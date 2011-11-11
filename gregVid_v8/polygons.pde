/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
 */

class Poly extends java.awt.Polygon {

  Minim m;
  AudioPlayer player;
  MyDropListener dl;

  public Poly(int[] x,int[] y, int n, PApplet parent) {
    //call the java.awt.Polygon constructor
    super(x, y, n);
    //create sound for this Poly
    m = new Minim(parent);
  }

  public Poly(PApplet parent) {
    super();
    //create sound for this Poly
    m = new Minim(parent);
  }

  public Poly() {
    super();
  }

  int getIndex() {
    return polygons.indexOf(this);
  }

  void setSound(String filePath) { //tell the polygon what sound is associated with it

    player = m.loadFile(filePath,2048);
    //player.play();
    player.printControls();
    // player.shiftVolume(0.8,0.0,1000);
  }

  void play() {
    // play the sound, if any
    if(player != null) {
      if(!player.isPlaying()){
      player.play();
      } else println("already playing!");
    }
  }

  //  void dropEvent(DropEvent theDropEvent) {
  //
  //  }

  void closeIt(SDrop drop) { //close off the polygon and make it ready to accept a sound
    //println(xpoints[0]+", "+ypoints[0]);
    dl = new MyDropListener(xpoints[0],ypoints[0],polygons.indexOf(this));
    drop.addDropListener(dl);
  }

  void drawMe() {
    beginShape();
    if(isActive) {
      fill(255, 0, 0, 64);
    } 
    else fill(0, 255, 128, 196);
    for (int i = 0; i < npoints; i++) {
      vertex(xpoints[i], ypoints[i]);
    }
    endShape(CLOSE);
    if(dl!=null) {
      dl.draw();
    }
  }

  boolean isActive = false;
}

