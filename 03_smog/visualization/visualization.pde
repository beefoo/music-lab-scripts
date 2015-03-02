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
JSONObject pm25JSON;
int pm25Min = 0;
int pm25Max = 0;
int pm25Count = 0;
ArrayList<Reading> pm25Readings;

// resolution
int canvasW = 1280;
int canvasH = 720;

// color palette
color bgColor = #262222;
color textColor = #f8f3f3;

// components
float componentMargin = 30;
float particleW = 12;

// text
int fontSize = 48;
PFont font = createFont("OpenSans-Semibold", fontSize, true);
int fontSizeSmall = 30;
PFont fontSmall = createFont("OpenSans-Semibold", fontSizeSmall, true);

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;

// define levels
ArrayList<Level> levels = new ArrayList<Level>();

// init particles
ArrayList<Particle> particleBacklog = new ArrayList<Particle>();
int particleLifeThreshold = 50;
int particleLifeUnit = 1;
float particleMoveUnit = 1;
float particleAngleVariance = 15;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();
  
  // init levels
  levels.add(new Level(#aedb87, 0, 35));
  levels.add(new Level(#d6ffb2, 36, 50));
  levels.add(new Level(#ffef66, 51, 100));
  levels.add(new Level(#e5a757, 101, 150));
  levels.add(new Level(#e56e57, 151, 200));
  levels.add(new Level(#ce3939, 201, 300));
  levels.add(new Level(#934870, 301, 500));
  levels.add(new Level(#683867, 501, 9999));
  
  // load data
  pm25JSON = loadJSONObject("pm25_data.json");
  pm25Min = pm25JSON.getInt("pm25_min");
  pm25Max = pm25JSON.getInt("pm25_max");
  pm25Count = pm25JSON.getInt("pm25_count");
  stopMs = pm25JSON.getFloat("total_ms");
  JSONArray pm25ValuesJSON = pm25JSON.getJSONArray("pm25_readings");
  
  // create a list of readings
  pm25Readings = new ArrayList<Reading>(pm25Count);
  float ms = 0;
  float ms_per_reading = stopMs / pm25Count;
  for (int i = 0; i < pm25Count; i++) {  
    JSONObject reading = pm25ValuesJSON.getJSONObject(i);
    pm25Readings.add(new Reading(ms, reading.getString("date"), reading.getInt("val")));
    ms += ms_per_reading;
  }
  
  // noLoop();
}

void draw(){
  
  // retrieve the current reading
  Reading reading = pm25Readings.get(pm25Count-1);
  Reading prevReading = pm25Readings.get(0);
  for (int i = 0; i < pm25Count; i++) {    
    Reading r = pm25Readings.get(i);
    if (r.getMs() > elapsedMs) {
      reading = prevReading;
      break; 
    }
    prevReading = r;
  }
  
  // draw bg
  background(bgColor); 
  
  // draw particles in backlog
  for(int i = particleBacklog.size()-1; i >= 0; i--) {
    Particle p = particleBacklog.get(i);
    float lifePercentage = float(p.getLife() - particleLifeThreshold) / float(pm25Max - particleLifeThreshold) * 100;
    fill(textColor, lifePercentage);
    ellipse(p.getX(), p.getY(), particleW, particleW);
    p.take(particleLifeUnit);
    p.move(particleMoveUnit);
    if (p.getLife() <= particleLifeThreshold) {
      particleBacklog.remove(i);
    }
  }  
  
  // draw current particles
  int level_i = 0;
  Level level = levels.get(0);
  int ring = 0;
  int ringCapacity = 1;
  float cx = 0.5 * canvasW, cy = 0.5 * canvasH, radius = 2, angleOffset = 0, angleStep = 180;
  for(int i = 1; i <= reading.getValue(); i++) {
    
    if (i > level.getMax() && level_i < levels.size()-1) {
      level_i++;
      level = levels.get(level_i);
    }
    
    float offset = i * 1000;
    //Calculate x and y as values between -1 and 1
    float x = sin((elapsedMs+offset) * 0.001);
    float y = cos((elapsedMs+offset) * 0.001);  
    
    // Multiply x and y by the ellipses width/height
    x *= radius * 2;
    y *= radius / 2;
    
    // center it
    x += cx;
    y += cy;   
   
    // draw dot
    fill(level.getColor(), 100);
    float[] p = rotatePoint(x, y, cx, cy, angleOffset);
    ellipse(p[0], p[1], particleW, particleW);       
    
    // next ring layer
    if (i >= ringCapacity) {
      ring++;
      ringCapacity += pow(2, ring);
      radius += 20;
      angleOffset = 0;
      angleStep = 0.5 * angleStep;
      
    } else {
      angleOffset += angleStep;
    }
    
    // add to particle backlog if over threshold
    if (i > particleLifeThreshold) {
      float a = angleBetweenPoints(cx, cy, p[0], p[1]) + random(-particleAngleVariance, particleAngleVariance);
      particleBacklog.add(new Particle(p[0], p[1], a, i));
    }
  }
  
  // draw bar
  level_i = 0;
  level = levels.get(0);
  Level pLevel = levels.get(0);
  float lh = 0.8 * fontSize;
  float lw = 1;
  float lx = componentMargin;
  float ly = canvasH - componentMargin - lh;  
  for(int i = 1; i <= reading.getValue(); i++) {
    float lp = float(i-level.getMin()) / float(level.getMax()-level.getMin());
    color lc = lerpColor(pLevel.getColor(), level.getColor(), lp);
    fill(lc);
    rect(lx, ly, lw, lh);
    if (i >= level.getMax()) {
      pLevel = level;
      level_i++;
      level = levels.get(level_i);
    }
    lx += lw;
  }
  
  // draw value text
  textFont(fontSmall, fontSizeSmall);
  textAlign(LEFT, CENTER);
  text(Integer.toString(reading.getValue()), lx + 10, ly, 200, lh);
  
  // draw label
  fill(textColor);
  text("Air Quality Index", componentMargin, ly - 2.0 * fontSizeSmall, 0.5 * canvasW, 2.0 * fontSizeSmall);
  
  // draw date text
  textFont(font, fontSize);  
  textAlign(RIGHT, TOP);
  text(reading.getDate(), 0.5 * canvasW, canvasH - componentMargin - fontSize, 0.5 * canvasW - componentMargin, 2.0 * fontSize);
  
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
  exit();
}

float angleBetweenPoints(float x1, float y1, float x2, float y2){
  float deltaX = x2 - x1,
        deltaY = y2 - y1;  
  return atan2(deltaY, deltaX) * 180 / PI;
}

float[] rotatePoint(float x, float y, float cx, float cy, float angle) {
  float s = sin(radians(angle));
  float c = cos(radians(angle));

  // translate point back to origin:
  x -= cx;
  y -= cy;

  // rotate point
  float xnew = x * c - y * s;
  float ynew = x * s + y * c;

  // translate point back:
  x = xnew + cx;
  y = ynew + cy;
  
  float[] p = {x, y};
  return p;
}

float[] translatePoint(float x, float y, float angle, float distance){
  float[] newPoint = new float[2];
  float r = radians(angle);
  
  newPoint[0] = x + distance*cos(r);
  newPoint[1] = y + distance*sin(r);
  
  return newPoint;
}

class Level
{
  color myColor;
  int min, max;

  Level(color _color, int _min, int _max) {
    myColor = _color;
    min = _min;
    max = _max;
  }
  
  boolean contains(int value) {
    return value >= min && value <= max;
  }
  
  int getMax(){
    return max;
  }
  
  int getMin(){
    return min;
  }
  
  color getColor(){
    return myColor;
  }
}

class Particle
{
  float x, y, a;
  int life;
  
  Particle(float _x, float _y, float _a, int _value){
    x = _x;
    y = _y;
    a = _a;
    life = _value;
  }
  
  int getLife() {
    return life;
  }
  
  float getX(){
    return x;
  }
  
  float getY(){
    return y;
  }
  
  void move(float distance) {
    float[] p = translatePoint(x, y, a, distance);
    x = p[0];
    y = p[1];
  }
  
  void take(int amount) {
    life -= amount;    
  }  
  
}

class Reading
{
  String date;
  float ms;
  int value;
  
  Reading (float _ms, String _date, int _value) {
    ms = _ms;
    date = _date;
    value = _value;
  }
  
  String getDate(){
    return date;
  }
  
  float getMs() {
    return ms; 
  }
  
  int getValue(){
    return value;
  }
  
}
