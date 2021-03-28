class Line{
  Point p1, p2;
  
  Line(Point tempP1, Point tempP2){
    p1 = tempP1;
    p2 = tempP2;
  }
  
  void drawLine(){
    stroke(0);
    line(p1.x, p1.y, p2.x, p2.y);
  }
  
  Point divideLine(Line l, float j){
    Point p_;
    p_ = new Point((1-j) * l.p1.x + j * l.p2.x, (1-j) * l.p1.y + j * l.p2.y);
    return p_;
  }
}
