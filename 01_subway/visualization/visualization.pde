/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Two Trains" (https://datadrivendj.com/tracks/subway)
 */

// output
int fps = 30;
String outputFrameFile = "output/frames-#####.png";
boolean captureFrames = false;
float elapsed_ms = 0;

// data
JSONArray stationsJSON;
ArrayList<Station> stations = new ArrayList<Station>();

// resolution
int canvasW = 1280;
int canvasH = 720;
float centerX = 0.5 * canvasW;
float centerY = 0.5 * canvasH;

// color palette
color bgColor = #232121;
color textColor = #f8f3f3;
color secondaryTextColor = #a49595;
color highlightColor = #d12929;

// components
float circle_diameter = 100;
float circle_y = 320;
float line_height = 18;

// text
float boroughY = 200;
float stationY = 420;
float stationWidth = 280;
float stationTextWidth = 500;
float stationHeight = canvasH - stationY;
float stationPadding = 200;
PFont font = createFont("OpenSans-Semibold", 36, true);
PFont fontLarge = createFont("OpenSans-Semibold", 72, true);

// calculations to make
float total_width = 0;
float padding_left = 0;
int total_ms = 0;
float pixels_per_ms = 0;
float padding_left_ms = 0;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  noStroke();
  frameRate(fps);
  textAlign(CENTER);
  
  // load data
  stationsJSON = loadJSONArray("stations.json");  
  for (int i = 0; i < stationsJSON.size(); i++) {    
    JSONObject stationJSON = stationsJSON.getJSONObject(i);
    Station station = new Station(centerY, stationJSON, i, stationsJSON.size());
    stations.add(station); 
    total_ms += station.getDuration();
    total_width += station.getWidth();
  }
  
  // pixels/time calculations
  padding_left = 0.5 * canvasW + 0.5 * stationTextWidth;
  pixels_per_ms = total_width / total_ms;  
  padding_left_ms = padding_left / pixels_per_ms;
  elapsed_ms = -1.0 * padding_left_ms;
  
  // initialize station components
  for (int i = 0; i < stations.size(); i++) {    
    stations.get(i).initComponents(); 
  }
  
  // noLoop();
}

void draw(){
  background(bgColor);
  
  for (int i = 0; i < stations.size(); i++) {    
    Station station = stations.get(i);
    if (station.isInFrame()) {
      station.drawComponents();
    }    
  }
  
  elapsed_ms += (1.0/fps) * 1000;
  
  if(captureFrames) {
    saveFrame(outputFrameFile);
  } 
}

void mousePressed() {
  exit();
}

class Station
{
  int duration, previous_duration, elapsed_duration, min_duration, station_index, station_count;
  float x, y, w, start_x, stop_x, start_ms, stop_ms;
  String name, borough;
  
  Station (float _y, JSONObject _station, int _station_index, int _station_count) {
    y = _y;
    name = _station.getString("name");
    borough = _station.getString("borough");
    duration = _station.getInt("duration");
    previous_duration = _station.getInt("previous_duration");
    elapsed_duration = _station.getInt("elapsed_duration");
    min_duration = _station.getInt("min_duration");
    station_index = _station_index;
    station_count = _station_count;
    w = float(duration / min_duration) * stationWidth;
  }
  
  void initComponents(){    
    // calculate start/stop x-coordinate
    start_x = 1.0 * canvasW + 0.5 * stationTextWidth;
    stop_x = -1.0 * w - stationPadding;
    
    float distance = abs(stop_x - start_x);
    float ms = distance / pixels_per_ms;
    
    // calculate start/stop times
    start_ms = elapsed_duration - padding_left_ms;
    stop_ms = start_ms + ms;
    
    // println(start_ms, stop_ms, start_x, stop_x);
    
    x = start_x;
  }
  
  void drawComponents() {    
    float percent_complete = (elapsed_ms - start_ms) / (stop_ms - start_ms);
    x = (stop_x - start_x) * percent_complete + start_x;
    
    // draw circle
    fill(highlightColor);
    ellipse(x, circle_y, circle_diameter, circle_diameter);
    
    // draw line
    if (station_index < station_count-1) {
      fill(secondaryTextColor);
      rect(x+circle_diameter/2, circle_y-line_height/2, w-circle_diameter+stationPadding, line_height);
    }    
    
    // draw station
    textFont(fontLarge, 48);
    fill(textColor);
    text(name, x-stationTextWidth/2, stationY, stationTextWidth, stationHeight);
    
    // draw borough 
    textFont(font, 36);
    fill(secondaryTextColor);
    text(borough, x, boroughY);
    
    // TODO: draw label helper
    // TODO: draw borough boundary
  }
  
  boolean isInFrame() {
    return (elapsed_ms >= start_ms && elapsed_ms <= stop_ms);
  }
  
  int getDuration() {
    return duration; 
  }
  
  float getWidth() {
    return w; 
  }
}
