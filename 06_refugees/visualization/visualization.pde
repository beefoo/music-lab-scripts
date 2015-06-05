/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// resolution
int canvasW = 1280;
int canvasH = 720;
float cx = 0.5 * canvasW;
float cy = 0.5 * canvasH;

// colors
color bgColor = #000000;

// data
String years_file = "years_refugees.json";
JSONArray yearsJSON;
ArrayList<Year> years;
Year previous_year;

// images and graphics
PImage img_map;
String img_map_file = "map.png";
PImage img_map_overlay;
String img_map_overlay_file = "map_overlay.png";

// components
float[] strokeWeightRange = {1, 4};
float[] strokeAlphaRange = {20, 100};

// text
color textC = #ede1e1;
int fontSize = 36;
PFont font = createFont("OpenSans-Semibold", fontSize, true);

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(HSB, 360, 100, 100);
  frameRate(fps);
  smooth();
  noStroke();  
  background(bgColor);
  ellipseMode(CENTER);
  textFont(font);
  textAlign(LEFT, CENTER);
  
  img_map = loadImage(img_map_file);
  img_map_overlay = loadImage(img_map_overlay_file);
  
  // load the data
  yearsJSON = loadJSONArray(years_file);
  
  years = new ArrayList<Year>();
  for (int i = 0; i < yearsJSON.size(); i++) {  
    JSONObject year = yearsJSON.getJSONObject(i);
    years.add(new Year(year));
  }
  
  image(img_map, 0, 0, canvasW, canvasH);
  
  previous_year = years.get(0);
  stopMs = years.get(years.size()-1).getStopMs();
  fill(textC);
  text(previous_year.getYear(), 30, 30);
  
  // noLoop();
}

void draw(){
  
  Year current_year = years.get(years.size()-1);
  
  for (int i = 0; i < years.size(); i++) {  
    Year y = years.get(i);
    if (y.isActive(elapsedMs)) {
      current_year = y;
      break;
    }
  }
  
  if (current_year.getYear() != previous_year.getYear()) {
    previous_year = current_year;
    image(img_map, 0, 0, canvasW, canvasH); 
    fill(textC);
    text(current_year.getYear(), 30, 30);   
  }  
  
  ArrayList<Refugee> refugees = current_year.getRefugees();
  
  
  noFill();
  for (int i = 0; i < refugees.size(); i++) {
    Refugee r = refugees.get(i);
    
    if (r.isActive(elapsedMs)) {
      float x1 = r.getX();
      float y1 = r.getY();
      r.move();
      float x2 = r.getX();
      float y2 = r.getY();
      color c = r.getColor(elapsedMs);
      float count = r.getCount();
      float weight = count * (strokeWeightRange[1]-strokeWeightRange[0]) + strokeWeightRange[0];
      float alpha = count * (strokeAlphaRange[1]-strokeAlphaRange[0]) + strokeAlphaRange[0];
      strokeWeight(weight);
      stroke(c, alpha);
      line(x1, y1, x2, y2);
    }    
  }
  
  // increment time
  elapsedMs += (1.0/fps) * 1000;
  
  // save image
  if(captureFrames) {
    saveFrame(outputFrameFile);
  }
  
  // check if we should exit
  if (elapsedMs > stopMs) {
    exit(); 
  }
}

void mousePressed() {
  saveFrame("output/frame.png");
  exit();
}

float angleBetweenPoints(float x1, float y1, float x2, float y2){
  float deltaX = x2 - x1,
        deltaY = y2 - y1;  
  return 1.0 * atan2(deltaY, deltaX) * 180.0 / PI;
}

float[] translatePoint(float x, float y, float angle, float distance){
  float[] newPoint = new float[2];
  float r = radians(angle);
  
  newPoint[0] = x + distance*cos(r);
  newPoint[1] = y + distance*sin(r);
  
  return newPoint;
}

class Year
{
  ArrayList<Refugee> refugees;
  float start_ms, stop_ms;
  int year;
  
  Year(JSONObject _year) {    
    year = _year.getInt("y");
    start_ms = _year.getFloat("ms0");
    stop_ms = _year.getFloat("ms1");
    refugees = new ArrayList<Refugee>();
    
    JSONArray refugeesJSON = _year.getJSONArray("r");
      for (int i = 0; i < refugeesJSON.size(); i++) {  
      JSONObject refugee = refugeesJSON.getJSONObject(i);
      refugees.add(new Refugee(refugee));
    }
  }
  
  ArrayList<Refugee> getRefugees(){
    return refugees;
  }
  
  float getStopMs(){
    return stop_ms;
  }
  
  int getYear(){
    return year;
  }
  
  boolean isActive(float ms) {
    return ms >= start_ms && ms < stop_ms; 
  }
}

class Refugee
{
  
  float start_ms, stop_ms, x, y, x1, y1, x2, y2, distance, angle, count_n, distance_step;
  
  Refugee(JSONObject _refugee) {    
    start_ms = _refugee.getFloat("ms0");
    stop_ms = _refugee.getFloat("ms1");
    x1 = round(_refugee.getFloat("x1"));
    y1 = round(_refugee.getFloat("y1"));
    x2 = round(_refugee.getFloat("x2"));
    y2 = round(_refugee.getFloat("y2"));
    distance = _refugee.getFloat("d");
    angle = angleBetweenPoints(x1, y1, x2, y2);
    count_n = _refugee.getFloat("c");
    
    x = x1;
    y = y1;
    distance_step = (1.0/fps) * 1000 / (stop_ms - start_ms) * distance;
  }
  
  boolean isActive(float ms) {
    return ms >= start_ms && ms < stop_ms; 
  }
  
  color getColor(float ms) {
    float lerp = getLerp(ms);
    color from = #ff3232; // red
    color to = #afef9b; // green
    return lerpColor(from, to, lerp);
  }
  
  float getCount() {
    return count_n;
  }
  
  float getLerp(float ms) {
    return (ms - start_ms) / (stop_ms - start_ms);
  }
  
  float getX() {
    return x; 
  }
  
  float getY() {
    return y; 
  }
  
  void move() {
    angle = angleBetweenPoints(x, y, x2, y2);
    float[] newPoint = translatePoint(x, y, angle, distance_step);
    x = round(newPoint[0]);
    y = round(newPoint[1]);    
  }
  
}

