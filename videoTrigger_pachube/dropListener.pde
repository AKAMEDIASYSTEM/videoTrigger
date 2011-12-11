// a custom DropListener class.
class MyDropListener extends DropListener {
  int polygonIndex;
  int myColor;
  float[] polyOrigin = new float[2];

  MyDropListener(float x, float y,int thePolygonIndex) {
    this.polygonIndex = thePolygonIndex;
    myColor = color(255,128);
    println(x+", "+y);
    polyOrigin[0] = x;
    polyOrigin[1]=y;
    // set a target rect for drop event.
    setTargetRect(x-10,y-10,20,20);
  }

  void draw() {
    fill(myColor);
    rect(polyOrigin[0]-10,polyOrigin[1]-10,20,20);
  }

  // if a dragged object enters the target area.
  // dropEnter is called.
  void dropEnter() {
    myColor = color(255,0,0,128);
  }

  // if a dragged object leaves the target area.
  // dropLeave is called.
  void dropLeave() {
    myColor = color(255,128);
  }

  void dropEvent(DropEvent theEvent) {
    // asociate files with the polygons they are dropped onto
    Poly dropPoly = new Poly();
    println("Dropped on MyDropListener");
    if(theEvent.isFile()) {
      dropPoly = (Poly)polygons.get(polygonIndex);
      //println(theEvent.filePath());
      dropPoly.setFile(theEvent.filePath());
    }
  }
}

