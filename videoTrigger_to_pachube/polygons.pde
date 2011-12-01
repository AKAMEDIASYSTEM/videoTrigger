/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
 */

class Poly extends java.awt.Polygon {

  boolean isActive = false;
  int emptyFrames = 0;

  public Poly(int[] x, int[] y, int n, PApplet parent) {
    //call the java.awt.Polygon constructor
    super(x, y, n);
    dOut.addData(polygons.size()+1, "new region");
  }

  public Poly(PApplet parent) {
    super();
    int k = polygons.size()+1;
    dOut.addData(k, "Region "+k);
    println("Region "+k);
  }

  public Poly() {
    super();
  }

  int getIndex() {
    return polygons.indexOf(this);
  }


  void trigger() {
    // pachube trigger
    int g = 1+ this.getIndex();
    println("ready to POST action to: "+g);
    //dOut.update(g-1, "Motion in region "+g); // update the datastream
    dOut.update(g-1, 1); // update the datastream 
    int response = dOut.updatePachube(); // updatePachube() updates by an authenticated PUT HTTP request
    println(response); // should be 200 if successful; 401 if unauthorized; 404 if feed doesn't exist
    emptyFrames = 0;
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

  void noAction() {
    // nothing is moving
    // increment some sort of counter per frame to count to timeoutThreshold seconds
    // pachube trigger
    emptyFrames++;
    if(emptyFrames>relaxThreshold) { // if we're inactive for relaxThreshold frames, post to pachube
      int g = 1+ this.getIndex();
      println("hit "+emptyFrames+" ready to POST noAction to: "+g);
      //dOut.update(g-1, "Motion in region "+g); // update the datastream
      dOut.update(g-1, 0); // update the datastream 
      int response = dOut.updatePachube(); // updatePachube() updates by an authenticated PUT HTTP request
      println(response); // should be 200 if successful; 401 if unauthorized; 404 if feed doesn't exist
      emptyFrames = 0;
    }
  }
} // end of Poly class

