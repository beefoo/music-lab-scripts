/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Air Play" (https://datadrivendj.com/tracks/smog)
 */
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// data
JSONObject pm25JSON;
float pm25Min = 0;
float pm25Max = 0;
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

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;

// define levels
ArrayList<Level> levels = new ArrayList<Level>();

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();
  textFont(font, fontSize);
  
  // init levels
  levels.add(new Level(#d6ffb2, 0, 35));
  levels.add(new Level(#aedb87, 36, 50));
  levels.add(new Level(#eeef8b, 51, 100));
  levels.add(new Level(#e5a757, 101, 150));
  levels.add(new Level(#e56e57, 151, 200));
  levels.add(new Level(#ce3939, 201, 300));
  levels.add(new Level(#934870, 301, 500));
  levels.add(new Level(#683867, 501, 9999));
  
  // load data
  pm25JSON = loadJSONObject("pm25_data.json");
  pm25Min = pm25JSON.getFloat("pm25_min");
  pm25Max = pm25JSON.getFloat("pm25_max");
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
  fill(bgColor, 100);
  rect(0, 0, canvasW, canvasH);
  
  // draw particles
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
    fill(level.getColor());
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
  }
  
  // draw value text
  /* fill(level.getColor());
  textAlign(LEFT, TOP);
  text(Integer.toString(reading.getValue()), componentMargin, canvasH - componentMargin - fontSize, 0.5 * canvasW - componentMargin, 2.0 * fontSize); */
  
  // draw data text
  fill(textColor);
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

float logBase(int x, int base) {
  return (log(x) / log(base));
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
  
  color getColor(){
    return myColor;
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
