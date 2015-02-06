/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Rhapsody In Grey" (https://datadrivendj.com/tracks/brain)
 */

// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = true;

// data
JSONArray eegJSON;
JSONArray labelsJSON;

// resolution
int canvasW = 1280;
int canvasH = 720;
int X_AXIS = 0;
int Y_AXIS = 1;

// color palette
color bgColor = #443d3d;
color labelBgColor = #262222;
color textColor = #f8f3f3;
color lineColor = #fcf8e0;
color pointColor = #ffe030;
color highlightColor = #ef6e6e;

// components
int labelCount = 23;
float labelW = 100;
float labelH = 1.0 * canvasH / labelCount;
float markerX = 0.5 * (canvasW - labelW/2);
float markerW = 10;
float pointD = 10;
float lineWeight = 2;
float readingPadding = 60;

// text
int fontSize = 16;
float textIndent = 20;
PFont font = createFont("OpenSans-Semibold", fontSize, true);

// distance/time
float pixelsPerMs = 100.0 / 1000;
float msBefore = markerX / pixelsPerMs;
float msAfter = 1.0 * (canvasW - markerX - labelW) / pixelsPerMs;
float startMs = 0; // 120000
float stopMs = 280000; // 160000
float elapsedMs = startMs;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);  
  
  // load data
  eegJSON = loadJSONArray("eeg.json");
  labelsJSON = eegJSON.getJSONArray(0);
  eegJSON.remove(0);
  
  // draw label bg
  noStroke();
  fill(labelBgColor);
  rect(canvasW - labelW, 0, labelW, canvasH);
  
  // text formatting
  textAlign(LEFT, CENTER);
  textFont(font, fontSize);
  fill(textColor);
  
  // draw labels
  float y = 0;
  float x = canvasW - labelW + textIndent;
  for (int i=1; i < labelsJSON.size(); i++) {
    String label = labelsJSON.getString(i);
    text(label, x, y, labelW - textIndent, labelH);
    y += labelH;
  }
  
  // noLoop();
}

void draw(){  
  // calculate start/end on the screen
  float screenStartMs = elapsedMs - msBefore;
  float screenEndMs = elapsedMs + msAfter;
  
  // a list of reading lists
  ArrayList<ArrayList<Reading>> lines = new ArrayList<ArrayList<Reading>>(labelCount);
  FloatList points = new FloatList(labelCount);
  
  // initialize readings
  for (int i=0; i<labelCount; i++) {
    lines.add(new ArrayList<Reading>());
  }
  
  // loop through each reading
  for (int i=0; i<eegJSON.size(); i++) {
    JSONArray valuesJSON = eegJSON.getJSONArray(i);
    float ms = valuesJSON.getFloat(0);
    
    // time is valid, add values to readings
    if (ms >= screenStartMs && ms <= screenEndMs) {
      for(int j=1; j < valuesJSON.size(); j++) {
         lines.get(j-1).add(new Reading(ms, valuesJSON.getFloat(j)));
      }
    }
    
    // add point
    if (abs(round(ms) - round(elapsedMs)) < 10) {
      points = new FloatList(labelCount);
      for(int j=1; j < valuesJSON.size(); j++) {
         points.append(valuesJSON.getFloat(j));
      }
    }
    
    // 
    if (ms > screenEndMs) {
      break; 
    }
  }
  
  // draw bg
  noStroke();
  fill(bgColor);
  rect(0, 0, canvasW - labelW, canvasH);
  
  // draw lines
  strokeWeight(lineWeight);
  stroke(lineColor);
  noFill();
  
  // loop through each line
  for(int i=0; i<lines.size(); i++) {
  
    ArrayList<Reading> line = lines.get(i);
    beginShape();
    
    // loop through each point
    for(int j=0; j<line.size(); j++) {
      Reading r = line.get(j);
      float x = getVertexX(markerX, elapsedMs, r.getMs());
      float y = getVertexY(i, labelH, readingPadding, r.getValue());
      vertex(x, y);
    }
    
    endShape(); 
  }  
  
  // draw left overlay
  noStroke();
  fill(labelBgColor, 80);
  rect(0, 0, markerX, canvasH);

  // draw right gradient overlay
  alphaGradient(int(markerX), 0, float(canvasW) - markerX - labelW + 1, float(canvasH), bgColor, X_AXIS);
  
  // draw marker
  noStroke();
  fill(textColor, 30);
  rect(markerX-markerW/2, 0, markerW, canvasH);
  
  // draw points
  fill(pointColor);
  for(int i=0; i<points.size(); i++) {
    float y = getVertexY(i, labelH, readingPadding, points.get(i));
    ellipse(markerX, y, pointD, pointD);
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
  exit();
}

float getVertexX(float cx, float elapsed_ms, float ms){
  float delta_ms = ms - elapsed_ms;
  float delta_px = delta_ms * pixelsPerMs;
  
  return cx + delta_px;
}

float getVertexY(int reading_index, float height, float padding, float value) {
  float minY = height * reading_index - padding;
  float maxY = minY + height + padding*2;
  
  return value * (maxY - minY) + minY;  
}

void alphaGradient(int x, int y, float w, float h, color c, int axis) {
  noFill();
  strokeWeight(1);
  float a1 = 0;
  float a2 = 100;

  if (axis == Y_AXIS) {  // Top to bottom gradient
    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      float alpha = inter * (a2 - a1) + a1;
      stroke(c, alpha);
      line(x, i, x+w, i);
    }
  }  
  else if (axis == X_AXIS) {  // Left to right gradient
    for (int i = x; i <= x+w; i++) {
      float inter = map(i, x, x+w, 0, 1);
      float alpha = inter * (a2 - a1) + a1;
      stroke(c, alpha);
      line(i, y, i, y+h);
    }
  }
}

class Reading
{
  float ms, value;
  
  Reading (float _ms, float _value) {
    ms = _ms;
    value = _value;
  }
  
  float getMs(){
    return ms;
  }
  
  float getValue(){
    return value;
  }
  
}

