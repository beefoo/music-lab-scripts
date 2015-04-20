/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Air Play"
 */
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// data  
JSONObject dataJSON;
JSONArray pairsJSON;
ArrayList<Pair> pairs;
int minPercent;
int maxPercent;
int minYear;
int maxYear;
int years;
int races = 4;

// resolution
int canvasW = 1280;
int canvasH = 720;
float cx = 0.5 * canvasW;
float cy = 0.5 * canvasH;

// color palette
color bgColor = #3f3b3b;
color textColor = #f8f3f3;

// text
int fontSizeBig = 72;
PFont fontBig = createFont("OpenSans-Extrabold", fontSizeBig, true);
int fontSize = 48;
PFont font = createFont("OpenSans-Semibold", fontSize, true);
int fontSizeSmall = 30;
PFont fontSmall = createFont("OpenSans-Semibold", fontSizeSmall, true);

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;

// figures
PShape fShape;
PShape mShape;
float fShapeW;
float mShapeW;
float shapeH = 500;
float shapePadding = 10;
float shapeOffset = 0.7;
float transitionMs = 800;

// arrows
PShape arrow_l;
PShape arrow_r;
float arrowW = 160;
float arrowH = 160;
float arrowOffset = 200;
float textPadding = 12;

// year

// turntable
float ttRadius = 0.5 * canvasW;
float ttXOffset = ttRadius + 130;
float ttY = 0.5 * canvasH;
color ttColor = #262222;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);  
  frameRate(fps);
  smooth();
  noStroke();
  noFill();
  
  // load man/woman shape
  fShape = loadShape("woman.svg");
  mShape = loadShape("man.svg");
  fShapeW = 1.0 * fShape.width / fShape.height * shapeH;
  mShapeW = 1.0 * mShape.width / mShape.height * shapeH;
  fShape.disableStyle();
  mShape.disableStyle();
  
  // load arrow shape
  arrow_r = loadShape("arrow_right.svg");
  arrow_l = loadShape("arrow_left.svg");
  arrow_r.disableStyle();
  arrow_l.disableStyle();

  // load data
  dataJSON = loadJSONObject("pairs.json");
  minPercent = dataJSON.getInt("min_percent");
  maxPercent = dataJSON.getInt("max_percent");
  minYear = dataJSON.getInt("min_year");
  maxYear = dataJSON.getInt("max_year");
  years = maxYear - minYear + 1;
  pairsJSON = dataJSON.getJSONArray("pairs");
  pairs = new ArrayList<Pair>();
  for (int i = 0; i < pairsJSON.size(); i++) {  
    JSONObject pair = pairsJSON.getJSONObject(i);
    pairs.add(new Pair(pair));
  }
  stopMs = pairs.get(pairs.size()-1).getStopMs();
  
  // noLoop();
}

void draw(){

  background(bgColor);
  
  // draw turntable
  fill(ttColor);
  ellipseMode(CENTER);
  ellipse(cx - ttXOffset, ttY, ttRadius*2, ttRadius*2);
  ellipse(cx + ttXOffset, ttY, ttRadius*2, ttRadius*2);
  
  int phase = races * years;
  
  // draw pairs
  for (int i = 0; i < pairsJSON.size(); i++) {
    Pair pair = pairs.get(i);
    boolean isCurrent = false;
    
    // pair is current
    if (pair.isCurrent(elapsedMs)) {
      isCurrent = true;
      
      // year
      fill(textColor, 50);
      textFont(fontBig);
      textAlign(CENTER, CENTER);
      text(pair.getYear(), cx, cy - 12);
      
      // female arrow
      shapeMode(CENTER);
      fill(pair.getFColor(minPercent, maxPercent));
      shape(arrow_r, cx - arrowW*0.5, cy - arrowOffset, arrowW, arrowH);
      
      // male arrow
      shapeMode(CENTER);
      fill(pair.getMColor(minPercent, maxPercent));
      shape(arrow_l, cx - arrowW*0.5, cy + arrowOffset - arrowH*0.25, arrowW, arrowH);
      
      // female percent      
      fill(textColor);
      textFont(font);
      textAlign(CENTER, TOP);
      text(pair.getFPercent() + "%", cx - 0.5*arrowW - textPadding, cy - arrowOffset - textPadding, arrowW, arrowH);
      
      // male percent
      text(pair.getMPercent() + "%", cx - 0.5*arrowW + textPadding, cy + arrowOffset - textPadding - arrowH*0.25, arrowW, arrowH);
    }
    
    // pair is visible
    if (pair.isInview(elapsedMs, transitionMs)) {     
      
      // draw female
      shapeMode(CENTER);
      pushMatrix();
        
        // female pivot point, rotate
        translate(cx - ttXOffset, ttY);
        if (!isCurrent && i%phase == 0 || isCurrent && i%phase == phase-1) {
          rotate(radians(pair.getRotation(elapsedMs, transitionMs, 90, -90, 0)));
        }
      
        // female figure
        fill(pair.getFRaceColor());
        shape(fShape, shapeOffset * ttRadius, 0, fShapeW, shapeH);
        
        // female race
        fill(textColor);
        textAlign(CENTER, TOP);
        textFont(font);
        text(pair.getFRace(), shapeOffset * ttRadius, 0.5 * shapeH + shapePadding);        
      popMatrix();
      
      // draw male
      shapeMode(CENTER);
      pushMatrix();
      
        // male pivot point, rotate
        translate(cx + ttXOffset, ttY);
        if (isCurrent && pair.getYear() == maxYear || !isCurrent && pair.getYear() == minYear) {
          rotate(radians(pair.getRotation(elapsedMs, transitionMs, 90, -90, 0)));
        }
      
        // male figure
        fill(pair.getMRaceColor());
        shape(mShape, -shapeOffset * ttRadius, 0, mShapeW, shapeH);
        
        // male race
        fill(textColor);
        text(pair.getMRace(), -shapeOffset * ttRadius, 0.5 * shapeH + shapePadding);
      popMatrix();  
    }
  }
  
  // increment time
  elapsedMs += (1.0/fps) * 1000;
  // elapsedMs += 100;
  
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
  exit();
}

class Pair
{
  String f_race, m_race;
  int f_percent, m_percent, year, start_ms, stop_ms;

  Pair(JSONObject _pair) {
    f_race = _pair.getString("f_race");
    m_race = _pair.getString("m_race");
    f_percent = _pair.getInt("f_percent");
    m_percent = _pair.getInt("m_percent");
    year = _pair.getInt("year");
    start_ms = _pair.getInt("start_ms");
    stop_ms = _pair.getInt("stop_ms");
  }
  
  color getColor(int percent, int min_percent, int max_percent){
    color green = #63d138;
    color yellow = #e59c00;
    color red = #e03333;
    float amt = 0;
    color c;
    
    if (percent >= 0) {
      amt = 1.0 * percent / max_percent;
      c = lerpColor(yellow, green, amt);
      
    } else {
      amt = 1.0 * percent / min_percent;
      c = lerpColor(yellow, red, amt);
    }
        
    return c;
  }
  
  color getFColor(int min_percent, int max_percent){
    return getColor(f_percent, min_percent, max_percent);
  }
  
  color getMColor(int min_percent, int max_percent){
    return getColor(m_percent, min_percent, max_percent);
  }
  
  float getRotation(float ms, float transition_ms, float from_angle, float to_angle, float via_angle) {
    float ts = transition_ms;
    float angle = 0, percent_transition = 0;
    
    if (ms < start_ms) {
      percent_transition = (ts - (start_ms - ms)) / ts;
      angle = percent_transition * (via_angle-from_angle) + from_angle;
      
    } else if (ms > stop_ms - ts) {
      percent_transition = (ts - (stop_ms - ms)) / ts;
      angle = percent_transition * (to_angle-via_angle) + via_angle;
    }
    
    return angle;
  }
  
  color getRaceColor(String race){
    color c = #bcecf2;    
    if (race.equals("Black")) c = #d2f2bc;
    else if (race.equals("Latino") || race.equals("Latina")) c = #ffe047;
    else if (race.equals("Asian"))  c = #f785a3;
    return c;
  }
  
  color getFRaceColor(){
    return getRaceColor(f_race);
  }
  
  color getMRaceColor(){
    return getRaceColor(m_race);
  }
  
  boolean isCurrent(float ms) {
    return (ms >= start_ms && ms < stop_ms);
  }
  
  boolean isInview(float ms, float transition_ms) {
    return (ms >= (start_ms-transition_ms) && ms < stop_ms);
  }

  String getFRace(){ return f_race; }
  String getMRace(){ return m_race; }
  int getFPercent(){ return f_percent; }
  int getMPercent(){ return m_percent; }
  int getYear(){ return year; }
  int getStartMs(){ return start_ms; }
  int getStopMs(){ return stop_ms; }

}
