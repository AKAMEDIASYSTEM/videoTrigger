/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
 */

class Poly extends java.awt.Polygon {
  MyDropListener dl;
  boolean isActive = false; // whether or not there was motion detected this frame
  int emptyFrames = 0; // for counting the number of frames for which we've been inactive


  public Poly(int[] x, int[] y, int n, PApplet parent) {
    //call the java.awt.Polygon constructor
    super(x, y, n);
    dOut.addData(polygons.size()+1, "new region");
    emptyFrames=frameCount;
  }

  public Poly(PApplet parent) {
    super();
    int k = polygons.size()+1;
    dOut.addData(k, "Region "+k);
    println("Region "+k);
    emptyFrames=frameCount;
  }

  public Poly() {
    super();
  }

  int getIndex() {
    return polygons.indexOf(this);
  }

  void setFile(String filePath) { //tell the polygon what file is associated with it
    //file drop handler code
    //sendOSC("file/"+filePath);
  }


  void closeIt(SDrop drop) { //close off the polygon and make it ready to accept a sound
    //println(xpoints[0]+", "+ypoints[0]);
    dl = new MyDropListener(xpoints[0], ypoints[0], polygons.indexOf(this));
    drop.addDropListener(dl);
  }

  void trigger() { // called when the polygon has motion
    if (abs(frameCount-emptyFrames)>frameRate*secondsToWait) { //only call this on intervals so we don't ddos pachube
      pachube_send(1);
      emptyFrames=frameCount; // reset our motion counter
    }
  }  // end of poly.trigger()

  void noAction() {

    if (abs(frameCount-emptyFrames)>frameRate*secondsToWait) { // if we're inactive for relaxThreshold frames, do something
      // do stuff once the noAction threshold has been reached
      pachube_send(0);
      println("triggered noAction in "+this.getIndex());
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
    if(inputs[2]==1) {
      fill(255,0,0,128);
      text(this.getIndex(),xpoints[0],ypoints[0]);
    }
  } // end of poly.drawMe();


  void pachube_send(float payload) {
    // pachube trigger
    int g = this.getIndex();
    println("ready to send "+payload+" to: "+(g+1)); // have to offset b/c pachube doesn't allow datafeed id=0
    dOut.update(g, payload); // update the datastream 
    int response = dOut.updatePachube(); // updatePachube() updates by an authenticated PUT HTTP request
    println(response); // should be 200 if successful; 401 if unauthorized; 404 if feed doesn't exist
  }
} // end of Poly class

