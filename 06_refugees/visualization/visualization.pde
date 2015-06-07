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
float REFUGEE_UNIT = 100000;

// images and graphics
PImage img_map;
String img_map_file = "map.png";
PImage img_map_overlay;
String img_map_overlay_file = "map_overlay.png";

// components
float[] strokeWeightRange = {1, 1};
float[] strokeAlphaRange = {20, 100};
float[] wavelengthRange = {1, 40};
float yearX = 20;
float yearY = 30;

// infobox
float infoW = 210;
float infoH = 360;
float infoX = 0;
float infoY = canvasH - infoH;
color infoC = #000000;
float infoTransitionMs = 1000;
float[] infoAlphaRange = {100, 100};
float infoM = 20;
float infoNM = 26;
float infoTextM = 30;

// text
color textC = #ede1e1;
color textNumberC = #ea2525;
color[] lerpTextC = {#998c8c, #ffffff};
color[] lerpNumberC = {#aa4c4c, #ff6666};
int fontSizeLarge = 36;
PFont fontLarge = createFont("OpenSans-Semibold", fontSizeLarge, true);
int fontSize = 28;
PFont font = createFont("OpenSans-Semibold", fontSize, true);
int fontSizeSmall = 16;
PFont fontSmall = createFont("OpenSans-Semibold", fontSizeSmall, true);

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(HSB, 360, 100, 100);
  frameRate(fps);
  smooth();
  noStroke();  
  background(bgColor);
  ellipseMode(CENTER);
  textFont(fontLarge);
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
  text(previous_year.getYear(), yearX, yearY);
  
  // noLoop();
}

void draw(){
  
  Year current_year = years.get(years.size()-1);
  // ArrayList<Country> countries = current_year.getCountries();
  
  for (int i = 0; i < years.size(); i++) {  
    Year y = years.get(i);
    if (y.isActive(elapsedMs)) {
      current_year = y;
      break;
    }
  }
  
  // draw year
  if (current_year.getYear() != previous_year.getYear()) {
    previous_year = current_year;
    image(img_map, 0, 0, canvasW, canvasH);
    noStroke();
    fill(textC);
    textFont(fontLarge);
    text(current_year.getYear(), yearX, yearY);    
  }
  
  // draw infobox
  /* if (elapsedMs < current_year.getStartMs() + infoTransitionMs) {
    noStroke();
    fill(infoC);
    rect(infoX, infoY, infoW, infoH);  
    fill(textC);
    textFont(fontSmall);
    float ix = infoX+infoM,
          iy = infoY+infoM;
    text("MOST REFUGEES", ix, iy);
    iy += 5;  
    
    for (Country c : countries) {  
      iy += infoTextM;
      float lerp = c.getCountN();
      color colorText = lerpColor(lerpTextC[0], lerpTextC[1], lerp);
      fill(colorText);
      textFont(font);
      text(c.getOName(), ix, iy);
      iy += infoNM;
      color colorNumber = lerpColor(lerpNumberC[0], lerpNumberC[1], lerp);
      fill(colorNumber);
      textFont(fontSmall);
      text(c.getCount(), ix, iy);
    }    
  } */
  
  ArrayList<Refugee> refugees = current_year.getRefugees();  
  noFill();
  for (Refugee r : refugees) {
    ArrayList<RefugeeLine> rlines = r.getLines();
    for (RefugeeLine rl : rlines) {
      if (rl.isActive(elapsedMs)) {
        float x1 = rl.getX();
        float y1 = rl.getY();
        rl.move();
        float x2 = rl.getX();
        float y2 = rl.getY();      
        float countn = rl.getCountN();
        float weight = countn * (strokeWeightRange[1]-strokeWeightRange[0]) + strokeWeightRange[0];
        float alpha = countn * (strokeAlphaRange[1]-strokeAlphaRange[0]) + strokeAlphaRange[0];
        color c = rl.getColor(elapsedMs);
        
        strokeWeight(weight);
        stroke(c, alpha);
        pushMatrix();
        translate(rl.getX1(), rl.getY1());
        rotate(radians(rl.getAngle()));
        line(x1, y1, x2, y2);      
        popMatrix();
      }
    }        
  }
  
  // increment time
  elapsedMs += frameMs;
  
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

/* int getCountryIndex(ArrayList<Country> _countries, String _code){
  int index = -1;
  for (int i = 0; i < _countries.size(); i++) {  
    Country c = _countries.get(i);
    if (c.getCode().equals(_code) == true) {
      index = i;
      break;
    }
  }
  return index;
} */

float angleBetweenPoints(float x1, float y1, float x2, float y2){
  float deltaX = x2 - x1,
        deltaY = y2 - y1;  
  return 1.0 * atan2(deltaY, deltaX) * 180.0 / PI;
}

float halton(int hIndex, int hBase) {    
  float result = 0;
  float f = 1.0 / hBase;
  int i = hIndex;
  while(i > 0) {
    result = result + f * float(i % hBase);
    
    i = floor(i / hBase);
    f = f / float(hBase);
  }
  return result;
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
      refugees.add(new Refugee(refugee, _year));
    }
  }
  
  ArrayList<Refugee> getRefugees(){
    return refugees;
  }
  
  float getStartMs(){
    return start_ms;
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

class RefugeeLine
{
  float start_ms, stop_ms, x, y, x1, y1, x2, y2, distance, angle, count_n, distance_step, wavelength;
  
  RefugeeLine(JSONObject _refugee, JSONObject _year, int hindex) {
    start_ms = _refugee.getFloat("ms0");
    stop_ms = _refugee.getFloat("ms1");
    x1 = _refugee.getFloat("x1");
    y1 = _refugee.getFloat("y1");
    x2 = _refugee.getFloat("x2");
    y2 = _refugee.getFloat("y2");
    distance = _refugee.getFloat("d");
    angle = angleBetweenPoints(x1, y1, x2, y2);
    count_n = _refugee.getFloat("cn");  
    
    // add randomness
    float year_start_ms = _year.getFloat("ms0");
    float year_stop_ms = _year.getFloat("ms1");
    float rand = halton(hindex, 3);
    stop_ms = min(stop_ms + rand * (year_stop_ms-year_start_ms) * 0.4, year_stop_ms);
    wavelength = rand * (wavelengthRange[1]-wavelengthRange[0]) + wavelengthRange[0];
    
    x = 0;
    y = 0;
    distance_step = frameMs / (stop_ms - start_ms) * distance;
  }
  
  boolean isActive(float ms) {
    return ms >= start_ms && ms < stop_ms; 
  }
  
  float getAngle(){
    return angle;
  }
  
  color getColor(float ms) {
    float lerp = getLerp(ms);
    color from = #ff3232; // red
    color to = #afef9b; // green
    return lerpColor(from, to, lerp);
  }
  
  float getCountN() {
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
  
  float getX1() {
    return x1; 
  }
  
  float getY1() {
    return y1; 
  }
  
  void move() {
    float x2 = x + distance_step;
    float y2 = 1.0 * sin(-x2/distance*PI) * wavelength;
    if (angle>90 || angle<-45) {
      y2 = 1.0 * sin(x2/distance*PI) * wavelength;
    }
    x = x2;
    y = y2;
  }
}

class Refugee
{
  ArrayList<RefugeeLine> lines;
  
  String name;
  float x, y, count, count_n;
  
  Refugee(JSONObject _refugee, JSONObject _year) {
    name = _refugee.getString("on");
    x = _refugee.getFloat("x1");
    y = _refugee.getFloat("y1");
    count = _refugee.getFloat("c");
    count_n = _refugee.getFloat("cn");
    
    // add lines
    lines = new ArrayList<RefugeeLine>();
    int hindex = 0;
    float c = count;
    while(c > 0) {
      lines.add(new RefugeeLine(_refugee, _year, hindex));
      c = c - REFUGEE_UNIT;
      hindex++;
    }
  }
  
  float getCount() {
    return count; 
  }
  
  float getCountN() {
    return count_n;
  }
  
  String getCountryName() {
    return name;
  }
  
  ArrayList<RefugeeLine> getLines() {
    return lines;
  }
  
  float getX() {
    return x; 
  }
  
  float getY() {
    return y; 
  }
  
}

