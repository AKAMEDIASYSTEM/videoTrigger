/*
 The class inherit all the fields, constructors and functions 
 of the java.awt.Polygon class, including contains(), xpoint,ypoint,npoint
 */

class Poly extends java.awt.Polygon {
  MyDropListener dl;
  boolean didWePlay = false; //whether we've already played the sound
  boolean isActive = false; // whether or not there was motion detected this frame
  boolean fading = false; // whether or not we're in the middle of a fade
  int emptyFrames = 0; // for counting the number of frames for which we've been inactive

  public Poly(int[] x, int[] y, int n, PApplet parent) {
    //call the java.awt.Polygon constructor
    super(x, y, n);

    emptyFrames=frameCount;
  }

  public Poly(PApplet parent) {
    super();

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
    // for OSC implementation, poly should send the string of the filepath on its channel
    sendOSC("file/"+filePath);
  }


  void closeIt(SDrop drop) { //close off the polygon and make it ready to accept a sound
    //println(xpoints[0]+", "+ypoints[0]);
    dl = new MyDropListener(xpoints[0], ypoints[0], polygons.indexOf(this));
    drop.addDropListener(dl);
  }

  void trigger() { // generic method to work on Greg's play logic
    sendOSC("Movement in "+this.getIndex());
    emptyFrames=frameCount; // reset our motion counter
  }  // end of poly.trigger()

  void noAction() {

    if (abs(frameCount-emptyFrames)>frameRate*secondsToWait) { // if we're inactive for relaxThreshold frames, do something
      // do stuff once the noAction threshold has been reached
      sendOSC("no Action in "+this.getIndex());
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
    if(inputs[2]==1){
      fill(255,0,0,128);
      text(this.getIndex(),xpoints[0],ypoints[0]);
    }
  } // end of poly.drawMe();

  void sendOSC(String msg) { // clone this function for any other datatypes you want to send
    /* in the following different ways of creating osc messages are shown by example */
    OscMessage myMessage = new OscMessage("/"+this.getIndex());  // send on a separate channel for each polygon
    myMessage.add(msg); /* add a string to the osc message */
    /* send the message */
    oscP5.send(myMessage, myRemoteLocation);
  }
} // end of Poly class

