class Point{
  float x, y;
  
  Point(){
  
  }
  
  Point(float tempX, float tempY){
    x = tempX;
    y = tempY;
  }

  // Setter
  public void set(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  void dot(color c){
    fill(c);
    noStroke();
    circle(x, y, 8);
  }
  
  void connect(Point p, color c){
    stroke(c);
    line(x, y, p.x, p.y);
  }
  
  public float getAngle(Point target) {
    float angle = (float) Math.toDegrees(Math.atan2(target.y - y, target.x - x));

    if(angle < 0){
        angle += 360;
    }

    return angle;
}
}
