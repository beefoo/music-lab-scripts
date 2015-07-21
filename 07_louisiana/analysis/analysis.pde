/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */
 
import java.util.Collections;
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// resolution
int canvasW = 1280;
int canvasH = 720;

// data
String color_table_file = "land_loss.csv";
String color_output_file = "../data/land_loss.json";
Table color_table;
int color_count;
ArrayList<TimeRange> ranges;
JSONArray ranges_json_array;
int min_year, max_year;

// images and graphics
PGraphics pg;
PImage img;
String img_file = "land_loss.png";
color[] img_colors;

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;

void setup() {  
  // set the stage
  size(canvasW, canvasH);
  colorMode(HSB, 360, 100, 100, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();
  
  // load the change data
  color_table = loadTable(color_table_file, "header");
  color_count = color_table.getRowCount();
  ranges = new ArrayList<TimeRange>();
  for (TableRow row : color_table.rows()) {
    ChangeKey ck = new ChangeKey(row);
    boolean range_exists = false;
    for(int i=0; i<ranges.size(); i++) {
      TimeRange tr = ranges.get(i);
      if (tr.equalsChangeKey(ck)) {
        ranges.get(i).addChangeKey(ck);
        range_exists = true;
      }      
    }
    if (!range_exists) {
      ranges.add(new TimeRange(ck));
    }
  }
  Collections.sort(ranges);
  
  // load the image data
  img = loadImage(img_file);
  pg = createGraphics(canvasW, canvasH);
  pg.image(img, 0, 0);
  pg.loadPixels();
  img_colors = pg.pixels;
  
  // classify image data
  for (int y=0; y<canvasH; y++) {
    for (int x=0; x<canvasW; x++) {
      color c = img_colors[x+y*canvasW];
      float h = hue(c),
          s = saturation(c),
          b = brightness(c);
      float min_distance = 99999;
      int min_tr_i = 0;
      int min_ck_i = 0;
      for(int i=0; i<ranges.size(); i++) {
        TimeRange tr = ranges.get(i);
        ArrayList<ChangeKey> cks = tr.getChangeKeys();
        for(int j=0; j<cks.size(); j++) {
          ChangeKey ck = cks.get(j);
          float d = dist(h, s, b, ck.getHue(), ck.getSaturation(), ck.getBrightness());
          if (d < min_distance) {
            min_distance = d;
            min_tr_i = i;
            min_ck_i = j;
          }
        }
      }
      ChangeKey min_ck = ranges.get(min_tr_i).getChangeKeys().get(min_ck_i);
      ranges.get(min_tr_i).addChange(new Change(x, y, min_ck.getChange()));
    }        
  }
  
  // save data to json file
  ranges_json_array = new JSONArray();
  for(int i=0; i<ranges.size(); i++) {
    TimeRange tr = ranges.get(i);
    JSONObject tr_json = new JSONObject();
    tr_json.setInt("year_start", tr.getStart());
    tr_json.setInt("year_end", tr.getEnd());
    
    JSONArray c_json_array = new JSONArray();
    ArrayList<Change> changes = tr.getChanges();
    for(int j=0; j<changes.size(); j++) {
      Change c = changes.get(j);
      JSONObject c_json = new JSONObject();
      c_json.setInt("x", c.getX());
      c_json.setInt("y", c.getY());
      c_json.setInt("c", c.getChange());
      c_json_array.setJSONObject(j, c_json);
    }
    tr_json.setJSONArray("c", c_json_array);
    ranges_json_array.setJSONObject(i, tr_json);
  }
  saveJSONArray(ranges_json_array, color_output_file);
  print("Wrote data to file: "+color_output_file);
  
  noLoop();
}

void draw(){
  
}

void mousePressed() {
  saveFrame("output/frame.png");
  exit();
}

class TimeRange implements Comparable
{
  int start, end;
  ArrayList<ChangeKey> change_keys;
  ArrayList<Change> changes;
  
  TimeRange(ChangeKey ck) {
    change_keys = new ArrayList<ChangeKey>();
    changes = new ArrayList<Change>();
    
    start = ck.getYearStart();
    end = ck.getYearEnd();
    change_keys.add(ck);
  }
  
  void addChange(Change c) {
    changes.add(c);
  }
  
  void addChangeKey(ChangeKey ck) {
    change_keys.add(ck);
  }
  
  int compareTo(Object o) {
    TimeRange tr = (TimeRange) o;
    int s1 = getStart();
    int s2 = tr.getStart();
    return s1 == s2 ? 0 : (s1 > s2 ? 1 : -1);
  }
  
  boolean equalsChangeKey(ChangeKey ck) {
    return ck.getYearStart() == start && ck.getYearEnd() == end;
  }
  
  ArrayList<ChangeKey> getChangeKeys(){
    return change_keys;
  }
  
  ArrayList<Change> getChanges(){
    return changes;
  }
  
  int getEnd() {
    return end;
  }
  
  int getStart() {
    return start; 
  }
  
  boolean isActive(int year) {
    return year >= start && year < end;
  }
    
}

class ChangeKey
{
  float h, s, b;
  int year_start, year_end, change;
  
  ChangeKey(TableRow _ck) {    
    h = _ck.getFloat("h");
    s = _ck.getFloat("s");
    b = _ck.getFloat("b");
    year_start = _ck.getInt("year_start");
    year_end = _ck.getInt("year_end");
    change = _ck.getInt("change");
  }
  
  float getBrightness() {
    return b;
  }
  
  int getChange(){
    return change;
  }
  
  float getHue() {
    return h;
  }
  
  float getSaturation() {
    return s;
  }
  
  int getYearEnd() {
    return year_end;
  }
  
  int getYearStart() {
    return year_start; 
  }
    
}

class Change
{
  int x, y, change;
  
  Change(int _x, int _y, int _c) {    
    x = _x;
    y = _y;
    change = _c;
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


