void mouseReleased() {
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

void mouseMoved() {

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

