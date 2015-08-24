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
ArrayList<Year> years;
JSONArray years_json_array;
String years_file = "../visualization/data/changes.json";

// images and graphics
PImage img_bg;
String img_bg_file = "../visualization/data/map_layer_bg.png";

// time
float startMs = 0;
float stopMs = 6000;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();

  // load the change data
  years = new ArrayList<Year>();
  years_json_array = loadJSONArray(years_file);
  float yearMs = stopMs / years_json_array.size();
  for (int i = 0; i < years_json_array.size(); i++) {
    JSONObject year_json = years_json_array.getJSONObject(i);
    years.add(new Year(year_json, i, yearMs));
  }

  // draw bg image
  img_bg = loadImage(img_bg_file);
  image(img_bg, 0, 0, canvasW, canvasH);

  // noLoop();
}

void draw(){

  // get current year
  int current_year_i = years.size()-1;
  Year current_year = years.get(current_year_i);
  for (int i = 0; i < years.size(); i++) {
    Year y = years.get(i);
    if (y.isActive(elapsedMs)) {
      current_year = y;
      current_year_i = i;
      break;
    }
  }

  // base image
  PImage img_base = loadImage(current_year.getImageStart());
  image(img_base, 0, 0, canvasW, canvasH);

  // update pixels in overlay
  ArrayList<Change> changes = current_year.getChanges();
  for(int i=0; i<changes.size(); i++) {
    Change change = changes.get(i);
    if (change.isActive(elapsedMs)) {
      float p = change.getProgress(elapsedMs);
      color c = lerpColor(change.getC1(), change.getC2(), p);
      fill(c);
      rect(change.getX(), change.getY(), 1, 1);
    }
  }

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

class Year
{
  int start_year, end_year;
  float lx, ly, lw, lh;
  float start_ms, end_ms;
  String start_img, end_img;
  ArrayList<Change> changes;

  Year(JSONObject _year, int _i, float _ms_per_year) {
    start_year = _year.getInt("year_start");
    end_year = _year.getInt("year_end");
    start_img = _year.getString("img_start");
    end_img = _year.getString("img_end");
    start_ms = _ms_per_year * _i;
    end_ms = start_ms + _ms_per_year;
    changes = new ArrayList<Change>();
    lx = 0;
    ly = 0;
    lw = 0;
    lh = 0;

    PGraphics pg1, pg2;
    PImage img1, img2;
    color[] colors1, colors2;

    pg1 = createGraphics(canvasW, canvasH);
    pg2 = createGraphics(canvasW, canvasH);
    img1 = loadImage(start_img);
    img2 = loadImage(end_img);

    pg1.image(img1, 0, 0);
    pg2.image(img2, 0, 0);
    pg1.loadPixels();
    pg2.loadPixels();
    colors1 = pg1.pixels;
    colors2 = pg2.pixels;

    JSONArray changes_json_array = _year.getJSONArray("changes");
    int change_count = changes_json_array.size();
    float change_duration = _ms_per_year / 3.0;
    float ms_per_change = (_ms_per_year-change_duration) / change_count;
    float change_ms = start_ms;
    for (int i = 0; i < change_count; i++) {
      JSONArray change_json = changes_json_array.getJSONArray(i);
      int x = change_json.getInt(0);
      int y = change_json.getInt(1);
      change_ms = min(change_ms, end_ms-change_duration);
      changes.add(new Change(x, y, colors1[x+y*canvasW], colors2[x+y*canvasW], change_ms, change_ms + change_duration));
      change_ms += ms_per_change;
    }
  }

  ArrayList<Change> getChanges(){
    return changes;
  }

  String getImageEnd() {
    return end_img;
  }

  String getImageStart() {
    return start_img;
  }

  float[] getLegend(){
    float[] l = {lx, ly, lw, lh};
    return l;
  }

  int getYearEnd() {
    return end_year;
  }

  int getYearStart() {
    return start_year;
  }

  boolean isActive(float ms) {
    return ms >= start_ms && ms < end_ms;
  }

}

class Change
{
  int x, y;
  color c1, c2;
  float start_ms, end_ms;

  Change(int _x, int _y, color _c1, color _c2, float _start_ms, float _end_ms) {
    x = _x;
    y = _y;
    
    c1 = _c1;
    c2 = _c2;

    start_ms = _start_ms;
    end_ms = _end_ms;
  }

  color getC1() {
    return c1;
  }

  color getC2() {
    return c2;
  }

  float getProgress(float ms){
    float p = (ms - start_ms) / (end_ms - start_ms);
    p = min(p, 1.0);
    p = max(p, 0.0);
    return p;
  }

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

  boolean isActive(float ms) {
    return ms >= start_ms;
  }
}
