/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = true;

// resolution
int canvasW = 1280;
int canvasH = 720;
float cx = 0.5 * canvasW;
float cy = 0.5 * canvasH;

// config
float REFUGEE_UNIT = 40000;
int COUNTRY_LABEL_COUNT = 10;
float YEAR_FADE_TIME = 1000;
int COUNTRY_COUNT_MIN = 400;
int MAX_EVENT_DISPLAY = 3;

// colors
color bgColor = #000000;
color refugeePathFrom = #ff3232; // red
color refugeePathTo = #afef9b; // green

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
float[] strokeWeightRange = {0.4, 2.0};
float[] strokeAlphaRange = {25, 255};
float[] wavelengthRange = {1, 100};
float wavelengthVariance = 20;

// labels
float[] labelCircleRange = {10, 200};
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
int fontSizeSmall = 20;
PFont fontSmall = createFont("OpenSans-Semibold", fontSizeSmall, true);
int fontSizeVSmall = 18;
PFont fontVSmall = createFont("OpenSans-Semibold", fontSizeVSmall, true);

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
  g_labels.textFont(fontSmall);
  
  // Key layer
  g_key = createGraphics(canvasW, canvasH);  
  g_key.noStroke();
  g_key.rectMode(CORNER);
  
  // Init drawing
  previous_year = years.get(0);
  stopMs = years.get(years.size()-1).getRefugeeStopMs();
  
  // noLoop();
}

void draw(){
  
  // select current year
  Year current_year = years.get(years.size()-1);
  int current_year_i = 0;
  for (int i = 0; i < years.size(); i++) {  
    Year y = years.get(i);
    if (y.isActive(elapsedMs)) {
      current_year = y;
      current_year_i = i;
      break;
    }
  }
  
  // check if this is a new year
  Boolean isNewYear = false;
  Boolean isFirst = (frameCount<=1);
  if (current_year.getYear() != previous_year.getYear()) {
    isNewYear = true;
    previous_year = current_year;
  } 
  
  // new year, draw year 
  if (isNewYear || isFirst) {
    if (!isFirst) {
      g_key.clear();
    }    
    g_key.beginDraw();
    // top left
    g_key.textAlign(LEFT, TOP); 
    g_key.fill(textC);
    g_key.textFont(fontLarge);
    g_key.text(current_year.getYear(), yearX, yearY);
    g_key.textFont(font);
    g_key.text(current_year.getPopulation(), yearX + 196, yearY + 45);
    g_key.text(current_year.getCount() + " (1 in " + current_year.getCountPer()+")", yearX + 196, yearY + 45 + 30);
    g_key.text(current_year.getCountThousand(), yearX + 344, yearY + 45 + 30*2);
    g_key.fill(textC2);    
    g_key.text("World Population: ", yearX, yearY + 45);
    g_key.text("World Refugees: ", yearX, yearY + 45 + 30);
    g_key.text("Countries with 1000+ refugees: ", yearX, yearY + 45 + 30*2);
    // bottom left
    g_key.textAlign(LEFT, BOTTOM);  
    g_key.text("Country of Origin", yearX + 35, canvasH - yearY - 30);
    g_key.text("Country of Asylum", yearX + 35, canvasH - yearY);
    g_key.fill(refugeePathFrom);
    g_key.rect(yearX, canvasH - yearY - 30 - 25, 20, 20);
    g_key.fill(refugeePathTo);
    g_key.rect(yearX, canvasH - yearY - 25, 20, 20);    
    // top right
    g_key.textAlign(RIGHT, TOP);
    g_key.fill(textC2);
    g_key.textFont(fontSmall);
    /* g_key.text("Notable Events", canvasW - yearX, yearY);
    ArrayList<Event> events = current_year.getEvents();
    g_key.fill(textC);
    g_key.textFont(fontVSmall);
    float eventYH = 30;
    float eventY = yearY + eventYH + 5;  
    for (int i = 0; i < events.size(); i++) {
      if (i >= MAX_EVENT_DISPLAY) {
        break;
      }
      Event e = events.get(i);
      g_key.text(e.getCountry() + ": " + e.getHeadline(), canvasW - yearX, eventY);
      eventY += eventYH;      
    } */
    g_key.endDraw();
  }
  
  // draw lines
  for (int i = 0; i < years.size(); i++) {  
    Year y = years.get(i);
    ArrayList<Refugee> refugees = y.getRefugees();
    PGraphics g_lines = y.getGraphics();
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
          // float weight = countn * (strokeWeightRange[1]-strokeWeightRange[0]) + strokeWeightRange[0];
          float weight = rl.getStrokeWeight(elapsedMs);
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
    if (y.getYear() >= current_year.getYear()) {
      break; 
    }
  }
  
  // draw labels
  ArrayList<Country> countries = current_year.getCountries();  
  g_labels.clear();
  g_labels.beginDraw();
  Year previousY = years.get(0);
  if (current_year_i > 0) {
    previousY = years.get(current_year_i-1);
  }
  
  for (int i = 0; i < countries.size(); i++) {
    Country c = countries.get(i);
    // ArrayList<Event> c_events = c.getEvents(events);
    /* if (i > COUNTRY_LABEL_COUNT) {
      break;
    } */
    if (c.getCount() < COUNTRY_COUNT_MIN) {
      continue; 
    }
    // circle
    /* float previousW = previousY.getCountryWidth(c.getCode());
    float w = c.getWidth(elapsedMs, previousW);    
    g_labels.ellipseMode(CENTER);
    g_labels.noFill();
    g_labels.stroke(labelCircleC, 100);
    g_labels.strokeWeight(labelCircleWeight);
    g_labels.ellipse(c.getX(), c.getY(), w, w); */
    
    // text
    /* int[] pos = c.getLabelPosition(elapsedMs, previousW);
    g_labels.fill(textC);
    g_labels.noStroke();
    g_labels.textAlign(pos[2], pos[3]);
    g_labels.text(c.getCountryName(), pos[0], pos[1]); */
  }
  g_labels.endDraw();
  
  // draw layers
  image(img_map, 0, 0, canvasW, canvasH);  
  for (Year y : years) {
    float alpha = y.getAlpha(elapsedMs);
    if (alpha > 0) {
      tint(255, alpha);
      image(y.getGraphics(), 0, 0, canvasW, canvasH);
    }
    if (y.getYear() >= current_year.getYear()) {
      break; 
    }
  }
  // image(g_labels, 0, 0, canvasW, canvasH);
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

float normalizeAngle(float angle) {
  angle = angle % 360;    
  if (angle <= 0) {
    angle += 360;
  }
  return angle;
}

int[] translatePoint(float x, float y, float angle, float distance){
  int[] newPoint = new int[2];
  float r = radians(angle);
  
  newPoint[0] = round(x + distance*cos(r));
  newPoint[1] = round(y + distance*sin(r));
  
  return newPoint;
}

class Year
{
  ArrayList<Refugee> refugees;
  ArrayList<Country> countries;
  ArrayList<Event> events;
  float start_ms, stop_ms, refugee_stop_ms;
  int year;
  String population, count, count_per, count_thousand;
  PGraphics g_lines;
  
  Year(JSONObject _year) {    
    year = _year.getInt("y");
    start_ms = _year.getFloat("ms0");
    stop_ms = _year.getFloat("ms1");
    refugee_stop_ms = _year.getFloat("rms1");
    population = _year.getString("p");
    count = _year.getString("rc");
    count_per = _year.getString("cp");
    count_thousand = _year.getString("ct");
    refugees = new ArrayList<Refugee>();
    countries = new ArrayList<Country>();
    events = new ArrayList<Event>();
    
    JSONArray countriesJSON = _year.getJSONArray("c");
    for (int i = 0; i < countriesJSON.size(); i++) {  
      JSONObject country = countriesJSON.getJSONObject(i);
      countries.add(new Country(country, _year));
    }
    
    JSONArray refugeesJSON = _year.getJSONArray("r");
    for (int i = 0; i < refugeesJSON.size(); i++) {  
      JSONObject refugee = refugeesJSON.getJSONObject(i);
      refugees.add(new Refugee(refugee, _year));
    }
    
    JSONArray eventsJSON = _year.getJSONArray("e");
    for (int i = 0; i < eventsJSON.size(); i++) {  
      JSONObject event = eventsJSON.getJSONObject(i);
      events.add(new Event(event));
    }
    
    // Line layer  
    g_lines = createGraphics(canvasW, canvasH);
    g_lines.noFill();
    g_lines.smooth();
  }
  
  float getAlpha(float ms){
    float alpha = 0;
    
    if ((ms-refugee_stop_ms) < YEAR_FADE_TIME) {
      alpha = 255.0 * (1.0 - (ms-refugee_stop_ms) / YEAR_FADE_TIME);
    }
    if (isActive(ms)) {
      alpha = 255.0; 
    }
    
    return alpha;
  }
  
  String getCount(){
    return count;
  }
  
  String getCountPer(){
    return count_per;
  }
  
  String getCountThousand(){
    return count_thousand;
  }
  
  ArrayList<Country> getCountries(){
    return countries;
  }
  
  float getCountryWidth(String code) {
    float w = 0;
    for(Country c : countries) {
      if (code.equals(c.getCode())) {
        w = c.getW();
      } 
    }
    return w;
  }
  
  ArrayList<Event> getEvents(){
    return events;
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
  
  float getRefugeeStopMs(){
    return refugee_stop_ms;
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
  String name, code;
  float count_n, x, y, w, start_ms, stop_ms;
  int count;
  
  Country(JSONObject _country, JSONObject _year) {
    name = _country.getString("n");
    code = _country.getString("cc");
    count = _country.getInt("c");
    count_n = _country.getFloat("cn");
    x = _country.getFloat("x");
    y = _country.getFloat("y");
    start_ms = _year.getFloat("ms0");
    stop_ms = _year.getFloat("ms1");
    w = count_n * (labelCircleRange[1]-labelCircleRange[0]) + labelCircleRange[0];
  }
  
  String getCode(){
    return code;
  }
  
  int getCount(){
    return count;
  }
  
  String getCountString() {
    return nfc(count); 
  }
  
  float getCountN() {
    return count_n;
  }
  
  String getCountryName() {
    return name;
  }
  
  int[] getLabelPosition(float ms, float w0){
    float _w = getWidth(ms, w0),
          angle = normalizeAngle(angleBetweenPoints(cx, cy, x, y));
    int[] pos = translatePoint(x, y, angle, _w * 0.5 + 50);    
    int[] pos2 = {CENTER, CENTER};
    pos2[0] = CENTER;
    if (angle > 315 || angle < 45) {
      pos2[0] = LEFT;
    } else if (angle > 135 && angle < 225) {
      pos2[0] = RIGHT;
    }
    if (angle > 225 && angle < 315) {
      pos2[1] = BOTTOM;
    } else if (angle > 45 && angle < 135){
      pos2[1] = TOP;
    }
    return concat(pos, pos2);
  }
  
  float getW(){
    return w;
  }
  
  float getWidth(float ms, float w0){
    float w1 = w,
          d = 0.5 * (stop_ms - start_ms);
    if (ms < (start_ms+d)) {
       float p = (ms-start_ms)/ d;
       w1 = (w1 - w0) * p + w0;
    }
    return w1;
  }
  
  float getX() {
    return x; 
  }
  
  float getY() {
    return y; 
  }
  
  ArrayList<Event> getEvents(ArrayList<Event> _events) {
    ArrayList<Event> events = new ArrayList<Event>();
    for(Event e : _events) {
      if (e.getCode().equals(code)) {
        events.add(e);
      }
    }
    return events;
  }
  
}

class Event
{
  String code, country, headline;
  
  Event(JSONObject _event) {
    code = _event.getString("cc");
    country = _event.getString("c");
    headline = _event.getString("h");
  }
  
  String getCode() {
    return code; 
  }
  
  String getCountry() {
    return country; 
  }
  
  String getHeadline() {
    return headline;
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
    // stop_ms = min(stop_ms + rand * (year_stop_ms-year_start_ms) * 0.4, year_stop_ms);
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
    return lerpColor(refugeePathFrom, refugeePathTo, lerp);
  }
  
  float getCountN() {
    return count_n;
  }
  
  float getLerp(float ms) {
    return (ms - start_ms) / (stop_ms - start_ms);
  }
  
  float getStrokeWeight(float ms) {
    float lerp = getLerp(ms);
    lerp = 1.0 - 1.0 * sin(lerp*PI);
    return (strokeWeightRange[1]-strokeWeightRange[0]) * lerp + strokeWeightRange[0]; 
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
      if (c > COUNTRY_COUNT_MIN) {
        lines.add(new RefugeeLine(_refugee, _year, hindex)); 
      }          
      c = c - REFUGEE_UNIT;
      hindex++;
    }
  }
  
  ArrayList<RefugeeLine> getLines() {
    return lines;
  }
  
}

