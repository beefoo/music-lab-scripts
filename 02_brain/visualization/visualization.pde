/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Rhapsody In Grey" (https://datadrivendj.com/tracks/brain)
 */
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// data
JSONArray eegJSON;
JSONArray labelsJSON;
float maxIntervalMs = 10;
float minUV = 0;
float maxUV = 0;

// resolution
int canvasW = 1280;
int canvasH = 720;
int X_AXIS = 0;
int Y_AXIS = 1;

// color palette
color bgColor = #262222;
color labelBgColor = #262222;
color textColor = #f8f3f3;
color lineColor = #6b6961;
color lineStartColor = #ffffff;
color lineStopColor = #262222;
color pointColor = #ffe030;
color highlightColor = #ef6e6e;

// components
int labelCount = 18;
float labelW = 100;
float labelH = 1.0 * canvasH / labelCount;
float markerX = 0.5 * (canvasW - labelW/2);
float markerW = 10;
float pointD = 10;
float lineWeight = 1;
float lineStartWeight = 2;
float lineStopWeight = 0.05;
float readingPadding = 40;
boolean nakedMode = false;

// text
int fontSize = 18;
float textIndent = 20;
PFont font = createFont("OpenSans-Semibold", fontSize, true);

// distance/time
float pixelsPerMs = 90.0 / 1000;
float msBefore = markerX / pixelsPerMs;
float msAfter = 1.0 * (canvasW - markerX - labelW) / pixelsPerMs;
float startMs = 0;
float stopMs = 224000;
float elapsedMs = startMs;

// scale
int scaleXUnit = 1;
int scaleYUnit = 1000;
int scaleYUnitDisplay = 500;
float scaleW = 1.0 * scaleXUnit * 1000 * pixelsPerMs;
float scaleH = (labelH + readingPadding * 2) * scaleYUnitDisplay / scaleYUnit;
float scaleX = 20;
float scaleMarginY = 30;
float scaleY = 1.0 * canvasH - scaleH - scaleMarginY;
float scaleYRatio = 1;
float scaleLineWeight = 1;
int scaleFontSize = 16;
PFont scaleFont = createFont("OpenSans-Regular", scaleFontSize, true);

// status
float statusMargin = 10;
float statusW = 60;
float statusH = 60;
float statusX = statusW/2 + statusMargin;
float statusY = statusH/2 + statusMargin;
float statusTextW = statusW * 3 + statusMargin * 2;
float statusTextH = 300;
float statusTextX = statusMargin;
float statusTextY = statusY + statusH/2 + statusMargin;
int statusFontSize = 26;
int statusFontLeading = statusFontSize + 4;
PFont statusFont = createFont("OpenSans-Regular", statusFontSize, true);
JSONArray eventsJSON;
ArrayList<Event> events;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  
  // load status messages
  eventsJSON = loadJSONArray("eeg_events.json");
  events = new ArrayList<Event>(eventsJSON.size());
  for (int i = 0; i < eventsJSON.size(); i++) {  
    JSONObject event = eventsJSON.getJSONObject(i);
    events.add(new Event(event.getFloat("start"), event.getFloat("duration"), event.getString("text")));
  }
  
  // load data
  eegJSON = loadJSONArray("eeg.json");
  labelsJSON = eegJSON.getJSONArray(0);
  eegJSON.remove(0);
  JSONArray minJSON = eegJSON.getJSONArray(0);
  eegJSON.remove(0);
  JSONArray maxJSON = eegJSON.getJSONArray(0);
  eegJSON.remove(0);
  
  // calculate min/max
  float[] mins = new float[minJSON.size()-1];  
  for(int i=1; i<minJSON.size(); i++) {
    mins[i-1] = minJSON.getFloat(i);
  }
  minUV = min(mins);
  float[] maxs = new float[maxJSON.size()-1];
  for(int i=1; i<maxJSON.size(); i++) {
    maxs[i-1] = maxJSON.getFloat(i);
  }
  maxUV = max(maxs);
  
  // calculate scale ratio
  scaleYRatio = (maxUV - minUV) / scaleYUnit;
  
  if (nakedMode) {
    labelW = 0;
  }
  
  // draw label bg
  noStroke();
  fill(labelBgColor);
  rect(canvasW - labelW, 0, labelW, canvasH);
  
  // text formatting
  textAlign(LEFT, CENTER);
  textFont(font, fontSize);
  fill(textColor);
  
  // draw labels
  if (!nakedMode) {
    float y = 0;
    float x = canvasW - labelW + textIndent;
    for (int i=1; i < labelsJSON.size(); i++) {
      String label = labelsJSON.getString(i);
      text(label, x, y, labelW - textIndent, labelH);
      y += labelH;
    }
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
    if (abs(round(ms) - round(elapsedMs)) < maxIntervalMs) {
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
  noFill();
  
  // loop through each line
  for(int i=0; i<lines.size(); i++) {
  
    ArrayList<Reading> line = lines.get(i);
    
    // get initial point
    Reading r = line.get(0);
    float x1 = getVertexX(markerX, elapsedMs, r.getMs());
    float y1 = getVertexY(i, labelH, readingPadding, r.getValue());
    
    if (nakedMode) {
      lineColor = lineStartColor;
    }
    
    // loop through each point
    for(int j=1; j<line.size(); j++) {
      r = line.get(j);
      float x2 = getVertexX(markerX, elapsedMs, r.getMs());
      float y2 = getVertexY(i, labelH, readingPadding, r.getValue());
      
      // if it's after the marker, make a gradient from light to dark
      if (x1 >= markerX) {
        float inter = 1.0 * (x1-markerX) / (canvasW-labelW-markerX);
        float lw = inter * (lineStopWeight - lineStartWeight) + lineStartWeight;
        color lc = lerpColor(lineStartColor, lineStopColor, inter);
        strokeWeight(lw);
        stroke(lc);
        
      // if it's before the marker, reverse the gradient and keep a unified weight
      } else {
        float inter = 1.0 * x1 / markerX;
        float lw = inter * (lineStartWeight - lineStopWeight) + lineStopWeight;
        color lc = lerpColor(lineStopColor, lineColor, inter);
        if (nakedMode) {
          strokeWeight(lw);
        } else {
          strokeWeight(lineWeight);
        }        
        stroke(lc);
      }
      
      line(x1, y1, x2, y2);
      x1 = x2;
      y1 = y2;
    }
  }
  
  if (!nakedMode) {
  
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
    
    // draw scale
    textFont(scaleFont, scaleFontSize);
    strokeWeight(scaleLineWeight);
    stroke(textColor);
    fill(textColor);
    line(scaleX, scaleY+scaleH, scaleX+scaleW, scaleY+scaleH); // x-axis
    line(scaleX, scaleY, scaleX, scaleY+scaleH); // y-axis
    String xlabel = Integer.toString(scaleXUnit) + " s";
    String ylabel = Integer.toString(scaleYUnitDisplay) + " uV";
    textAlign(CENTER, CENTER);
    text(xlabel, scaleX, scaleY+scaleH-5, scaleW, scaleMarginY);
    textAlign(LEFT, CENTER);
    text(ylabel, scaleX + 5, scaleY + scaleH/2);
  
  }
  
  // draw status
  if (events.size() > 0 && !nakedMode) {
    
    // draw status arcs
    noStroke();

    float sx = statusX;
    Event currentEvent = events.get(0);
    boolean currentFound = false;
    for(int i=0; i<events.size(); i++) {
      Event e = events.get(i);
      float percent = e.getPercent(elapsedMs);
      // check for current event
      if (percent >= 0 && percent < 1 && !currentFound) {
        currentEvent = e;
        currentFound = true;
      }
      // empty circle
      fill(lineColor);
      ellipse(sx, statusY, statusW, statusH);
      // colored arc
      fill(pointColor);
      arc(sx, statusY, statusW, statusH, percent*2.0*PI - PI/2.0, 1.5*PI);
      // increment
      sx += (statusW + statusMargin);
    }    
    
    // draw status text
    textFont(statusFont, statusFontSize);
    textLeading(statusFontLeading);
    textAlign(CENTER, TOP);
    fill(textColor);
    text(currentEvent.getText(), statusTextX, statusTextY, statusTextW, statusTextH);
    
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

float getVertexY(int reading_index, float _height, float padding, float value) {
  float minY = _height * reading_index - padding;
  float maxY = minY + _height + padding*2;
  
  // update value to fit in the canvas's Y scale
  float yDiff = (scaleYRatio * scaleH) - scaleH;
  value = value * scaleYRatio;
  
  return value * (maxY - minY) + minY - yDiff/2;  
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

class Event
{
  float start, duration, end;
  String text;
  
  Event (float _start, float _duration, String _text) {
    start = _start;
    end = start + _duration;
    duration = _duration;
    text = _text;
  }
  
  float getPercent(float ms){
    float percent = (ms - start) / duration;
    
    percent = min(1.0, max(0.0, percent));
    
    return percent;
  }
  
  String getText(){
    return text;
  } 
}

