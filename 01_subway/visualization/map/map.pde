/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Two Trains"
 */

// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;
float elapsed_ms = 0;

// data
JSONArray stationsJSON;
ArrayList<Station> stations = new ArrayList<Station>();

// image
PImage mapImage;
String mapImageFile = "img/new_york_city_map.png";

// resolution
int canvasW = 320;
int canvasH = 720;

// line style
color lineColor = #aaaaaa;
color highlightColor = #d12929;
int lineWeight = 4;
float lineBoxW = 251;
float lineBoxH = 554;
float lineOffsetX = 48;
float lineOffsetY = 42;
float dotDiameter = 4;

// calculations to make
int total_ms = 0;

void setup() {  
  // set the stage
  size(canvasW, canvasH);
  frameRate(fps);
  stroke(lineColor);
  strokeWeight(lineWeight);
  strokeJoin(ROUND);
  fill(highlightColor);
  
  // load image
  mapImage = loadImage(mapImageFile);
  image(mapImage, 0, 0);
  
  // load data  
  stationsJSON = loadJSONArray("stations.json");
  float min_lat = stationsJSON.getJSONObject(0).getFloat("lat");
  float max_lat = stationsJSON.getJSONObject(0).getFloat("lat");
  float min_lng = stationsJSON.getJSONObject(0).getFloat("lng");
  float max_lng = stationsJSON.getJSONObject(0).getFloat("lng");
  for (int i = 0; i < stationsJSON.size(); i++) {    
    JSONObject stationJSON = stationsJSON.getJSONObject(i);
    Station station = new Station(stationJSON, i, stationsJSON.size());
    stations.add(station); 
    total_ms += station.getDuration();
    if (station.getLat() < min_lat) min_lat = station.getLat();
    if (station.getLat() > max_lat) max_lat = station.getLat();
    if (station.getLng() < min_lng) min_lng = station.getLng();
    if (station.getLng() > max_lng) max_lng = station.getLng();
  }
  
  // initialize stations
  for (int i = 0; i < stations.size(); i++) {    
    Station station = stations.get(i);
    station.initXY(min_lat, max_lat, min_lng, max_lng);
    if (i > 0) {      
      stations.get(i-1).initLine(station);
    }  
  }
  
  noStroke();
  // noLoop();
}

void draw(){
  
  for (int i = 0; i < stations.size(); i++) {    
    Station station = stations.get(i);
    if (station.isInFrame()) {
      station.drawDot();
      break;
    }    
  }
  
  elapsed_ms += (1.0/fps) * 1000;
  
  if(captureFrames) {
    saveFrame(outputFrameFile);
  }
  
  if (elapsed_ms > total_ms) exit();
}

void mousePressed() {
  exit();
}

class Station
{
  int duration, elapsed_duration, station_index, station_count;
  float lat, lng, start_ms, stop_ms, x1, y1, x2, y2, direction, distance;
  
  Station (JSONObject _station, int _station_index, int _station_count) {
    duration = _station.getInt("duration");
    elapsed_duration = _station.getInt("elapsed_duration"); 
    lat = _station.getFloat("lat");
    lng = _station.getFloat("lng");
    station_index = _station_index;
    station_count = _station_count;
    x1 = -1;
    y1 = -1;
    x2 = -1;
    y2 = -1;
    distance = 0;
    
    start_ms = float(elapsed_duration);
    stop_ms = start_ms + duration;
  }
  
  void initXY(float min_lat, float max_lat, float min_lng, float max_lng) {
    x1 = (lng - min_lng) / (max_lng - min_lng) * lineBoxW + lineOffsetX;
    y1 = (1.0 - (lat - min_lat) / (max_lat - min_lat)) * lineBoxH + lineOffsetY;
  }
  
  void initLine(Station next_station){
    x2 = next_station.getX();
    y2 = next_station.getY();
    distance = dist(x1, y1, x2, y2);
    
    // calculate angle between points
    float deltaX = x2 - x1,
          deltaY = y2 - y1;  
    direction =  atan2(deltaY, deltaX) * 180.0 / PI;
    
    // draw the initial line
    line(x1, y1, x2, y2);
  }
  
  void drawDot() {
    if (distance <= 0) {
      ellipse(x1, y1, dotDiameter, dotDiameter);
      return;
    }
    
    float percent_complete = (elapsed_ms-start_ms)/(stop_ms-start_ms),
          distance_complete = distance * percent_complete;
    float dot[] = translatePoint(x1, y1, direction, distance_complete);
    
    ellipse(dot[0], dot[1], dotDiameter, dotDiameter);
  }
  
  boolean isInFrame() {
    return (elapsed_ms >= start_ms && elapsed_ms < stop_ms);
  }
  
  int getDuration() {
    return duration; 
  }
  
  float getLat() {
    return lat; 
  }
  
  float getLng() {
    return lng; 
  }
  
  float getX() {
    return x1; 
  }
  
  float getY() {
    return y1; 
  }
  
  float[] translatePoint(float x, float y, float angle, float distance){
    float[] newPoint = new float[2];
    float r = radians(angle);
    
    newPoint[0] = x + distance*cos(r);
    newPoint[1] = y + distance*sin(r);
    
    return newPoint;
  }
  
}
