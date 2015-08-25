/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */

// output
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = true;

// resolution
int canvasW = 600;
int canvasH = 338;

// data
ArrayList<Year> years;
JSONArray years_json_array;
String years_file = "../visualization/data/changes.json";

// text
color textC = #f4f3ef;
int fontSize = 32;
PFont font = createFont("OpenSans-Semibold", fontSize, true);

// images and graphics
PImage img_bg;
String img_bg_file = "../visualization/data/map_layer_bg.png";

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(1);
  smooth();
  noStroke();
  noFill();

  // load the change data
  years = new ArrayList<Year>();
  years_json_array = loadJSONArray(years_file);
  for (int i = 0; i < years_json_array.size(); i++) {
    JSONObject year_json = years_json_array.getJSONObject(i);
    years.add(new Year(year_json));
  }

  // draw bg image
  img_bg = loadImage(img_bg_file);
  image(img_bg, 0, 0, canvasW, canvasH);

  // noLoop();
}

void draw(){

  if (frameCount >= years.size()) {
    exit();
  }

  // get current year
  Year current_year = years.get(frameCount-1);

  // base image
  PImage img_base = loadImage(current_year.getImageStart());
  image(img_base, 0, 0, canvasW, canvasH);

  fill(textC);
  textFont(font);
  textAlign(LEFT, BOTTOM);
  text(current_year.getYearStart(), 20, canvasH - 20);

  // save image
  if(captureFrames) {
    saveFrame(outputFrameFile);
  }
}

void mousePressed() {
  saveFrame("output/frame.png");
  exit();
}

class Year
{
  int start_year, end_year;
  String start_img, end_img;

  Year(JSONObject _year) {
    start_year = _year.getInt("year_start");
    end_year = _year.getInt("year_end");
    start_img = _year.getString("img_start");
    end_img = _year.getString("img_end");
  }

  String getImageEnd() {
    return end_img;
  }

  String getImageStart() {
    return start_img;
  }

  int getYearEnd() {
    return end_year;
  }

  int getYearStart() {
    return start_year;
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
