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
float particleLifeUnit = 0.2;
float particleMoveUnit = 0.2;
float particleAngleVariance = 15;
float particleBBX = 260;
float particleBBY = particleW * 2;
float particleBBW = canvasW - particleBBX - particleW * 2;
float particleBBH = canvasH - particleW * 2;
float backlogMax = 0;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();

  // load data
  pm25JSON = loadJSONObject("pm25_data.json");
  pm25Min = pm25JSON.getInt("pm25_min");
  pm25Max = pm25JSON.getInt("pm25_max");
  pm25Count = pm25JSON.getInt("pm25_count");
  stopMs = pm25JSON.getFloat("total_ms");
  JSONArray pm25ValuesJSON = pm25JSON.getJSONArray("pm25_readings");
  
  // init levels
  levels.add(new Level("Good", #aedb87, 0, 50));
  levels.add(new Level("Moderate", #ffef66, 51, 100));
  levels.add(new Level("Unhealthy", #e5a757, 101, 200));
  levels.add(new Level("Very Unhealthy", #ce3939, 201, 300));
  levels.add(new Level("Hazardous", #934870, 301, 500));
  levels.add(new Level("Beyond Index", #665f5f, 501, pm25Max));
  
  // calculate level bounds
  float ly = particleBBY;
  for(int i = levels.size()-1; i>=0; i--) {
    Level level = levels.get(i);
    float lh = 1.0*(level.getMax()-roundToNearest(level.getMin(), 10))/pm25Max*particleBBH;
    level.setMinY(ly);
    level.setMaxY(ly+lh);
    ly += lh;
  }
  
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
  
  // draw levels
  textFont(fontSmall, fontSizeSmall);
  float lx = componentMargin;
  for(int i = levels.size()-1; i>=0; i--) {
    Level level = levels.get(i);
    // draw line
    if (i < levels.size()-1) {
      fill(textColor, 20);
      rect(lx, level.getMinY(), canvasW - lx*2, 1);
    }
    // draw label
    fill(level.getColor(), 100);
    textAlign(LEFT, CENTER);
    text(level.getLabel(), lx, level.getMinY()-(levels.size()-i), 0.5 * canvasW, level.getHeight());
  }
  
  // draw particles in backlog
  for(int i = particleBacklog.size()-1; i >= 0; i--) {
    Particle p = particleBacklog.get(i);
    float lifePercentage = (p.getLife() - particleLifeThreshold) / float(pm25Max - particleLifeThreshold) * 100;
    fill(textColor, lifePercentage);
    ellipse(p.getX(), p.getY(), particleW, particleW);
    p.take(particleLifeUnit);
    p.move(particleMoveUnit);  
    if (p.getLife() <= particleLifeThreshold) {
      particleBacklog.remove(i);
    }
  }  
  
  // draw current particle  
  int level_i = 0;
  Level level = levels.get(0);
  for(int i = 1; i <= reading.getValue(); i++) {
    
    if (i > level.getMax() && level_i < levels.size()-1) {
      level_i++;
      level = levels.get(level_i);
    }
    
    // calculate particle x and y
    float px = random(0,particleBBW) + particleBBX;
    float py = particleBBH - (float(i)/pm25Max*particleBBH) + particleBBY;
   
    // draw dot
    fill(level.getColor(), 100);
    ellipse(px, py, particleW, particleW);
    
    // add to particle backlog if over threshold
    if (i > particleLifeThreshold) {
      float pa = angleBetweenPoints(0.5 * canvasW, 0, px, py) + random(-particleAngleVariance, particleAngleVariance);
      particleBacklog.add(new Particle(px, py, float(i), pa));
    }
  }
  
  /* if (particleBacklog.size() > backlogMax) {
    backlogMax = particleBacklog.size();
    print(reading.getDate(), backlogMax);
  } */
  
  // draw date text
  fill(textColor);
  textFont(font, fontSize);  
  textAlign(RIGHT, TOP);
  text(reading.getDate(), 0.5 * canvasW, componentMargin, 0.5 * canvasW - componentMargin, 2.0 * fontSize);
  
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

float roundToNearest(float n, float nearest) {
  return 1.0 * round(n/nearest) * nearest;
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
  String label;
  float minY, maxY;

  Level(String _label, color _color, int _min, int _max) {
    label = _label;
    myColor = _color;
    min = _min;
    max = _max;
    minY = 0;
    maxY = 0;
  }
  
  boolean contains(int value) {
    return value >= min && value <= max;
  }
  
  color getColor(){
    return myColor;
  }
  
  int getMax(){
    return max;
  }
  
  float getMaxY(){
    return maxY;
  }
  
  int getMin(){
    return min;
  }
  
  float getMinY(){
    return minY;
  }
  
  float getHeight(){
    return maxY - minY;
  }
  
  String getLabel(){
    return label;
  }
  
  void setMaxY(float _y){
    maxY = _y;
  }
  
  void setMinY(float _y){
    minY = _y;
  }
}

class Particle
{
  float life, x, y, a;
  
  Particle(float _x, float _y, float _value, float _angle){
    x = _x;
    y = _y;
    life = _value;
    a = _angle;
  }
  
  float getLife(){
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
    if (p[1] < 0) {
      a = random(180+particleAngleVariance, 360-particleAngleVariance);
    } else if (p[0] < 0 || p[1] < 0 || p[0] > canvasW || p[1] > canvasH) {
      a = random(particleAngleVariance, 180-particleAngleVariance);
    } else {
      x = p[0];
      y = p[1];
    }
    
  }
  
  void take(float amount) {
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
