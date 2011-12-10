import processing.core.*; 
import processing.xml.*; 

import ddf.minim.*; 
import ddf.minim.signals.*; 
import ddf.minim.analysis.*; 
import ddf.minim.effects.*; 
import sojamo.drop.*; 
import controlP5.*; 
import processing.video.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class gregVid_v12 extends PApplet {








/*
this is supposed to:
 
 * plug in a hi-res webcamera to a laptop
 * run a script that lets me preview the shot
 * let me draw a polygonal shape to define a "region"
 * let me set a threshold-of-change that will, within the
 * region, trigger the sound
 * let me drop sounds into each region
 * set an inactivity threshold...after this time we set all sounds to "not played"
 * From Greg:
 * People entering the area should trigger the sound, which will play in its entirety.
 * Ideally (and tell me if these are complicated), the sound would play through, and if
 * people are still in the area, it will not play again until people exit completely
 * and a new group arrives. If people leave before the sound file has been played in
 * its entirety, it would fade out, say 45 seconds after they leave.
 */

ControlP5 controlP5;
CheckBox checkbox;
Capture video;
AudioPlayer player;
SDrop drop;

public int numPixels;
int[] backgroundPixels;



public int[] inputs = new int[2];
public int controlBackground = color(0x97FFFF);
public int controlFont = color(0xFF8888);
public boolean isNewPoly = true;
public ArrayList polygons;
public int checkBoxOffset = 0; // a cheat to stop adding the first poly point when Draw is clicked
public float MULTIPLIER_DEFAULT = 0.5f; // default is 0.5, so volume = 0.5* prev volume
Poly thisPoly;
Poly currentPoly;

// SOME SETTINGS YOU CAN FUTZ WITH
public int pointThreshold = 5; // the max distance between points to make them "snap" together
public int motion_Threshold = 200; // unitless difference threshold, alters motion sensitivity
public int secondsToWait = 10; // number of seconds to wait before triggering "poly.noAction"
public float relaxThreshold = 24*secondsToWait; // frames/sec * number of seconds we want to wait before halving the volume
public float fadeInterval = 24*5; // number of frames to wait between fades
public int FADE_STEPS = 10; // the number of times we scale down the volume to fade gracefully.
public float fade_Intensity = 0.5f; // halves the volume of the player...we chain this to get semi-exponential fade-out



public void setup() 
{
  size(640, 480, P2D);
  frameRate(24);

  // UI setup
  controlP5 = new ControlP5(this);
  controlP5.addSlider("motion_Threshold", 0, 765, 200, 20, 100, 10, 100);
  controlP5.addSlider("fade_Intensity", 0, 0.99f, 0.5f, 20, 240, 10, 100);
  checkbox = controlP5.addCheckBox("DrawToggle", 20, 20);
  // make adjustments to the layout of a checkbox.
  checkbox.setColorForeground(controlBackground);
  checkbox.setColorActive(color(0xffDD1DFF));
  checkbox.setColorLabel(controlFont);
  checkbox.addItem("Draw", 0);
  checkbox.addItem("Analyze", 1);

  // containers setup
  polygons = new ArrayList();
  drop = new SDrop(this);

  // video setup
  println(Capture.list());
  video = new Capture(this, width, height, 24);
  video.filter(GRAY);
  numPixels = video.width * video.height;
  // Create array to store the background image
  backgroundPixels = new int[numPixels];
  // Make the pixels[] array available for direct manipulation
  loadPixels();
}

public void draw() {

  fill(0, 255, 128, 128);
  stroke(0, 255, 255);

  if (video.available()) {
    video.read(); // Read a new video frame
    video.loadPixels(); // Make the pixels of video available
    int presenceSum = 0;
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...

      // Fetch the current color in that location, and also the color
      // of the background in that spot
      int currColor = video.pixels[i];
      int bkgdColor = backgroundPixels[i];

      if (inputs[1]==1) {      // if we're in analyzing mode

        // Extract the red, green, and blue components of the current pixel\u2019s color
        int currR = (currColor >> 16) & 0xFF;
        int currG = (currColor >> 8) & 0xFF;
        int currB = currColor & 0xFF;
        // Extract the red, green, and blue components of the background pixel\u2019s color
        int bkgdR = (bkgdColor >> 16) & 0xFF;
        int bkgdG = (bkgdColor >> 8) & 0xFF;
        int bkgdB = bkgdColor & 0xFF;
        // Compute the difference of the red, green, and blue values
        int diffR = abs(currR - bkgdR);
        int diffG = abs(currG - bkgdG);
        int diffB = abs(currB - bkgdB);

        presenceSum = diffR + diffG + diffB;

        // is the pixel in a polygon?
        for (int j=0;j<polygons.size();j++) {

          Poly thisPoly = (Poly)polygons.get(j);

          float[] tempXY = pixelToXY(i);

          if (thisPoly.contains(tempXY[0], tempXY[1])) {  // if the pixel is in a polygon

            if (presenceSum > motion_Threshold) { // if we detect motion in the polygon
              println("Motion in polygon "+j);
              thisPoly.isActive = true;
              keyPressed();  // this resets the background
            }
            else {
              thisPoly.isActive = (false || thisPoly.isActive);
              //thisPoly.isActive = false;
            }

            // Render the difference image to the screen
            // pixels[i] = color(diffR, diffG, diffB);
            // The following line does the same thing much faster, but is more technical
            pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
          } // end of is-pixel-in-polygon loop
        } // end of go-through-all-the-polygons loop
      } // end of are-we-in-analyze-mode loop
      pixels[i]=currColor;
    } // end of pixel-diff code

    updatePixels(); // Notify that the pixels[] array has changed

    // now go through all polygons and draw them
    for (int i=0; i<polygons.size(); i++) {
      Poly eachPoly = new Poly();
      eachPoly = (Poly)polygons.get(i);
eachPoly.drawMe();
      if (eachPoly.isActive) {
        if (inputs[1]==1) {
          eachPoly.trigger();
          eachPoly.isActive = false; // reset isActive every Frame
        }
      }
      else {
        if (inputs[1]==1) {
          eachPoly.noAction();
        }
      }
      
    }

    // draw stuff
    // draw circles around origins if we're near them - so they only appear when you're OK to click
    if (!polygons.isEmpty()) {
      Poly eachPoly = new Poly();
      eachPoly = (Poly)polygons.get(polygons.size()-1);
      if (dist(eachPoly.xpoints[0], eachPoly.ypoints[0], mouseX, mouseY)<=pointThreshold) {
        ellipse(eachPoly.xpoints[0], eachPoly.ypoints[0], pointThreshold*2, pointThreshold*2);  // draw circle at origin
      }
    }

    controlP5.draw();
  } // end of video.available()
}

public void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {

    print("got an event from "+theEvent.group().name()+"\t");
    // checkbox uses arrayValue to store the state of 
    // individual checkbox-items. usage:
    for (int i=0;i<theEvent.group().arrayValue().length;i++) {
      int n = (int)theEvent.group().arrayValue()[i];
      inputs[i] = n;
      println("it's "+n+"\t");
      println("inputs is "+inputs[i]);
    }
    if (inputs[0]==1) {
      checkBoxOffset = 0;
    }
  }
}

public float[] pixelToXY(int pixel) {  // HEY IS THIS RIGHT??
  // convert a pixel's index number to its xy position
  float[] ourPoint = new float[2];
  ourPoint[0] = (pixel % video.width);
  ourPoint[1] = ceil(pixel/video.width);
  return ourPoint;
}


public boolean isLastPoint(Poly p) {
  // check whether the first and last points are close to each other
  // if they are within pointThreshold of each other, make the last point = first point (to close shape) 
  if (dist(p.xpoints[p.npoints-1], p.ypoints[p.npoints-1], p.xpoints[0], p.ypoints[0]) <= pointThreshold) {
    // if the dist is less than threshold, make last points = first points and close shape
    p.xpoints[p.npoints-1] = p.xpoints[0];
    p.ypoints[p.npoints-1] = p.ypoints[0];
    p.closeIt(drop);
    println("we closed a polygon");
    return true;
  } 
  else return false;
}

// When a key is pressed, capture the background image into the backgroundPixels
// buffer, by copying each of the current frame\u2019s pixels into it.
public void keyPressed() {
  //println("supposedly reset background");
  video.loadPixels();
  arraycopy(video.pixels, backgroundPixels);
}

public void stop() {
  // safely stop all the audio players
  for (int j=0;j<polygons.size();j++) {
    Poly thisPoly = (Poly)polygons.get(j);
    if(thisPoly.player!=null) {
      thisPoly.player.close();
    }
    thisPoly.m.stop();
  }
  super.stop();
  // go through every polygon and if it has a sound file, stop it properly 
  // correct order is: player.close() then minim.stop()
}

// a custom DropListener class.
class MyDropListener extends DropListener {
  int polygonIndex;
  int myColor;
  float[] polyOrigin = new float[2];

  //  MyDropListener(Poly p) {
  //    myColor = color(255);
  //    polyOrigin[0] = p.xpoints[0];
  //    polyOrigin[1] = p.ypoints[0];
  //    println(polyOrigin[0]+", "+polyOrigin[1]);
  //    // set a target rect for drop event.
  //    setTargetRect(polyOrigin[0],polyOrigin[1],polyOrigin[0]+20,polyOrigin[1]+20);
  //  }

  MyDropListener(float x, float y,int thePolygonIndex) {
    this.polygonIndex = thePolygonIndex;
    myColor = color(255,128);
    println(x+", "+y);
    polyOrigin[0] = x;
    polyOrigin[1]=y;
    // set a target rect for drop event.
    setTargetRect(x-10,y-10,20,20);
  }

  public void draw() {
    fill(myColor);
    rect(polyOrigin[0]-10,polyOrigin[1]-10,20,20);
  }

  // if a dragged object enters the target area.
  // dropEnter is called.
  public void dropEnter() {
    myColor = color(255,0,0,128);
  }

  // if a dragged object leaves the target area.
  // dropLeave is called.
  public void dropLeave() {
    myColor = color(255,128);
  }

  public void dropEvent(DropEvent theEvent) {
    Poly dropPoly = new Poly();
    println("Dropped on MyDropListener");
    if(theEvent.isFile()) {
      println("it's a file! "+polygonIndex);
      // check that it's a soundfile
      // TODO

      // get polygons[polygonIndex]
      dropPoly = (Poly)polygons.get(polygonIndex);
      println(theEvent.filePath());
      // and add the file as s sound
      dropPoly.setSound(theEvent.filePath());
    }
  }
}

//This effect manually fades out a player over time.
//It only exists becuase Minim doesn't support fading on my machine...wtf?!


class FaderEffect implements AudioEffect
{
  public void process(float[] samp)
  {
    // sanity check for fade_Intensity value
    if((fade_Intensity < 0) || (fade_Intensity > 1)) {
      fade_Intensity = MULTIPLIER_DEFAULT;
    }
    float[] processed = new float[samp.length];
    for (int j = 0; j < samp.length; j++)
    {
      processed[j] = samp[j] * fade_Intensity;
    }
    // we have to copy the values back into samp for this to work
    arraycopy(processed, samp);
  }

  public void process(float[] left, float[] right)
  {
    process(left);
    process(right);
  }
}

public void mouseReleased() {
  // are we in draw mode?
  // are we beginning a shape or are we midstream?
  // are we over the first point in the shape? (then close shape)
  // if not, add a point to the current polygon
  checkBoxOffset += 1;
  if((inputs[0]==1) && (checkBoxOffset>1)) { // if we *are* in draw mode
    //we need to throw away the first positive mouseReleased
    // because it's always where the checkbox is
    if(isNewPoly) { // if we're starting a new polygon

      thisPoly = new Poly(this);
      thisPoly.addPoint(mouseX,mouseY);
      // we don't have to check for this being the final point becuase it's the first point
      polygons.add(thisPoly);  // add thisPoly to our master list
      isNewPoly = false;  // let future-us know we're in the middle of making a polygon
    } 
    else {  
      //else we're just adding a point to the current polygon
      currentPoly = (Poly)polygons.get(polygons.size()-1);
      currentPoly.addPoint(mouseX,mouseY);

      if( isLastPoint((Poly)polygons.get(polygons.size()-1)) ) {
        // close the polygon
        isNewPoly = true;
      }
    }
  }
}  // end of mouseReleased()

public void mouseMoved() {

  if(inputs[0]==1) { // if we're in Draw mode, show polygon origins
    // OR: do we just show the current polygon's origin? Might be faster...
    fill(255,0,0,128);
    //    if(!polygons.isEmpty()) {
    //      for (int i=0; i<polygons.size(); i++) {
    //        Poly eachPoly = new Poly();
    //        eachPoly = (Poly)polygons.get(i);
    //        ellipse(eachPoly.xpoints[0],eachPoly.ypoints[0],5,5);
    //      }
    //    }
    //    if(!polygons.isEmpty()) {
    //      Poly eachPoly = new Poly();
    //      eachPoly = (Poly)polygons.get(polygons.size()-1);
    //      if(dist(eachPoly.xpoints[0],eachPoly.ypoints[0],mouseX,mouseY)<=pointThreshold) {
    //        ellipse(eachPoly.xpoints[0],eachPoly.ypoints[0],pointThreshold*2,pointThreshold*2);  // draw circle at origin
    //      }
    //    }
  }
} // end of mouseMoved()

/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
 */

class Poly extends java.awt.Polygon {
  FaderEffect fadeEffect;
  Minim m;
  AudioPlayer player;
  MyDropListener dl;
  boolean didWePlay = false; //whether we've already played the sound
  boolean isActive = false; // whether or not there was motion detected this frame
  boolean fading = false; // whether or not we're in the middle of a fade
  int emptyFrames = 0; // for counting the number of frames for which we've been inactive

  public Poly(int[] x, int[] y, int n, PApplet parent) {
    //call the java.awt.Polygon constructor
    super(x, y, n);
    //create sound for this Poly
    m = new Minim(parent);
    emptyFrames=frameCount;
  }

  public Poly(PApplet parent) {
    super();
    //create sound for this Poly
    m = new Minim(parent);
    emptyFrames=frameCount;
  }

  public Poly() {
    super();
  }

  public int getIndex() {
    return polygons.indexOf(this);
  }

  public void setSound(String filePath) { //tell the polygon what sound is associated with it
    player = m.loadFile(filePath, 2048);
    player.printControls();
  }

  public void play() {
    // play the sound, if any
    if (player != null) {
      if (!player.isPlaying()) {
        println("playing the sound in polygon "+this.getIndex());
        player.play();
      } 
      else println("already playing!");
    }
  }

  public void fade() {
    fadeEffect = new FaderEffect();
    player.addEffect(fadeEffect); // add the fade-out effect to the audio
    fading = true;
    println("added a fadeout effect, total is "+player.effectCount());
  }

  public void closeIt(SDrop drop) { //close off the polygon and make it ready to accept a sound
    //println(xpoints[0]+", "+ypoints[0]);
    dl = new MyDropListener(xpoints[0], ypoints[0], polygons.indexOf(this));
    drop.addDropListener(dl);
  }

  public void trigger() { // generic method to work on Greg's play logic
    //this.isActive = true;
    if (player != null) {

      if(player.effectCount()>0) {  // we've seen action again, so clear any effects we appended to player
        player.removeEffect(player.effectCount()-1); // remove the last-added effect to (sort of) smoothly fade back up
        println("There are now "+player.effectCount()+" effects in poly "+this.getIndex());
      }

      if (!player.isPlaying()) { // if we're not already playing the sound
        if (!didWePlay) { // and if we haven't already played
          player.play(); // play the sound
          didWePlay = true; // remember that we played it
        } 
        else { // we're already playing
          // nothing to do?
        }
      }
    }
    emptyFrames=frameCount; // reset our motion counter
  }  // end of poly.trigger()

  public void noAction() {

    if(fading && (abs(frameCount-emptyFrames)>fadeInterval)) {
      if (player!=null && player.isPlaying()) { // if we're playing a sound
        if(player.effectCount() < FADE_STEPS) { // if we're not done fading out, keep chaining effects
          fade();
        }
        else { // if we've reduced the volume FADE_STEPS times, we're faint enough to stop the song.
          player.pause();
          player.clearEffects();
          player.rewind();
          println("cleared effects and rewound");
          didWePlay = false; // so we can start up again
          this.fading = false;
        }
      }
      emptyFrames = frameCount;
    }

    if (abs(frameCount-emptyFrames)>relaxThreshold) { // if we're inactive for relaxThreshold frames, do something
      println("hit "+emptyFrames+" noAction in: "+this.getIndex());
      if(player!=null) {
        if(player.isPlaying()) {
          fade();
        }
      }
      emptyFrames=frameCount; // reset our motion counter after we've done something to force us to wait relaxThreshold more seconds till we repeat
    }
  } // end of poly.noAction()

  public void drawMe() {
    beginShape();
    if (isActive) {
      fill(255, 0, 0, 64);
    } 
    else fill(0, 255, 128, 128);
    for (int i = 0; i < npoints; i++) {
      vertex(xpoints[i], ypoints[i]);
    }
    endShape(CLOSE);
    if (dl!=null) {
      dl.draw();
    }
  } // end of poly.drawMe();
} // end of Poly class

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "gregVid_v12" });
  }
}
