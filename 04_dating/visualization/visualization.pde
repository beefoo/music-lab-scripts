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
JSONArray pairsJSON;
ArrayList<Pair> pairs;

// resolution
int canvasW = 1280;
int canvasH = 720;

// color palette
color bgColor = #262222;
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

// components
PShape fShape;
PShape mShape;
float fShapeW;
float mShapeW;
float shapeH = 500;
float shapePadding = 30;
PShape arrow_l;
PShape arrow_r;
float arrowW = 160;
float arrowH = 160;
float arrowOffset = 100;

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
  pairsJSON = loadJSONArray("pairs.json");
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
  
  // retrieve current pair
  Pair pair = pairs.get(0);
  for (int i = 0; i < pairsJSON.size(); i++) {  
    pair = pairs.get(i);
    if (pair.isCurrent(elapsedMs)) {
      break; 
    }
  }
  
  float cx = 0.5 * canvasW;
  float cy = 0.5 * canvasH;
  float cxf = 0.25 * canvasW;
  float cxm = 0.75 * canvasW;
  float offsetY = 0.5 * (canvasH - (shapeH + shapePadding + fontSize));
  
  // female figure
  fill(pair.getFRaceColor());
  shape(fShape, cxf - 0.5*fShapeW, offsetY, fShapeW, shapeH);
  
  // female race
  textAlign(CENTER, TOP);
  textFont(font);
  text(pair.getFRace(), cxf, offsetY + shapeH + shapePadding);
  
  // male figure
  fill(pair.getMRaceColor());
  shape(mShape, cxm - 0.5*mShapeW, offsetY, mShapeW, shapeH);
  
  // male race
  text(pair.getMRace(), cxm, offsetY + shapeH + shapePadding);
  
  // year
  fill(textColor, 50);
  textFont(fontBig);
  textAlign(CENTER, CENTER);
  text(pair.getYear(), cx, cy);
  
  // female arrow
  fill(pair.getFColor());
  shape(arrow_r, cx - arrowW, arrowOffset, arrowW, arrowH);
  
  // male arrow
  fill(pair.getMColor());
  shape(arrow_l, cx - arrowW, canvasH - arrowOffset - arrowH - 20, arrowW, arrowH);  
  
  // female percent
  float textPadding = 12;
  fill(textColor);
  textFont(font);
  textAlign(CENTER, CENTER);
  text(pair.getFPercent() + "%", cx - 0.5*arrowW - textPadding, arrowOffset + textPadding, arrowW, arrowH);
  
  // male percent
  text(pair.getMPercent() + "%", cx - 0.5*arrowW + textPadding, canvasH - arrowOffset - arrowH - 20 + textPadding, arrowW, arrowH);
  
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
  
  color getColor(int percent){
    color green = #63d138;
    color red = #e03333;
    int d = 30;    
    float amt = 1.0*(percent+d)/(2.0*d);
    color c = lerpColor(red, green, amt);    
    return c;
  }
  
  color getFColor(){
    return getColor(f_percent);
  }
  
  color getMColor(){
    return getColor(m_percent);
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

  String getFRace(){ return f_race; }
  String getMRace(){ return m_race; }
  int getFPercent(){ return f_percent; }
  int getMPercent(){ return m_percent; }
  int getYear(){ return year; }
  int getStartMs(){ return start_ms; }
  int getStopMs(){ return stop_ms; }

}
