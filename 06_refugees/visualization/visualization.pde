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

// config
float REFUGEE_UNIT = 100000;
int COUNTRY_LABEL_COUNT = 30;
float YEAR_FADE_TIME = 1000;

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
PGraphics g_map, g_labels, g_key;

// key
float yearX = 20;
float yearY = 20;

// lines
float[] strokeWeightRange = {1, 1};
float[] strokeAlphaRange = {20, 100};
float[] wavelengthRange = {1, 100};
float wavelengthVariance = 10;

// labels
float[] labelCircleRange = {5, 120};
color labelCircleC = #ffe900;
float labelCircleWeight = 0.5;

// text
color textC = #ede1e1;
color textC2 = #aa9898;
color textNumberC = #ea2525;
int fontSizeLarge = 36;
PFont fontLarge = createFont("OpenSans-Semibold", fontSizeLarge, true);
int fontSize = 24;
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
  frameRate(fps);
  smooth();
  noStroke();  
  background(bgColor);
  noFill();
  
  img_map = loadImage(img_map_file);
  
  // load the data
  yearsJSON = loadJSONArray(years_file);
  
  years = new ArrayList<Year>();
  for (int i = 0; i < yearsJSON.size(); i++) {  
    JSONObject year = yearsJSON.getJSONObject(i);
    years.add(new Year(year));
  }
  
  // Label layer
  g_labels = createGraphics(canvasW, canvasH);
  g_labels.textAlign(CENTER, BOTTOM); 
  g_labels.textFont(fontSmall);
  
  // Key layer
  g_key = createGraphics(canvasW, canvasH);  
  g_key.noStroke();   
  
  // Init drawing
  previous_year = years.get(0);
  stopMs = years.get(years.size()-1).getStopMs();
  
  // noLoop();
}

void draw(){
  
  ArrayList<Year> previousYearsLines = new ArrayList<Year>();
  
  // select current year
  Year current_year = years.get(years.size()-1);  
  for (int i = 0; i < years.size(); i++) {  
    Year y = years.get(i);
    if (y.isActive(elapsedMs)) {
      current_year = y;
      break;
    } else {
      previousYearsLines.add(y);
    }
  }
  
  // check if this is a new year
  Boolean isNewYear = false;
  if (current_year.getYear() != previous_year.getYear()) {
    isNewYear = true;
    previous_year = current_year;
  } 
  
  // new year, draw year 
  if (isNewYear || frameCount==1) {
    if (frameCount > 1) {
      g_key.clear();
    }    
    g_key.beginDraw();
    g_key.textAlign(LEFT, TOP); 
    g_key.fill(textC);
    g_key.textFont(fontLarge);
    g_key.text(current_year.getYear(), yearX, yearY);
    g_key.textFont(font);
    g_key.text(current_year.getPopulation(), yearX + 196, yearY + 45);
    g_key.text(current_year.getCount() + " (1 in " + current_year.getCountPer()+")", yearX + 196, yearY + 75);
    g_key.fill(textC2);    
    g_key.text("World Population: ", yearX, yearY + 45);
    g_key.text("World Refugees: ", yearX, yearY + 75);    
    g_key.endDraw();
  }
  
  // draw lines
  ArrayList<Refugee> refugees = current_year.getRefugees();
  PGraphics g_lines = current_year.getGraphics();
  g_lines.beginDraw();
  g_lines.noFill();
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
        
        g_lines.strokeWeight(weight);
        g_lines.stroke(c, alpha);
        g_lines.pushMatrix();
        g_lines.translate(rl.getX1(), rl.getY1());
        g_lines.rotate(radians(rl.getAngle()));
        g_lines.line(x1, y1, x2, y2);      
        g_lines.popMatrix();
      }
    }        
  }
  g_lines.endDraw();
  
  // draw labels
  ArrayList<Country> countries = current_year.getCountries();
  g_labels.clear();
  g_labels.beginDraw();
  for (int i = 0; i < COUNTRY_LABEL_COUNT; i++) {  
    if (i < countries.size()) {
      Country c = countries.get(i);
      float w = c.getCountN() * (labelCircleRange[1]-labelCircleRange[0]) + labelCircleRange[0];
      
      // circle
      g_labels.ellipseMode(CENTER);
      g_labels.noFill();
      g_labels.stroke(labelCircleC);
      g_labels.strokeWeight(labelCircleWeight);
      g_labels.ellipse(c.getX(), c.getY(), w, w);
      
      // text
      //g_labels.fill(textC);
      //g_labels.noStroke();
      //g_labels.text(c.getCountryName(), c.getX() + 0.5*w, c.getY() + 0.5*w);
    }
  }
  g_labels.endDraw();
  
  // draw layers
  image(img_map, 0, 0, canvasW, canvasH);  
  for (Year y : previousYearsLines) {
    float alpha = y.getAlpha(elapsedMs);
    if (alpha > 0) {
      tint(255, alpha);
      image(y.getGraphics(), 0, 0, canvasW, canvasH);
    }  
  }
  tint(255, 255);
  image(g_lines, 0, 0, canvasW, canvasH);
  //image(g_labels, 0, 0, canvasW, canvasH);
  image(g_key, 0, 0, canvasW, canvasH);
  
  // increment time
  elapsedMs += frameMs;
  
  // save image
  if(captureFrames) {
    saveFrame(outputFrameFile);
  }
  
  // check if we should exit
  if (elapsedMs > stopMs) {
    saveFrame("output/frame.png");
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
  ArrayList<Country> countries;
  float start_ms, stop_ms;
  int year;
  String population, count, count_per;
  PGraphics g_lines;
  
  Year(JSONObject _year) {    
    year = _year.getInt("y");
    start_ms = _year.getFloat("ms0");
    stop_ms = _year.getFloat("ms1");
    population = _year.getString("p");
    count = _year.getString("rc");
    count_per = _year.getString("cp");
    refugees = new ArrayList<Refugee>();
    countries = new ArrayList<Country>();
    
    JSONArray countriesJSON = _year.getJSONArray("c");
    for (int i = 0; i < countriesJSON.size(); i++) {  
      JSONObject country = countriesJSON.getJSONObject(i);
      countries.add(new Country(country));
    }
    
    JSONArray refugeesJSON = _year.getJSONArray("r");
    for (int i = 0; i < refugeesJSON.size(); i++) {  
      JSONObject refugee = refugeesJSON.getJSONObject(i);
      refugees.add(new Refugee(refugee, _year));
    }
    
    // Line layer  
    g_lines = createGraphics(canvasW, canvasH);
    g_lines.noFill();
    g_lines.smooth();
  }
  
  float getAlpha(float ms){
    float alpha = 0;
    
    if ((ms-stop_ms) < YEAR_FADE_TIME) {
      alpha = 255.0 * (1.0 - (ms-stop_ms) / YEAR_FADE_TIME);
    }
    
    return alpha;
  }
  
  String getCount(){
    return count;
  }
  
  String getCountPer(){
    return count_per;
  }
  
  ArrayList<Country> getCountries(){
    return countries;
  }
  
  PGraphics getGraphics(){
    return g_lines;
  }
  
  String getPopulation(){
    return population;
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

class Country
{
  String name;
  float count_n, x, y;
  int count;
  
  Country(JSONObject _country) {
    name = _country.getString("n");
    count = _country.getInt("c");
    count_n = _country.getFloat("cn");
    x = _country.getFloat("x");
    y = _country.getFloat("y");
  }
  
  String getCount() {
    return nfc(count); 
  }
  
  float getCountN() {
    return count_n;
  }
  
  String getCountryName() {
    return name;
  }
  
  float getX() {
    return x; 
  }
  
  float getY() {
    return y; 
  }
  
}

class RefugeeLine
{
  float start_ms, stop_ms, x, y, x1, y1, x2, y2, distance, distance_n, angle, count_n, distance_step, wavelength;
  
  RefugeeLine(JSONObject _refugee, JSONObject _year, int hindex) {
    start_ms = _refugee.getFloat("ms0");
    stop_ms = _refugee.getFloat("ms1");
    x1 = _refugee.getFloat("x1");
    y1 = _refugee.getFloat("y1");
    x2 = _refugee.getFloat("x2");
    y2 = _refugee.getFloat("y2");
    distance = _refugee.getFloat("d");
    distance_n = _refugee.getFloat("dn");
    angle = angleBetweenPoints(x1, y1, x2, y2);
    count_n = _refugee.getFloat("cn");  
    
    // add randomness
    float year_start_ms = _year.getFloat("ms0");
    float year_stop_ms = _year.getFloat("ms1");
    float rand = halton(hindex, 3);
    stop_ms = min(stop_ms + rand * (year_stop_ms-year_start_ms) * 0.4, year_stop_ms);
    wavelength = distance_n * (wavelengthRange[1]-wavelengthRange[0]) + wavelengthRange[0];
    wavelength = wavelength + rand * wavelengthVariance;
    
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
  
  Refugee(JSONObject _refugee, JSONObject _year) {    
    // add lines
    lines = new ArrayList<RefugeeLine>();
    int hindex = 0;
    float c =  _refugee.getFloat("c");
    while(c > 0) {
      lines.add(new RefugeeLine(_refugee, _year, hindex));
      c = c - REFUGEE_UNIT;
      hindex++;
    }
  }
  
  ArrayList<RefugeeLine> getLines() {
    return lines;
  }
  
}

