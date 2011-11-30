/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
 */

class Poly extends java.awt.Polygon {

  boolean isActive = false;

  public Poly(int[] x, int[] y, int n, PApplet parent) {
    //call the java.awt.Polygon constructor
    super(x, y, n);
    dOut.addData(polygons.size()+1, "new region");
  }

  public Poly(PApplet parent) {
    super();

    dOut.addData(polygons.size()+1, "new region two");
    println("new region two");
  }

  public Poly() {
    super();
  }

  int getIndex() {
    return polygons.indexOf(this);
  }


  void play() {

    // pachube trigger
    println("ready to POST: "+this.getIndex());
    dOut.update(this.getIndex(), "motion in this region!"); // update the datastream 
    int response = dOut.updatePachube(); // updatePachube() updates by an authenticated PUT HTTP request
    println(response); // should be 200 if successful; 401 if unauthorized; 404 if feed doesn't exist
  }


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

  }



  void trigger() { // generic method to work on Greg's play logic
    // put whatever you want in here!
  }


void noAction() {
  // nothing is moving
  // increment some sort of counter per frame to count to timeoutThreshold seconds
}
} // end of Poly class
