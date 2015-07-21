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
ArrayList<TimeRange> ranges;
JSONArray ranges_json_array;
String ranges_file = "../data/land_loss.json";

// images and graphics
PGraphics pg_overlay;
PImage img_bg;
String img_bg_file = "bg_water.png";
PImage img_overlay;
String img_overlay_file = "overlay_land.png";
color[] img_overlay_colors;

// text
color textC = #423535;
int fontSize = 36;
PFont font = createFont("OpenSans-Semibold", fontSize, true);

// components
color lossColor= #db4e4e;
color landColor = #e0edc3;
color gainColor = #90a06a;

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;
float timeRangeMs = 8000;

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();

  // load the change data
  ranges = new ArrayList<TimeRange>();
  ranges_json_array = loadJSONArray(ranges_file);
  for (int i = 0; i < ranges_json_array.size(); i++) {
    JSONObject tr_json = ranges_json_array.getJSONObject(i);
    TimeRange tr = new TimeRange(tr_json, i, timeRangeMs);
    ranges.add(tr);
  }

  // load the images
  img_bg = loadImage(img_bg_file);
  img_overlay = loadImage(img_overlay_file);
  pg_overlay = createGraphics(canvasW, canvasH);

  stopMs = timeRangeMs * ranges.size();

  // noLoop();
}

void draw(){

  // draw bg image
  image(img_bg, 0, 0, canvasW, canvasH);

  // get current time range
  TimeRange current_tr = ranges.get(ranges.size()-1);
  int current_tr_i = 0;
  for (int i = 0; i < ranges.size(); i++) {
    TimeRange tr = ranges.get(i);
    if (tr.isActive(elapsedMs)) {
      current_tr = tr;
      current_tr_i = i;
      break;
    }
  }

  // update pixels in overlay
  ArrayList<Change> changes = current_tr.getChanges();
  img_overlay.loadPixels();
  for(Change c : changes) {
    int change = c.getChange();
    int pixel_i = c.getX() + c.getY() * canvasW;
    // color pc = img_overlay.pixels[pixel_i];
    if (change != 0) {
      color pc = current_tr.getColor(elapsedMs, c);
      img_overlay.pixels[pixel_i] = pc;
    }
  }
  img_overlay.updatePixels();
  image(img_overlay, 0, 0, canvasW, canvasH);

  textAlign(LEFT, BOTTOM);
  fill(textC);
  textFont(font);
  text(current_tr.getStart()+"-"+current_tr.getEnd(), 10, canvasH - 10);

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

class TimeRange implements Comparable
{
  int start, end;
  float start_ms, end_ms;
  ArrayList<Change> changes;

  TimeRange(JSONObject _tr, int _i, float _ms_per_tr) {
    start = _tr.getInt("year_start");
    end = _tr.getInt("year_end");
    start_ms = _ms_per_tr * _i;
    end_ms = start_ms + _ms_per_tr;
    changes = new ArrayList<Change>();
    JSONArray changes_json_array = _tr.getJSONArray("c");
    for (int i = 0; i < changes_json_array.size(); i++) {
      JSONObject change_json = changes_json_array.getJSONObject(i);
      Change c = new Change(change_json);
      changes.add(c);
    }
  }

  int compareTo(Object o) {
    TimeRange tr = (TimeRange) o;
    int s1 = getStart();
    int s2 = tr.getStart();
    return s1 == s2 ? 0 : (s1 > s2 ? 1 : -1);
  }

  ArrayList<Change> getChanges(){
    return changes;
  }

  float getAlpha(float ms) {
    float lerp = 1.0 * (ms-start_ms) / (end_ms-start_ms);
    return 100.0 * sin(lerp*PI);
  }

  color getColor(float ms, Change c) {
    float lerp = 1.0 * (ms-start_ms) / (end_ms-start_ms);
    color pc = landColor;
    float pa = 100;

    // loss
    if (c.getChange() < 0) {

      if (lerp < 0.5) {
        pc = lerpColor(landColor, lossColor, lerp*2.0);

      } else {
        pc = lossColor;
        pa = lerp(100, 0, (lerp-0.5)*2.0);
      }

    // gain
    } else {

      if (lerp < 0.5) {
        pc = gainColor;
        pa = lerp(0, 100, lerp*2.0);

      } else {
        pc = lerpColor(gainColor, landColor, (lerp-0.5)*2.0);
      }

    }

    return color(red(pc), green(pc), blue(pc), pa);
  }

  int getEnd() {
    return end;
  }

  int getStart() {
    return start;
  }

  boolean isActive(float ms) {
    return ms >= start_ms && ms < end_ms;
  }

}

class Change
{
  int x, y, change;

  Change(JSONObject _c) {
    x = _c.getInt("x");
    y = _c.getInt("y");
    change = _c.getInt("c");
  }

  int getChange() {
    return change;
  }

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

}
