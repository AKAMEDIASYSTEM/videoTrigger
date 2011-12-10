import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import sojamo.drop.*;
import controlP5.*;
import processing.video.*;
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
public int FADE_STEPS = 5; // the number of times we halve the volume to fade gracefully.
public float MULTIPLIER_DEFAULT = 0.5;
public float multiplier = 0.5; // halves the volume of the player...we cahin this to get semi-exponential fade-out

public int[] inputs = new int[2];
public int controlBackground = color(0x97FFFF);
public int controlFont = color(0xFF8888);
public boolean isNewPoly = true;
public ArrayList polygons;
Poly thisPoly;
Poly currentPoly;
public int pointThreshold = 5; // the max distance between points to make them "snap" together
public int motionThreshold = 200;
public int relaxThreshold = 24*10; // number of inactive frames before we trigger "poly.noAction"
// 24 frames/sec * number of seconds we want to wait before halving the volume
public int checkBoxOffset = 0; // a cheat to stop adding the first poly point when Draw is clicked


void setup() 
{
  size(640, 480, P2D);
  frameRate(24);

  // UI setup
  controlP5 = new ControlP5(this);
  controlP5.addSlider("motionThreshold", 0, 765, 200, 20, 100, 10, 100);
  checkbox = controlP5.addCheckBox("DrawToggle", 20, 20);
  // make adjustments to the layout of a checkbox.
  checkbox.setColorForeground(controlBackground);
  checkbox.setColorActive(color(#DD1DFF));
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

void draw() {

  fill(0, 255, 128, 196);
  stroke(0, 255, 255);

  if (video.available()) {
    video.read(); // Read a new video frame
    video.loadPixels(); // Make the pixels of video available
    int presenceSum = 0;
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...

      // Fetch the current color in that location, and also the color
      // of the background in that spot
      color currColor = video.pixels[i];
      color bkgdColor = backgroundPixels[i];

      if (inputs[1]==1) {      // if we're in analyzing mode

        // Extract the red, green, and blue components of the current pixel’s color
        int currR = (currColor >> 16) & 0xFF;
        int currG = (currColor >> 8) & 0xFF;
        int currB = currColor & 0xFF;
        // Extract the red, green, and blue components of the background pixel’s color
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
          thisPoly.isActive = (thisPoly.isActive || false);
          float[] tempXY = pixelToXY(i);
          if (thisPoly.contains(tempXY[0], tempXY[1])) {  // if the pixel is in a polygon
            if (presenceSum > motionThreshold) {
              // fire an event saying which polygon had movement
              println("We got one in polygon "+j+" motionThreshold is "+motionThreshold);
              // thisPoly.trigger(); // generic trigger statement for the poly
              thisPoly.play();
              // reset some values
              keyPressed();  // this resets the background 
              thisPoly.isActive = true; // this lets us draw the polygon correctly
            } 
            else {
              thisPoly.noAction(); // tell the poly that action has stopped
            }
            // Render the difference image to the screen
            // pixels[i] = color(diffR, diffG, diffB);
            // The following line does the same thing much faster, but is more technical
            pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
          }
          else { // ie, the pixel is not in thisPoly

            //  pixels[i]=currColor;
          }
        }
      }
      pixels[i]=currColor;
    }
    updatePixels(); // Notify that the pixels[] array has changed

    for (int i=0; i<polygons.size(); i++) {
      Poly eachPoly = new Poly();
      eachPoly = (Poly)polygons.get(i);
      if (eachPoly.isActive) {
        fill(255, 0, 0, 64);
      } 
      else {
        fill(0, 255, 128, 196);
      }
      eachPoly.drawMe();
    }

    // draw stuff

    // draw circles around origins if we're near them
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

void controlEvent(ControlEvent theEvent) {
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
// buffer, by copying each of the current frame’s pixels into it.
void keyPressed() {
  //println("supposedly reset background");
  video.loadPixels();
  arraycopy(video.pixels, backgroundPixels);
}

void stop() {
  // safely stop all the audio players
  for (int j=0;j<polygons.size();j++) {
    Poly thisPoly = (Poly)polygons.get(j);
    thisPoly.m.stop();
  }
  super.stop();
  // go through every polygon and if it has a sound file, stop it properly 
  // correct order is: player.close() then minim.stop()
}

