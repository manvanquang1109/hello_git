public final color SQUARE_LINE_100_COLOR = #e3d0b9;
public final color SQUARE_LINE_COLOR = #ece2e1;
public final color MARKING_NUM_COLOR = 0;
public final color POINT_COLOR = #ec4646;
public final color POINT_CONNECTION_COLOR = #23689b;
public final int MARKING_NUM_SIZE = 8;
public final int MAX = 100000;

//khoang cach giua 2 diem ma khong ve
public final float DIST_NOT_DRAW = 0;

public String standardized_d = "";
public String standardized_tranformation_para = "";

ArrayList<String> transformation_cmd = new ArrayList<String>();

XML xml;
XML[] g_element;
//smallest_element: path, circle, ellipse, line, polygon, polyline, rect
ArrayList<XML> smallest_element = new ArrayList<XML>();
ArrayList<String> element_names = new ArrayList<String>();
ArrayList<String> d_attribute = new ArrayList<String>();
ArrayList<String> transform_attribute = new ArrayList<String>();

ArrayList<Point> points = new ArrayList<Point>();
ArrayList<Point> abs_points = new ArrayList<Point>();
ArrayList<Point> abs_p_transform = new ArrayList<Point>();
ArrayList<Point> drawing_points = new ArrayList<Point>();
ArrayList<Integer> dont_connect = new ArrayList<Integer>();

String char_and_num[];
ArrayList<Character> drawing_cmd = new ArrayList<Character>();
ArrayList<Character> cmd = new ArrayList<Character>();
ArrayList<Integer> cmd_count = new ArrayList<Integer>();
ArrayList<Integer> m_2nd_index = new ArrayList<Integer>();

void setup(){
  size(1000, 1000);
  
  //create background: color, square lines and marking numbers
  drawBackground();
  
  //load svg file
  xml = loadXML("home-test.svg");
  
  //extract points from paths of xml
  prepareForDrawing();
}

void draw(){
  draw_();
  drawPoint();
}

void drawBackground(){
  background(255);
  
  //draw square line
  for(int i = 1; i < 100; i++){
    //draw horizontal line
    if (i % 10 == 0){
      stroke(SQUARE_LINE_100_COLOR);
    }
    else{
      stroke(SQUARE_LINE_COLOR);
    }
    line(0, 10*i, 1000, 10*i);
    
    //draw vertical line
    if (i % 10 == 0){
      stroke(SQUARE_LINE_100_COLOR);
    }
    else{
      stroke(SQUARE_LINE_COLOR);
    }
    line(10*i, 0, 10*i, 1000);
  }
  
  //create marking number for the lines
  for(int i = 1; i < 20; i++){
    String markingNumber = str(i*50);
    
    fill(MARKING_NUM_COLOR);
    textSize(MARKING_NUM_SIZE);
    text(markingNumber, 0, i*50);
    
    fill(MARKING_NUM_COLOR);
    textSize(MARKING_NUM_SIZE);
    text(markingNumber, i*50, MARKING_NUM_SIZE);
  }
}

void prepareForDrawing(){
  
  //thêm xuống dòng nếu xml hiện tại đang viết liền, gây đếm sai getChildCount(), gây vẽ thiếu
  xml = beautifyXML(xml);
  println("xml.getChildCount = " + xml.getChildCount());
  
  //gồm các thao tác: lấy ra các smallest_elements, thêm các thuộc tính của cha nó vào.
  //Chuyển các thuộc tính cơ bản của các ellipse, polygon,... thành thuộc tính d của path -> đưa vào mảng d_attribute. Lấy thuộc tính transform -> đưa vào mảng transform_attribute
  getDAndTransformAttributeFromXML();
  
  //<path stroke="red" stroke-width=".2" fill="none" d="M500 500 c-80 -50 -120 -120 -90 -150 40 -30 120 10 190 100 140 170 110 190 -100 50z" transform=" matrix (1, 0, 0, 1, 0, 0)"/>
  //d_attribute[0] = "M500 500 c-80 -50 -120 -120 -90 -150 40 -30 120 10 190 100 140 170 110 190 -100 50z" (thô, chưa chuẩn hóa)
  //transform_attribute[0] = " matrix (1, 0, 0, 1, 0, 0)"
  
  for (int i = 0; i < d_attribute.size(); i++){
    //xóa các mảng sử dụng 1 lần cho mỗi element
    clearArray();
    
    //transform_attribute[0] = " matrix (1, 0, 0, 1, 0, 0)". Sau khi separate, ca hai (type, parameters) deu duoc chuan hoa
    //transform_cmd[0] = "matrix"
    //transform_cmd[1] = "1 0 0 1 0 0"
    separateTransformAtrribute(transform_attribute.get(i), i);
    
    standardized_d = standardizeString(d_attribute.get(i));
    println("standardized_d = " + standardized_d);
    
    char_and_num = standardized_d.split(" ");
    
    extract(char_and_num);
    
    turnRelativeToAbsoluteCoordinates();
    
    initiateArrayForTransformation();
    transform(transformation_cmd.get(i * 2), transformation_cmd.get(i * 2 + 1));
    
    addDrawingPoints();
  }
  minimizeDrawingPoints();
  printArray_();
}

void getDAndTransformAttributeFromXML(){
  //println("n_defs = " + xml.getChild("defs").getChildCount());
  
  //xây dựng mảng smallest_element
  getElementsFromXML(xml);
  //for (int i = 0; i < smallest_element.size(); i++){
  //  println("smallest_element[" + i + "] = " + smallest_element.get(i));
  //}
  
  //lấy thuộc tính d và transform từ tất cả các dạng smallest elements (path, ellipse, rect,...)
  getDAndTransformAttributeFromSmallestElements();
}

//lấy ra các element nhỏ nhất (path, ellipse,...) thêm vào mảng smallest_element VÀ đưa các thuộc tính của element cha cho các element con
//xml(g(path, ellipse), path, g(g(circle), ellipse))
//smallest_element[XML] path, ellipse, path, circle, ellipse
//Thuật toán: khi nào mà xml_temp đang xét, không còn child (getChildCount = 0) thì thêm vào mảng
void getElementsFromXML(XML xml){
  XML xml_temp;
  for (int i = 1; i < xml.getChildCount() - 1; i = i + 2){
    xml_temp = xml.getChild(i);
    if (xml_temp.getChildCount() == 0){
      smallest_element.add(xml_temp);
    }
    else{
      addAttributesToChildren(xml_temp);
      getElementsFromXML(xml_temp);
    }
  }
}

//nếu g có thuộc tính transform, thêm thuộc tính đó vào các con của g
//vẫn chưa giải quyết được, nếu g có transform mà path (con của g) cũng có transform thì sao
void addAttributesToChildren(XML xml){
  XML xml_temp;
  
  String transform_s = xml.getString("transform");
  
  for (int i = 1; i < xml.getChildCount() - 1; i = i + 2){
    xml_temp = xml.getChild(i);
    
    if (transform_s != null){
      xml_temp.setString("transform", transform_s);
    }
  }
}

//quét mảng smallest_element, lấy ra d -> thêm vào mảng d_attribute. lấy ra transform -> thêm vào mảng transform_attribute
void getDAndTransformAttributeFromSmallestElements(){
  for (int i = 0; i < smallest_element.size(); i++){
    XML xml_temp = smallest_element.get(i);
    
    String d = dAttributeExtractedFromAllKindOfElements(xml_temp);
    d_attribute.add(d);
    
    String transform_s = xml_temp.getString("transform");
    transform_attribute.add(transform_s);
  }
}

//hàm lấy ra thuộc tính d của tất cả các element
//Thuật toán: lấy ra các thuộc tính của 1 element, chuẩn hóa chúng (standardizeString), đưa chúng về float. Xét từng trường hợp.
//xml = <ellipse cx="200" cy="300" rx="100" ry="50"/>
//d = "m 100 300 a 100 50 0 0 0 200 0 a 100 50 0 0 0 -200 0
String dAttributeExtractedFromAllKindOfElements(XML xml){
  String element_name = nameFromElement(xml);
  String d = "";
  
  if (element_name.equals("path")){
    d = xml.getString("d");
  }
  
  else if (element_name.equals("circle")){
    float cx = Float.parseFloat(standardizeString(xml.getString("cx")));
    float cy = Float.parseFloat(standardizeString(xml.getString("cy")));
    float r = Float.parseFloat(standardizeString(xml.getString("r")));
        
    d = d + "m " + (cx - r) + " " + cy + " ";
    d = d + "a " + r + " " + r + " 0 0 0 " + (r * 2) + " 0";
    d = d + "a " + r + " " + r + " 0 0 0 " + (r * -2) + " 0";
  }
  
  else if (element_name.equals("ellipse")){
    float cx = Float.parseFloat(standardizeString(xml.getString("cx")));
    float cy = Float.parseFloat(standardizeString(xml.getString("cy")));
    float rx = Float.parseFloat(standardizeString(xml.getString("rx")));
    float ry = Float.parseFloat(standardizeString(xml.getString("ry")));
        
    d = d + "m " + (cx - rx) + " " + cy + " ";
    d = d + "a " + rx + " " + ry + " 0 0 0 " + (rx * 2) + " 0";
    d = d + "a " + rx + " " + ry + " 0 0 0 " + (rx * -2) + " 0";
  }
  
  else if (element_name.equals("line")){
    float x1 = Float.parseFloat(standardizeString(xml.getString("x1")));
    float y1 = Float.parseFloat(standardizeString(xml.getString("y1")));
    float x2 = Float.parseFloat(standardizeString(xml.getString("x2")));
    float y2 = Float.parseFloat(standardizeString(xml.getString("y2")));
        
    d = d + "m " + x1 + " " + y1 + " L " + x2 + " " + y2;
  }
  
  else if (element_name.equals("polygon")){
    String points_s = xml.getString("points");
    points_s = standardizeString(points_s);
    String[] xy = points_s.split(" ");
    
    d = d + "m " + xy[0] + " " + xy[1] + " ";
    for (int i = 2; i < xy.length; i = i + 2){
      d = d + "L " + xy[i] + " " + xy[i + 1] + " ";
    }
    d = d + "z";
  }
  
  else if (element_name.equals("polyline")){
    String points_s = xml.getString("points");
    points_s = standardizeString(points_s);
    String[] xy = points_s.split(" ");
    
    d = d + "m " + xy[0] + " " + xy[1] + " ";
    for (int i = 2; i < xy.length; i = i + 2){
      d = d + "L " + xy[i] + " " + xy[i + 1] + " ";
    }
  }
  
  else if (element_name.equals("rect")){
    float w, h;
    float x = 0;
    float y = 0;
    float rx = 0;
    float ry = 0;
        
    w = Float.parseFloat(standardizeString(xml.getString("width")));
    h = Float.parseFloat(standardizeString(xml.getString("height")));
    
    if (xml.getString("x") != null){
      x = Float.parseFloat(standardizeString(xml.getString("x"))); 
    }
    
    if (xml.getString("y") != null){
      y = Float.parseFloat(standardizeString(xml.getString("y")));    
    }
    
    if (xml.getString("rx") != null){
      rx = Float.parseFloat(standardizeString(xml.getString("rx")));
      ry = Float.parseFloat(standardizeString(xml.getString("ry")));
    }
    
    d = d + "m " + (x + rx) + " " + y + " ";
    d = d + "h " + (w - 2 * rx) + " ";
    d = d + "a " + rx + " " + ry + " 0 0 1 " + rx + " " + ry + " ";
    d = d + "v " + (h - 2 * ry) + " ";
    d = d + "a " + rx + " " + ry + " 0 0 1 " + (-1 * rx) + " " + ry + " "; 
    d = d + "h " + (2 * rx - w) + " ";
    d = d + "a " + rx + " " + ry + " 0 0 1 " + (-1 * rx) + " " + (-1 * ry) + " ";
    d = d + "v " + (2 * ry - h) + " ";
    d = d + "a " + rx + " " + ry + " 0 0 1 " + rx + " " + (-1 * ry);
  }
  
  return d;
}

//xml = <ellipse cx="165.874" cy="104.687" rx="29.355" ry="23.377"/>
//element_name = "ellipse"
//Thuật toán: quét chuỗi xml_s, tìm ký tự là chữ -> vị trí k_temp, tìm ký tự là khoảng trắng -> vị trí k => trích xuất xml_s
String nameFromElement(XML xml){
  String xml_s = xml.toString();
  int k = 0;
  println("xml = " + xml);
  while (Character.isLetter(xml_s.charAt(k))){
    k++;
  }
  int k_temp = k;
  while (xml_s.charAt(k) != ' '){
    k++;
  }
  
  String element_name = xml_s.substring(k_temp + 1, k);
  return element_name;
}

void separateTransformAtrribute(String s, int i){
  //neu khong co transform_attribute[0] trong path, hoac transform_attribute[i] = "none" thi tranformation_cmd[0] = "none" va transformation_cmd[1] = "0"
  if (s == null || s.equals("none")){
    transformation_cmd.add("none");
    transformation_cmd.add("0");
  }
  else{
    String type = "";
    for (int k = 0; k < s.length(); k++){
      if (Character.isLetter(s.charAt(k))){
        type = type + s.substring(k, k + 1);
      }
      else if (s.charAt(k) == '('){
        type = type + ",";
      }
    }
    type = type.substring(0, type.length() - 1);
    
    String para = "";
    String para_temp = "";
    for (int k = 0; k < s.length(); k++){
      int k_temp = k;
      if (s.charAt(k) == '('){
        k_temp = k + 1;
        while (s.charAt(k) != ')'){
          k++;
        }
        para_temp = s.substring(k_temp, k);
        para_temp = standardizeString(para_temp);        
        para = para + para_temp + ",";
      }
    }
    para = para.substring(0, para.length() - 1);
    
    transformation_cmd.add(type);
    transformation_cmd.add(para);
  }
 
  println("type of transformation = " + transformation_cmd.get(i * 2));
  println("parameters of transformation = " + transformation_cmd.get(i * 2 + 1));
}

String standardizeString(String s0){
   //s1 la chuoi chi giu lai cac ky tu can thiet, gom '-' '.' 0 den 9, xoa khoang trang hai dau
   String s1 = s0.replaceAll("[^-.0-9MHVLQTCSAZmhvlqtcsaz]+"," ").trim();
   
   //s2 la chuoi se tra ve, khoi tao s2 = s1
   //s2: M170c-150z -> M 170c -150z
   String s2 = s1;
   int k = 0;
   for (int i = 0; i < s1.length() - 1; i++){
     if (Character.isLetter(s1.charAt(i)) && !Character.isWhitespace(s1.charAt(i+1))){
       s2 = s2.substring(0, i + 1 + k) + " " + s2.substring(i + 1 + k, s2.length());
       k++;
     }
   }
   
   //s2: M 170c -150z -> M 170 c -150 z
   s1 = s2;
   k = 0;
   for (int i = 1; i < s1.length(); i++){
     if (Character.isLetter(s1.charAt(i)) && Character.isDigit(s1.charAt(i - 1))){
       s2 = s2.substring(0, i + k) + " " + s2.substring(i + k, s2.length());
       k++;
     }
   }
   
   //s2: M150-170 c -170-200 z -> M 150 -170 c -170 -200
   s1 = s2;
   k = 0;
   for (int i = 1; i < s1.length(); i++){
     if (s1.charAt(i) == '-' && Character.isDigit(s1.charAt(i - 1))){
       s2 = s2.substring(0, i + k) + " " + s2.substring(i + k, s2.length());
       k++;
     }
   }
   
   //s2: l .15 -.17.17 -.19 -> l .15 -.17 .17 -.19
   s2 = "m " + s2;
   s1 = s2;
   k = 0;
   for (int i = s1.length() - 1; i > 0; i--){
     if (s1.charAt(i) == '.'){
       int temp_i = i;
       boolean is_dot_existed = false;
       while (s1.charAt(--temp_i) != ' '){
         if (s1.charAt(temp_i) == '.'){
           is_dot_existed = true;
         }
       }
       if (is_dot_existed){
         s2 = s2.substring(0, i) + " " + s2.substring(i, s2.length());
         k++;
       }
     }
   }
   s2 = s2.substring(2, s2.length());
   
   //s2: l .15 -.17 .17 -.19 -> l 0.15 -0.17 0.17 -0.19
   s1 = s2;
   k = 0;
   for (int i = 2; i < s1.length(); i++){
     if ((s1.charAt(i) == '.' && s1.charAt(i-1) == ' ')
      || (s1.charAt(i) == '.' && s1.charAt(i-1) == '-' && s1.charAt(i-2) == ' ')){
       s2 = s2.substring(0, i + k) + "0" + s2.substring(i + k, s2.length());
       k++;
     }
   }
   
   //loai bo truong hop ma: l 20 20 l 30 30 -> l 20 20 30 30, nhung m 20 20 m 30 30 -> m 20 20 m 30 30
   s1 = s2;
   k = 0;
   for (int i = 0; i < s1.length(); i++){
     char c = s1.charAt(i);
     if (Character.isLetter(c)){
       while (i++ < s1.length() - 1 && !Character.isLetter(s1.charAt(i)));
       if (i < s1.length()){
         if (c == s1.charAt(i) && c != 'm'){
           s2 = s2.substring(0, i + k - 1) + s2.substring(i + k + 1, s2.length());
           k = k - 2;
         }
       }
       i--;
     }
   }
   return s2;
}

void extract(String[] s){  
  //drawing_cmd: M M M a a a a a a a a c c c c c c c m m m m m m l l l h h z
  char c = '?';
  for (int i = 0; i < s.length; i++){
    if (Character.isLetter(s[i].charAt(0))){
      if (c == 'm' && s[i].charAt(0) == 'm'){
        m_2nd_index.add(i);
      }
      drawing_cmd.add(s[i].charAt(0));
      c = s[i].charAt(0);
    }
    else{
      drawing_cmd.add(c);
    }
  }
  m_2nd_index.add(MAX);
  
  //cmd:        M a c m m l h z
  //cmd_count:  3 8 7 3 3 3 2 1
  int temp_count = 1;
  int k = 0;
  for (int i = 1; i < drawing_cmd.size(); i++){
    if (drawing_cmd.get(i) == drawing_cmd.get(i-1) && i != m_2nd_index.get(k)){
      temp_count++;
    }
    else{
      cmd.add(drawing_cmd.get(i-1));
      cmd_count.add(temp_count);
      temp_count = 1;
      if (i == m_2nd_index.get(k) && k < m_2nd_index.size() - 1){
        k++;
      }
    }
  }
  cmd.add(drawing_cmd.get(drawing_cmd.size()-1));
  cmd_count.add(temp_count);

  //cmd:        M a c m m l h z
  //cmd_count:  1 4 3 1 1 1 1 1
  for (int i = 0; i < cmd.size(); i++){
    if (cmd.get(i) == 'M' || cmd.get(i) == 'm'
     || cmd.get(i) == 'L' || cmd.get(i) == 'l'
     || cmd.get(i) == 'Q' || cmd.get(i) == 'q'
     || cmd.get(i) == 'T' || cmd.get(i) == 't'
     || cmd.get(i) == 'C' || cmd.get(i) == 'c'
     || cmd.get(i) == 'S' || cmd.get(i) == 's'){
      cmd_count.set(i, (cmd_count.get(i) - 1) / 2);
    }
    else if (cmd.get(i) == 'H' || cmd.get(i) == 'h'
          || cmd.get(i) == 'V' || cmd.get(i) == 'v'){
      cmd_count.set(i, cmd_count.get(i) - 1);
    }
    else if (cmd.get(i) == 'A' || cmd.get(i) == 'a'){
      cmd_count.set(i, (cmd_count.get(i) - 1) / 7 * 4);
    }
  }
  
  //drawing_cmd:  empty
  drawing_cmd.clear();

  //cmd:        M a c m m l h z
  //cmd_count:  1 4 3 1 1 1 1 1
  //drawing_cmd:  M a a a a c c c m m l h z
  for (int i = 0; i < cmd_count.size(); i++){
    for (int j = 1; j <= cmd_count.get(i); j++){
      drawing_cmd.add(cmd.get(i));
    }
  }
  
  for (int i = 0; i < cmd_count.size(); i++){
    print(cmd_count.get(i) + "" + cmd.get(i) + " ");
  }
  println();
  
  //tach lay diem cho vao array points
  k = 0;
  for (int i = 0; i < cmd.size(); i++){
    k++;
    if (cmd.get(i) != 'H' && cmd.get(i) != 'h' && cmd.get(i) != 'V' && cmd.get(i) != 'v' && cmd.get(i) != 'A' && cmd.get(i) != 'a' && cmd.get(i) != 'Z' && cmd.get(i) != 'z'){
      for (int j = 0; j < cmd_count.get(i); j++){
        Point p_temp = new Point(Float.parseFloat(s[k]), Float.parseFloat(s[k+1]));
        points.add(p_temp);
        k = k + 2;
      }
    }
    else if (cmd.get(i) == 'H' || cmd.get(i) == 'h' || cmd.get(i) == 'V' || cmd.get(i) == 'v'){
      for (int j = 0; j < cmd_count.get(i); j++){
        if (cmd.get(i) == 'H' || cmd.get(i) == 'h'){
          Point p_temp = new Point(Float.parseFloat(s[k]), 0);
          points.add(p_temp);
          k = k + 1;
        }
        else{
          Point p_temp = new Point(0, Float.parseFloat(s[k]));
          points.add(p_temp);
          k = k + 1;          
        }
      }
    }
    else if (cmd.get(i) == 'A' || cmd.get(i) == 'a'){
      for (int j = 0; j < cmd_count.get(i); j++){
        if (j % 4 != 1){       
          Point p_temp = new Point(Float.parseFloat(s[k]), Float.parseFloat(s[k+1]));
          points.add(p_temp);
          k = k + 2;
        }
        else{
          Point p_temp = new Point(Float.parseFloat(s[k]), 0);
          points.add(p_temp);
          k = k + 1;
        }
      }     
    }
    else if (cmd.get(i) == 'Z' || cmd.get(i) == 'z'){
      for (int j = 0; j < cmd_count.get(i); j++){
        Point p_temp = new Point(0, 0);
        points.add(p_temp);
      }      
    }
  }
  
  //for (int i = 0; i < cmd_count.size(); i++){
  //  print(cmd_count.get(i) + "" + cmd.get(i) + " ");
  //}
  //println();
  
  //for (int i = 0; i < drawing_cmd.size(); i++){
  //  print(drawing_cmd.get(i) + " ");
  //}
  //println();
  
  //for (int i = 0; i < points.size(); i++){
  //  println("points[" + i + "]: " + points.get(i).x + " " + points.get(i).y);
  //}
}

void turnRelativeToAbsoluteCoordinates(){
  char c;
  Point p_temp;
  
  for (int i = 0; i < points.size(); i++){
    p_temp = new Point(points.get(i).x, points.get(i).y);
    abs_points.add(p_temp);
  }
  
  p_temp = new Point(abs_points.get(0).x, abs_points.get(0).y);
  
  for (int i = 1; i < drawing_cmd.size(); i++){
    c = drawing_cmd.get(i);
    
    if (c == 'M' || c == 'L' || c == 'Q' || c == 'T' || c == 'C' || c == 'S' || c == 'A'){
      p_temp.set(points.get(i).x, points.get(i).y);
    }
    
    else if (c == 'H'){
      p_temp.set(points.get(i).x, abs_points.get(i - 1).y);
      abs_points.get(i).set(p_temp.x, p_temp.y);
    }
    
    else if (c == 'V'){
      p_temp.set(abs_points.get(i - 1).x, points.get(i).y);
      abs_points.get(i).set(p_temp.x, p_temp.y);
    }
    
    else if (c == 'm' || c == 'l' || c == 't' || c == 'h' || c == 'v'){
      p_temp.set(p_temp.x + points.get(i).x, p_temp.y + points.get(i).y);
      abs_points.get(i).set(p_temp.x, p_temp.y);
    }
    
    else if (c == 'q' || c == 's'){
      abs_points.get(i).set(p_temp.x + points.get(i).x, p_temp.y + points.get(i).y);
      p_temp.set(p_temp.x + points.get(i + 1).x, p_temp.y + points.get(i + 1).y);
      abs_points.get(i + 1).set(p_temp.x, p_temp.y);
      
      i = i + 1;
    }
    
    else if (c == 'c'){
      abs_points.get(i).set(p_temp.x + points.get(i).x, p_temp.y + points.get(i).y);
      abs_points.get(i + 1).set(p_temp.x + points.get(i + 1).x, p_temp.y + points.get(i + 1).y);
      p_temp.set(p_temp.x + points.get(i + 2).x, p_temp.y + points.get(i + 2).y);
        
      abs_points.get(i + 2).set(p_temp.x, p_temp.y);
      
      i = i + 2;
    }
    
    else if (c == 'a'){
      p_temp.set(p_temp.x + points.get(i + 3).x, p_temp.y + points.get(i + 3).y);
      abs_points.get(i + 3).set(p_temp.x, p_temp.y);
      
      i = i + 3;
    }
    
    else if (c == 'Z' || c == 'z'){
      int find_m = i;
      while (drawing_cmd.get(find_m) != 'm' && drawing_cmd.get(find_m) != 'M'){
        find_m--;
      }
      p_temp.x = abs_points.get(find_m).x;
      p_temp.y = abs_points.get(find_m).y;
      
      abs_points.get(i).set(p_temp.x, p_temp.y);
    }
  }
  
  //println('\n' + "ABSOLUTE POINTS BEFORE TRANSFORMATION: ");
  //for (int i = 0; i < abs_points.size(); i++){
  //  println("abs_points[" + i + "]: " + abs_points.get(i).x + " " + abs_points.get(i).y);
  //}
  //println();
}

void drawPoint(){
   //for (int i = 0; i < points.size(); i++){
   //  points.get(i).dot(POINT_COLOR);
   //}
   Point p1 = new Point(256, 0);
   p1.dot(POINT_COLOR);
   
   Point p2 = new Point(6.79, 64.58);
   p2.dot(POINT_COLOR);   
}

void addDrawingPoints(){
  //drawing_points.clear();
  //dont_connect.clear();
  
  char c;
  char pre_c = '?';
  Point p_temp;
  
  dont_connect.add(drawing_points.size() - 1);
  drawing_points.add(new Point(0, 0));
  
  for (int i = 0; i < drawing_cmd.size(); i++){
    boolean similarity = true;
    c = drawing_cmd.get(i);
    if (c != pre_c){
      pre_c = c;
      similarity = false;
    }
    
    if (c == 'M' || c == 'm'){
      p_temp = abs_points.get(i);
      drawing_points.add(p_temp);
      if (!similarity){
        dont_connect.add(drawing_points.size() - 2);
      }
      else{
        if (pre_c == 'm'){
          dont_connect.add(drawing_points.size() - 2);
        }
      }
    }
    
    if (c == 'L' || c == 'l' || c == 'H' || c == 'h' || c == 'V' || c == 'v'){
      p_temp = abs_points.get(i);
      drawing_points.add(p_temp);
    }
    
    if (c == 'Q' || c == 'q'){
      Point p00, p10, p20;
      p00 = abs_points.get(i - 1);
      p10 = abs_points.get(i);
      p20 = abs_points.get(i + 1);
      
      drawQuadraticCurve(p00, p10, p20);
      i = i + 1;
    }
    
    if (c == 'T' || c == 't'){
      Point p00, p10, p20;
      p00 = abs_points.get(i - 1);
      //diem p10 la diem doi xung voi ...
      p10 = new Point(2 * abs_points.get(i - 1).x - abs_points.get(i - 2).x, 2 * abs_points.get(i - 1).y - abs_points.get(i - 2).y);
      p20 = abs_points.get(i);
      
      drawQuadraticCurve(p00, p10, p20);
    }    
    
    if (c == 'C' || c == 'c'){
      Point p00, p10, p20, p30;
      p00 = abs_points.get(i - 1);
      p10 = abs_points.get(i);
      p20 = abs_points.get(i + 1);
      p30 = abs_points.get(i + 2);
      
      drawBezierCurve(p00, p10, p20, p30);
      i = i + 2;
    }
    
    if (c == 'S' || c == 's'){
      Point p00, p10, p20, p30; 
      p00 = abs_points.get(i - 1);
      //p10 la diem doi xung voi      
      p10 = new Point(2 * abs_points.get(i - 1).x - abs_points.get(i - 2).x, 2 * abs_points.get(i - 1).y - abs_points.get(i - 2).y);
      p20 = abs_points.get(i);
      p30 = abs_points.get(i + 1);    
      
      drawBezierCurve(p00, p10, p20, p30);
      i = i + 1;      
    }
    
    if (c == 'A' || c == 'a'){
      Point p_start, p_end;
      float rx_cmd, ry_cmd;
      p_start = abs_points.get(i - 1);
      p_end = abs_points.get(i + 3);
      rx_cmd = abs_points.get(i).x;
      ry_cmd = abs_points.get(i).y;
      
      float large_flag = abs_points.get(i + 2).x;
      float sweep_flag = abs_points.get(i + 2).y;
      
      drawArc(p_start, rx_cmd, ry_cmd, p_end, large_flag, sweep_flag);
      i = i + 3;
    }
    
    //Khi gap lenh Z, noi lai diem ma bat dau la lenh M, da duoc danh dau tai vi tri cuoi cung tai Array dont_connect
    if (c == 'Z' || c == 'z'){
      //p_temp = drawing_points.get(dont_connect.get(dont_connect.size() - 1) + 1);
      p_temp = abs_points.get(i);
      drawing_points.add(p_temp);
    }
  }
  
  //Point p_start = new Point(200, 800);
  //Point p_end = new Point(800, 800);
  //drawArc(p_start, 100, 50, p_end);
  
  ////hien thi cac diem ma se khong duoc noi do thay doi vi tri but bang lenh m hoac M
  //for (int i = 0; i < dont_connect.size(); i++){
  //  print(dont_connect.get(i) + " ");
  //  println();
  //}
}

void drawQuadraticCurve(Point p00, Point p10, Point p20){
   Point p01, p11, p02;
   
   for (float i = 0; i < 1.01; i+= 0.1){
       p01 = new Point((1-i) * p00.x + i * p10.x, (1-i) * p00.y + i * p10.y);
       p11 = new Point((1-i) * p10.x + i * p20.x, (1-i) * p10.y + i * p20.y);
       
       p02 = new Point((1-i) * p01.x + i * p11.x, (1-i) * p01.y + i * p11.y);
       
       drawing_points.add(p02);
   }  
}

void drawBezierCurve(Point p00, Point p10, Point p20, Point p30){
   //this is where the algorithm are used
   Point p01, p11, p21, p02, p12, p03;
   
   for (float i = 0; i < 1.01; i+= 0.1){
       p01 = new Point((1-i) * p00.x + i * p10.x, (1-i) * p00.y + i * p10.y);
       p11 = new Point((1-i) * p10.x + i * p20.x, (1-i) * p10.y + i * p20.y);
       p21 = new Point((1-i) * p20.x + i * p30.x, (1-i) * p20.y + i * p30.y);
       
       p02 = new Point((1-i) * p01.x + i * p11.x, (1-i) * p01.y + i * p11.y);
       p12 = new Point((1-i) * p11.x + i * p21.x, (1-i) * p11.y + i * p21.y);
       
       p03 = new Point((1-i) * p02.x + i * p12.x, (1-i) * p02.y + i * p12.y);
       
       drawing_points.add(p03);
   }
}

void drawArc(Point p_start, float rx_cmd, float ry_cmd, Point p_end, float large_flag, float sweep_flag){
  if (rx_cmd != 0 && ry_cmd != 0){
  
  //tinh toan cac tham so cua elip: t - he so giua rx va ry o lenh A; rx, ry - ban kinh; cx, cy - toa do tam cua elip
  float dx = p_end.x - p_start.x;
  float dy = p_end.y - p_start.y;
  float t = rx_cmd / ry_cmd;
  float ry = sqrt((dx / 2 * dx / 2) / (t * t) + (dy / 2 * dy / 2));
  float rx = ry * t;
  println("hihi = " + rx + ", " + ry);
  
  float x1, y1, x2, y2;
  float cx, cy, cx1, cy1, cx2, cy2;
  
  //neu ban kinh tinh toan nho hon ban kinh o cmd (r < r_cmd) thi ban kinh elip se la ban kinh o cmd
  //khi gan r = r_cmd thi ta phai xac dinh vi tri tam cua elip bang pt (x-cx)2/rx2 + (y-cy)2/ry2 = 1
  //xac dinh duoc hai toa do tam elip, mot vi tri cho large+sweep = 0+1 hoac 1+0 ; mot vi tri cho large+sweep = 0+0 hoac 1+1
  if (rx >= rx_cmd && ry >= ry_cmd){
    cx = (p_end.x + p_start.x) / 2;
    cy = (p_end.y + p_start.y) / 2;
  }
  else{
    rx = rx_cmd;
    ry = ry_cmd;
    cx = (p_end.x + p_start.x) / 2;
    cy = (p_end.y + p_start.y) / 2;
    
    x1 = p_start.x;
    y1 = p_start.y;
    x2 = p_end.x;
    y2 = p_end.y;
    
    //ax * x + bx = ay * y + y
    float ax = 2 * -(x1 - x2);
    float bx = x1 * x1 - x2 * x2;
    float ay = 2 * -(y2 - y1);
    float by = y2 * y2 - y1 * y1;
    println(ax + ", " + bx + ", " + ay + ", " + by);
    
    //ax * x + bx = 0
    if (y1 == y2){
      cx1 = -bx / ax;
      cx2 = -bx / ax;
      
      cy1 = sqrt(1 - (x1 - cx1) / rx * (x1 - cx1) / rx) * ry + cy;
      cy2 = sqrt(1 - (x1 - cx2) / rx * (x1 - cx2) / rx) * ry + cy;      
    }
    else{
    // y = ax + b
    float a = (ax * (ry / rx) * (ry / rx)) / ay;
    float b = (bx * (ry / rx) * (ry / rx) - by) / ay;
    float c;
    
    // a0 + a1 * x + a2 * x2 = 0;
    float a2 = 1 / (rx * rx) + (a / ry) * (a / ry);
    float a1 = -2 * (x1 / (rx * rx) + (y1 - b) * a / (ry * ry));
    float a0 = (x1 / rx) * (x1 / rx) + (y1 - b) / ry * (y1 - b) / ry - 1;
    
    float delta = a1 * a1 - 4 * a2 * a0;
    println("delta = " + delta);
    
    println("large flag = " + large_flag + ", sweep flag = " + sweep_flag);
    cx1 = (-a1 + sqrt(delta)) / (2 * a2);
    cy1 = a * cx1 + b;
    println("cx1 = " + cx1 + ", cy1 = " + cy1);
    
    cx2 = (-a1 - sqrt(delta)) / (2 * a2);
    cy2 = a * cx2 + b;
    println("cx2 = " + cx2 + ", cy2 = " + cy2);  
    }

    //chuan hoa lai gia tri large va sweep
    if (large_flag != 0){
      large_flag = 1;
    }
    if (sweep_flag != 0){
      sweep_flag = 1;
    }
    
    //phuong trinh di qua 2 diem p_start va p_end: ax + by + c = 0;    
    float a = y1 - y2;
    float b = -(x1 - x2);
    float c = -x1 * (y1 - y2) + y1 * (x1 - x2);
    
    if (large_flag + sweep_flag != 1){//00 hoac 11
      if (condition1(a, b, c, x1, y1, x2, y2, cx1, cy1)){
        cx = cx1;
        cy = cy1;
      }
      else{
        cx = cx2;
        cy = cy2;
      }
    }
    else{
      if (condition1(a, b, c, x1, y1, x2, y2, cx1, cy1)){
        cx = cx2;
        cy = cy2;
      }
      else{
        cx = cx1;
        cy = cy1;
      }      
    }  
  }
  
  println("dx = " + dx + ", dy = " + dy);
  println("rx = " + rx + ", ry = " + ry);
  println("center = " + cx + " " + cy);
  
  
  //x = rx * cos(deg) + cx; y = ry * sin(deg) + cy
  float deg_start = (float) Math.toDegrees(Math.atan2((p_start.y - cy) / ry, (p_start.x - cx) / rx));
  float deg_end = (float) Math.toDegrees(Math.atan2((p_end.y - cy) / ry, (p_end.x - cx) / rx));
  //println("deg_start_before = " + deg_start);
  if (deg_start < 0){
    deg_start = deg_start + 360;
  }
  if (deg_end <= 0){
    deg_end = deg_end + 360;
  }
  println("goc deg_start = " + deg_start);
  println("goc deg_end = " + deg_end);
  println("-----------");
  
  
  //00 -> quay nguoc, 01 -> quay thuan, 10 -> quay nguoc, 11 -> quay thuan
  //sweep_flag = 0 -> quay nguoc / sweep_flag = 1 -> quay thuan
  if (sweep_flag == 1){//quay thuan tu p_start -> p_end bang cach cho gia tri deg_start < deg_end
    float deg;
    float deg_start_temp = deg_start;
    if (deg_start < deg_end){
    }
    else{
      deg_start = deg_start - 360;
    }
    for (int i = 0; i <= 20; i++){
      deg = deg_start + (deg_end - deg_start) / 20.0 * i;
      float x = rx * (float) Math.cos(Math.toRadians(deg)) + cx;
      float y = ry * (float) Math.sin(Math.toRadians(deg)) + cy;
      drawing_points.add(new Point(x, y));
    }
    deg_start = deg_start_temp;
  }
  else{//quay nguoc tu p_start -> p_end bang cach cho gia tri deg_start > deg_end
    float deg;
    float deg_end_temp = deg_end;
    if (deg_start > deg_end){
    }
    else{
      deg_end = deg_end - 360;
    }
    for (int i = 0; i <= 20; i++){
      deg = deg_start + (deg_end - deg_start) / 20.0 * i;
      float x = rx * (float) Math.cos(Math.toRadians(deg)) + cx;
      float y = ry * (float) Math.sin(Math.toRadians(deg)) + cy;
      drawing_points.add(new Point(x, y));
    }
    deg_end = deg_end_temp;
  }
  
  }
}

//diem (x1, y1) nam cung phia voi (x2, y2) bo la duong thang ax + by + c = 0
boolean sameSide(float a, float b, float c, float x1, float y1, float x2, float y2){
  if ((a * x1 + b * y1 + c) * (a * x2 + b * y2 + c) > 0){
    return true;
  }
  else{
    return false;
  }
}

boolean condition1(float a, float b, float c, float x1, float y1, float x2, float y2, float cx1, float cy1){
  if ((x1 == x2 && y1 > y2 && cx1 < x1) || (x1 == x2 && y1 < y2 && cx1 > x1)
   || (y1 == y2 && x1 > x2 && cy1 > y1) || (y1 == y2 && x1 < x2 && cy1 < y2)
   || (x1 > x2 && y1 > y2 && !sameSide(a, b, c, cx1, cy1, x1, y2)) || (x1 < x2 && y1 > y2 && sameSide(a, b, c, cx1, cy1, x1, y2))
   || (x1 > x2 && y1 < y2 && sameSide(a, b, c, cx1, cy1, x1, y2)) || (x1 < x2 && y1 < y2 && !sameSide(a, b, c, cx1, cy1, x1, y2))){
    return true;
  }
  else{
    return false;
  }
}

void initiateArrayForTransformation(){
  Point p_temp;  
  
  //gan array abs_points sang abs_p_transform. Lam dieu nay duy nhat 1 lan cho 1 path, do do phai check xem da thuc hien lan thu may roi
  for (int i = 0; i < abs_points.size(); i++){
    p_temp = new Point(abs_points.get(i).x, abs_points.get(i).y);
    abs_p_transform.add(p_temp);
  }
}

void transform(String cmd, String para){
  
  //nếu transform_att gồm nhiều cmd cùng lúc: translate và scale, translate và rotate
  if (cmd.contains(",")){
    String[] cmd_splited = cmd.split(",");
    String[] para_splited = para.split(",");
    
    int i_temp = 0;
    for (int i = 0; i < cmd_splited.length; i++){
      if (cmd_splited[i].equals("translate")){
        i_temp = i;
        i++;
      }
      transform(cmd_splited[i], para_splited[i]);
    }
    transform(cmd_splited[i_temp], para_splited[i_temp]);
  }
  else{
  if (cmd.equals("none")){
  }
  
  else if (cmd.equals("translate")){
    String[] para_array = para.split(" ");
    
    float e = 0;
    float f = 0;
    
    if (para_array.length == 1){
      e = Float.parseFloat(para_array[0]);      
    }
    else if (para_array.length == 2){
      e = Float.parseFloat(para_array[0]);
      f = Float.parseFloat(para_array[1]);
    }
    
    String matrix_para = "1 0 0 1 " + e + " " + f;
    transform("matrix", matrix_para);
  }
  
  else if (cmd.equals("skewX")){
    String[] para_array = para.split(" ");
    float deg = Float.parseFloat(para_array[0]);
    
    double c_double = Math.tan(Math.toRadians(deg));    
    float c = (float) c_double;
    
    String matrix_para = "1 0 " + c + " 1 0 0";
    transform("matrix", matrix_para);
  }
  
  else if (cmd.equals("skewY")){
    String[] para_array = para.split(" ");
    float deg = Float.parseFloat(para_array[0]);
    
    double b_double = Math.tan(Math.toRadians(deg));    
    float b = (float) b_double;
    
    String matrix_para = "1 " + b + " 0 1 0 0";
    transform("matrix", matrix_para);
  }
  
  else if (cmd.equals("scale")){
    String[] para_array = para.split(" ");
    float a = 1;
    float d = 1;
    if (para_array.length == 1){
      a = Float.parseFloat(para_array[0]);
      d = a;
    }
    else if (para_array.length == 2){
      a = Float.parseFloat(para_array[0]);
      d = Float.parseFloat(para_array[1]);
    }
    
    String matrix_para = a + " 0 0 " + d + " 0 0";
    transform("matrix", matrix_para);
  }
  
  else if (cmd.equals("rotate")){
    String[] para_array = para.split(" ");
    float deg = 0;
    float a = 1;
    float b = 0;
    float c = 0;
    float d = 1;
    float e = 0;
    float f = 0;
    if (para_array.length == 1){
      deg = Float.parseFloat(para_array[0]);
      
      a = (float) Math.cos(Math.toRadians(deg));
      b = (float) Math.sin(Math.toRadians(deg));
      c = -b;
      d = a;
    }
    else if (para_array.length == 3){
      deg = Float.parseFloat(para_array[0]);
      e = Float.parseFloat(para_array[1]);
      f = Float.parseFloat(para_array[2]);
      
      String translate_para = (-e) + " " + (-f);
      transform("translate", translate_para);
      String rotate_para = Float.toString(deg);
      transform("rotate", rotate_para);
      translate_para = e + " " + f;
      transform("translate", translate_para);      
    }
    
    String matrix_para = a + " " + b + " " + c + " " + d + " 0 0";
    transform("matrix", matrix_para);
  }  
  
  else if (cmd.equals("matrix")){
    String[] para_array = para.split(" ");
    float a = Float.parseFloat(para_array[0]);
    float b = Float.parseFloat(para_array[1]);
    float c = Float.parseFloat(para_array[2]);
    float d = Float.parseFloat(para_array[3]);
    float e = Float.parseFloat(para_array[4]);
    float f = Float.parseFloat(para_array[5]);

    float oldX, oldY, newX, newY;
    for (int i = 0; i < abs_points.size(); i++){
      oldX = abs_points.get(i).x;
      oldY = abs_points.get(i).y;
      newX = a * oldX + c * oldY + e;
      newY = b * oldX + d * oldY + f;
      
      abs_p_transform.get(i).set(newX, newY);
    }
    
    for (int i = 0; i <abs_points.size(); i++){
      if (drawing_cmd.get(i) == 'a' || drawing_cmd.get(i) == 'A'){
        oldX = abs_points.get(i).x;
        oldY = abs_points.get(i).y;
        newX = Math.abs(a * oldX);
        newY = Math.abs(d * oldY);
        abs_p_transform.get(i).set(newX, newY);
        
        oldX = abs_points.get(i + 1).x;
        oldY = abs_points.get(i + 1).y;
        abs_p_transform.get(i + 1).set(oldX, oldY);
        
        oldX = abs_points.get(i + 2).x;
        oldY = abs_points.get(i + 2).y;
        if (a * d < 0){
          if (oldY != 0){
            newY = 0;
          }
          else{
            newY = 1;
          }
        }
        else{
          newY = oldY;
        }
        abs_p_transform.get(i + 2).set(oldX, newY);
        
        oldX = abs_points.get(i + 3).x;
        oldY = abs_points.get(i + 3).y;
        println("oldX 3 = " + oldX + ", oldY 3 = " + oldY);    
        newX = a * oldX + e;
        newY = d * oldY + f;
        println("newX 3 = " + newX + ", newY 3 = " + newY);
        abs_p_transform.get(i + 3).set(newX, newY);
        
        i = i + 3;
      }
    }
  }
  
  for (int i = 0; i < abs_p_transform.size(); i++){
    abs_points.get(i).set(abs_p_transform.get(i).x, abs_p_transform.get(i).y);
  }
  
  //for (int i = 0; i < abs_points.size(); i++){
  //  println("abs_points[" + i + "]: " + abs_points.get(i).x + " " + abs_points.get(i).y);
  //}
  println();
  }
}

void minimizeDrawingPoints(){
  float x1, y1, x2, y2;
  int k = 1;
  int m = 0;
  
  for (int i = 0; i < drawing_points.size() - 1; i++){
    x1 = drawing_points.get(i).x;
    y1 = drawing_points.get(i).y;
    if (i != dont_connect.get(k)){
      //println("hihi");
      x2 = drawing_points.get(i + 1).x;
      y2 = drawing_points.get(i + 1).y;
      if (dist(x1, y1, x2, y2) < DIST_NOT_DRAW){
        //println("distance = " + dist(x1, y1, x2, y2));
        dont_connect.add(k, i);
        m++;
      }
    }
    else{
      if (k + m < dont_connect.size() - 1){
        k++;
      }
    }
  }
  
  sort();
}

void sort(){
  int n = dont_connect.size();
  int[] array = new int[n];
  for (int i = 0; i < n; i++){
    array[i] = dont_connect.get(i);
  }
  for (int i = 0; i < n - 1; i++){
    for (int j = i + 1; j < n; j++){
      if (array[i] > array[j]){
        int temp = array[i];
        array[i] = array[j];
        array[j] = temp;
      }
    }
  }
  dont_connect.clear();
  dont_connect.add(array[0]);
  for (int i = 1; i < n; i++){
    if (array[i] != array[i - 1]){
      dont_connect.add(array[i]);
    }
  }
}

void clearArray(){
  points.clear();
  abs_points.clear();
  //println("done clearing: abs_points.size() = " + abs_points.size());
  abs_p_transform.clear();
  //println("done clearing: abs_p_transform.size() = " + abs_p_transform.size());  
  drawing_cmd.clear();
  cmd.clear();
  cmd_count.clear();
  m_2nd_index.clear();
}

void printArray_(){
  println("PRINT ARRAY:");
  println("size of drawing_points: " + drawing_points.size());
  println("size of dont_connect: " + dont_connect.size());
  
  //for (int i = 0; i < drawing_points.size(); i++){
  //  println("drawing_points[" + i + "]: " + drawing_points.get(i).x + " " + drawing_points.get(i).y);
  //}
  
  //for (int i = 0; i < dont_connect.size(); i++){
  //  println("dont_connect[" + i + "]: " + dont_connect.get(i));
  //}

  
  for (int i = 0; i < 100; i++){
    print("-");
  }
  println();
}

void draw_(){  
  //noi cac diem cua Array drawing_points lai voi nhau, ta duoc ket qua
  int k = 1;
  for (int j = 0; j < drawing_points.size() - 1; j++){
    if (j != dont_connect.get(k)){
      drawing_points.get(j).connect(drawing_points.get(j + 1), POINT_CONNECTION_COLOR);
      //if (drawing_points.get(j).x == 0 && drawing_points.get(j).y == 0){
      //  println("hihi: " + j);
      //}
    }
    else{
      if (k < dont_connect.size() - 1){
        k++;
      }
    }
  }
}

XML beautifyXML(XML xml){
  String s1 = xml.toString();
  String s2 = s1;
  int start_index = s1.indexOf("<svg");
  int end_index = s1.indexOf("</svg>") + 5;
  
  int end_index_of_smallest_element = s1.lastIndexOf("/>") + 1;
  ArrayList<String> names = new ArrayList<String>();
  
  //tìm vị trí của các element cha </g>, </style>,... thêm '\n' vào trước chúng
  int k = 0;
  int k_count = 0;
  while(true){
    k = s1.indexOf("</", k);
    
    if (s1.charAt(k - 1) != '\n'){
      k_count++;
      s2 = s2.substring(0, k-1 + k_count) + '\n' + s2.substring(k-1 + k_count, s2.length());
    }
    
    //tìm tên của </style>, </g> là name = "style", "g"
    int k_temp = k + 1;
    String name = "";
    
    while (s1.charAt(k) != '>'){
      k++;
    }
    for (int i = k_temp; i < k; i++){
      char c = s1.charAt(i);
      if (Character.isLetter(c)){
        name = name + c;
      }
    }
    
    //nếu có nhiều </g> thì chỉ thêm một "g" vào mảng names
    boolean be_existing = false;
    for (int i = 0; i < names.size(); i++){
      if (name == names.get(i)){
        be_existing = true;
        break;
      }
    }
    if (!be_existing){
      names.add(name);
    }
    
    //khi nào gặp </svg> cuối cùng thì dừng vòng while
    if (k == end_index){
      break;
    }
  }
  
  //duyệt toàn bộ mảng names -> mỗi name lại kiểm tra toàn bộ xml, lấy vị trí của "<style" -> đưa vào mảng vị trí indexes
  s1 = s2;
  k = 0;
  k_count = 0;
  ArrayList<Integer> indexes = new ArrayList<Integer>(); 
  for (int i = 0; i < names.size(); i++){
    String name = names.get(i);
    
    while(true){
      k = s1.indexOf("<" + name, k);   
      if (k == -1 || k == 0){
        break;
      }
      if (s1.charAt(k - 1) != '\n'){
        indexes.add(k - 1);
      }
      k = k + 1;
    }
  }
  
  //sắp xếp mảng indexes từ nhỏ -> lớn
  indexes = quickSort(indexes);
  
  //thêm '\n' vào trước <style>, <g>
  for (int i = 0; i < indexes.size(); i++){
    k = indexes.get(i);
    s2 = s2.substring(0, k + i + 1) + '\n' + s2.substring(k + i + 1, s2.length());
  }
  
  
  //tìm vị trí của "/>" (vị trí của smallest_elements) lùi về đầu để lấy vị trí k_backward của "<path" rồi thêm '\n'
  s1 = s2;
  k = 0;
  k_count = 0;
  while(true){
    k = s1.indexOf("/>", k);
    
    //khi nào không tìm thấy nữa (k=-1) thì dừng vòng while
    if (k == -1){
      break;
    }
    int k_backward = k;
    while (s1.charAt(k_backward) != '<'){
      k_backward--;
    }
    
    k = k + 1;
    
    if (s1.charAt(k_backward - 1) != '\n'){
      k_count++;
      s2 = s2.substring(0, k_backward-1 + k_count) + '\n' + s2.substring(k_backward-1 + k_count, s2.length());     
    }
  }
  println("AFTER BEAUTIFYING");
  println("xml = " + s2 + '\n');
  
  XML xml_returned = parseXML(s2);
  return xml_returned;
}

ArrayList<Integer> quickSort(ArrayList<Integer> arr){
  
  for (int i = 0; i < arr.size() - 1; i++){
    for (int j = i + 1; j < arr.size(); j++){
      int x = arr.get(i);
      int y = arr.get(j);
      if (x > y){
        arr.set(i, y);
        arr.set(j, x);
      }
    }
  }
  return arr;
}
