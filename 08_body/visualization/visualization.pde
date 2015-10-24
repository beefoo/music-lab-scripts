/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */

// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// resolution
int canvasW = 1280;
int canvasH = 720;

// data
ArrayList<Artist> artists;
JSONArray regions_json_array;
JSONArray artists_json_array;
String regions_file = "../data/regions.json";
String artists_file = "../data/analysis.json";

// images and graphics
PImage img;
PImage img_mask;
PImage img_gradient;
PImage img_active;
PGraphics pg_mask;
String img_file = "bodies.png";
String img_mask_file = "bodies_mask.png";
String img_active_file = "bodies_active.png";
String img_gradient_file = "gradient.png";

// text
color textC = #f4f3ef;
int fontSize = 42;
PFont font = createFont("OpenSans-Semibold", fontSize, true);

// components
int labelX = canvasW / 2;
int labelY = canvasH - 24;

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;
float artistMs = 2000;

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();

  // load the region data
  ArrayList<Region> regions = new ArrayList<Region>();
  regions_json_array = loadJSONArray(regions_file);
  for (int i = 0; i < regions_json_array.size(); i++) {
    JSONObject region_json = regions_json_array.getJSONObject(i);
    JSONArray region_regions = region_json.getJSONArray("regions");
    for (int j = 0; j < region_regions.size(); j++) {
      regions.add(new Region(region_json.getString("id"), region_regions.getJSONObject(j)));
    }
  }

  // load the artist data
  artists = new ArrayList<Artist>();
  artists_json_array = loadJSONArray(artists_file);
  for (int i = 0; i < artists_json_array.size(); i++) {
    JSONObject artist_json = artists_json_array.getJSONObject(i);
    artists.add(new Artist(artist_json, artistMs, regions));
  }

  // load images
  img_mask = loadImage(img_mask_file);
  img_gradient = loadImage(img_gradient_file);
  img_active = loadImage(img_active_file);

  // load mask
  pg_mask = createGraphics(canvasW, canvasH);
  pg_mask.background(255);
  pg_mask.loadPixels();

  // determine length
  stopMs = artistMs * artists.size();

  // noLoop();
}

void draw(){

  // get current artist
  Artist current_artist = artists.get(artists.size()-1);
  for (int i = 0; i < artists.size(); i++) {
    Artist a = artists.get(i);
    if (a.isActive(elapsedMs)) {
      current_artist = a;
      break;
    }
  }

  // create mask
  pg_mask.beginDraw();
  pg_mask.background(255);
  pg_mask.imageMode(CENTER);
  for (Region r : current_artist.getRegions()) {
    int x = round(r.getX() * canvasW);
    int y = round(r.getY() * canvasH);
    int w = round(r.getSW(elapsedMs) * canvasW);
    int h = round(r.getSH(elapsedMs) * canvasH);
    pg_mask.tint(255, round(r.getValue()*255));
    pg_mask.image(img_gradient, x, y, w, h);
  }
  pg_mask.endDraw();
  pg_mask.updatePixels();

  // draw images
  img = loadImage(img_file);
  img.mask(pg_mask.pixels);
  image(img_active, 0, 0, canvasW, canvasH);
  image(img, 0, 0, canvasW, canvasH);
  // image(img_mask, 0, 0, canvasW, canvasH);

  // label
  fill(textC);
  textAlign(CENTER, BOTTOM);
  textFont(font);
  text(current_artist.getName(), labelX, labelY);

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

class Artist
{
  int index;
  float start_ms, end_ms;
  String name;
  ArrayList<Region> regions;

  Artist(JSONObject _artist, float _ms_per_artist, ArrayList<Region> _regions) {
    index = _artist.getInt("index");
    name = _artist.getString("artist");
    start_ms = _ms_per_artist * index;
    end_ms = start_ms + _ms_per_artist;
    // look through artist's regions
    regions = new ArrayList<Region>();
    JSONArray regions_json_array = _artist.getJSONArray("regions");
    for (int i = 0; i < regions_json_array.size(); i++) {
      JSONObject region_json = regions_json_array.getJSONObject(i);
      String region_id = region_json.getString("name");
      float region_value = region_json.getFloat("value_n");
      // look through regions for matches
      for (Region r : _regions) {
        if (region_id.equals(r.getId())) {
          Region region = new Region(r);
          region.setValue(region_value);
          regions.add(region);
        }
      }
    }
  }

  int getIndex(){
    return index;
  }

  String getName(){
    return name;
  }

  ArrayList<Region> getRegions(){
    return regions;
  }

  boolean isActive(float ms) {
    return ms >= start_ms && ms < end_ms;
  }

}

class Region
{
  float minMultiplier = 1.0;
  float maxMultiplier = 1.5;
  float minWave = 1.0;
  float maxWave = 1.3;
  float pulse = 0.2;

  JSONObject regionJSON;
  float x, y, w0, h0, w, h, value;
  String id;

  Region(String _id, JSONObject _region) {
    id = _id;
    regionJSON = _region;
    w = regionJSON.getFloat("w") * 0.01;
    h = regionJSON.getFloat("h") * 0.01;
    w0 = w;
    h0 = h;
    x = regionJSON.getFloat("x") * 0.01 + w * 0.5;
    y = regionJSON.getFloat("y") * 0.01 + h * 0.5;
    value = 0;
  }

  // copy constructor
  Region(Region r){
    this(r.getId(), r.getRegionJSON());
  }

  String getId(){
    return id;
  }

  JSONObject getRegionJSON(){
    return regionJSON;
  }

  float getX(){
    return x;
  }

  float getY(){
    return y;
  }

  float getW(){
    return w;
  }

  float getH(){
    return h;
  }

  float getSW(float ms){
    float m = _getWaveMultiplier(ms*pulse%100*0.01);
    return w * m;
  }

  float getSH(float ms){
    float m = _getWaveMultiplier(ms*pulse%100*0.01);
    return h * m;
  }

  float getValue(){
    return value;
  }

  void setValue(float _value){
    value = _value;
    float m = lerp(minMultiplier, maxMultiplier, value);
    w = w0 * m;
    h = h0 * m;
  }

  float _getWaveMultiplier(float p){
    float rad = p * PI;
    float m = sin(rad);
    return lerp(minWave, maxWave, m);
  }

}
