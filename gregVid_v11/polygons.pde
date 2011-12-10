/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
 */

class Poly extends java.awt.Polygon {
  FaderEffect fadeEffect;
  Minim m;
  AudioPlayer player;
  MyDropListener dl;
  boolean didWePlay = false; // this keeps track of whether we've already played the sound
  boolean isActive = false;
  int emptyFrames = 0;

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
    //player.play();
    player.printControls();
    // player.shiftVolume(0.8,0.0,1000);
  }

  void play() {
    // play the sound, if any
    if (player != null) {
      if (!player.isPlaying()) {
        player.play();
      } 
      else println("already playing!");
    }
  }

  void closeIt(SDrop drop) { //close off the polygon and make it ready to accept a sound
    //println(xpoints[0]+", "+ypoints[0]);
    dl = new MyDropListener(xpoints[0], ypoints[0], polygons.indexOf(this));
    drop.addDropListener(dl);
  }

  void trigger() { // generic method to work on Greg's play logic
    this.isActive = false;
    if (player != null) {
      // we've seen action again, so clear any effects we appended to player
      if(player.effectCount()>0) {
        player.removeEffect(player.effectCount()-1); // remove the last-added effect to (sort of) smoothly fade back up
        println("There are now "+player.effectCount()+" effects");
      }
      if (!player.isPlaying()) {
        if (!didWePlay) { // if we haven't already played
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
    // called when nothing is moving

    //this.isActive = false; // so we can draw the poly correctly

    if (abs(frameCount-emptyFrames)>relaxThreshold) { // if we're inactive for relaxThreshold frames, do something
      int g = this.getIndex();
      println("hit "+emptyFrames+" noAction in: "+g);
      if (player!=null) {
        if(player.effectCount()<FADE_STEPS) { // if we're not done fading out, keep chaining effects
          fadeEffect = new FaderEffect();
          player.addEffect(fadeEffect); // add the fade-out effect to the audio
          println("added another fadeout effect, total is "+player.effectCount());
        }
        else { // if we've halved the volume 5 times, we're faint enough to stop the song.
          player.pause();
          player.clearEffects();
          player.rewind();
          println("cleared effects and rewound");
        }
      }
      emptyFrames=frameCount; // reset our motion counter with the last frame in which motion was detected
    }
  } // end of poly.noAction()

  void drawMe() {
    beginShape();
    if (isActive) {
      fill(255, 0, 0, 64);
    } 
    else fill(0, 255, 128, 196);
    for (int i = 0; i < npoints; i++) {
      vertex(xpoints[i], ypoints[i]);
    }
    endShape(CLOSE);
    if (dl!=null) {
      dl.draw();
    }
  } // end of poly.drawMe();
} // end of Poly class

