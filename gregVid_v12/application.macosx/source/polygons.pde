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

  int getIndex() {
    return polygons.indexOf(this);
  }

  void setSound(String filePath) { //tell the polygon what sound is associated with it
    player = m.loadFile(filePath, 2048);
    player.printControls();
  }

  void play() {
    // play the sound, if any
    if (player != null) {
      if (!player.isPlaying()) {
        println("playing the sound in polygon "+this.getIndex());
        player.play();
      } 
      else println("already playing!");
    }
  }

  void fade() {
    fadeEffect = new FaderEffect();
    player.addEffect(fadeEffect); // add the fade-out effect to the audio
    fading = true;
    println("added a fadeout effect, total is "+player.effectCount());
  }

  void closeIt(SDrop drop) { //close off the polygon and make it ready to accept a sound
    //println(xpoints[0]+", "+ypoints[0]);
    dl = new MyDropListener(xpoints[0], ypoints[0], polygons.indexOf(this));
    drop.addDropListener(dl);
  }

  void trigger() { // generic method to work on Greg's play logic
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

  void noAction() {

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

  void drawMe() {
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

