/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */

import java.util.Collections;

// jobs
boolean analyzeData = false;
boolean analyzeImages = true;

// resolution
int canvasW = 1280;
int canvasH = 720;

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(HSB, 360, 100, 100, 100);
  smooth();
  noStroke();
  noFill();

  if (analyzeData) {
    doAnalyzeData();
  }

  if (analyzeImages) {
    doAnalyzeImages();
  }

  noLoop();
}

void draw(){

}

void mousePressed() {
  exit();
}

void doAnalyzeData() {
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
  int count=0;
  for(TimeRange tr : ranges) {

    if (!tr.isChange()) {
      continue;
    }

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
    ranges_json_array.setJSONObject(count, tr_json);
    count++;
  }
  saveJSONArray(ranges_json_array, color_output_file);
  print("Wrote data to file: "+color_output_file);
}

void doAnalyzeImages() {
  String image_dir = "../visualization/data/";
  String color_table_file = "land_loss.csv";
  String changes_output_file = "../visualization/data/changes.json";
  Table color_table = loadTable(color_table_file, "header");
  ArrayList<ImageYear> imgYears = new ArrayList<ImageYear>();

  // read csv data
  for (TableRow row : color_table.rows()) {
    int year = row.getInt("year_start");
    int change = row.getInt("change");
    String img = image_dir + "map_layer_" + str(year) + ".png";

    if (change < 0) {
      imgYears.add(new ImageYear(year, img));
    }
  }

  // calculate changes year-over-year
  for (int i=1; i<imgYears.size(); i++) {
    ImageYear currentYear = imgYears.get(i);
    ImageYear previousYear = imgYears.get(i-1);

    currentYear.compareYear(previousYear);
  }

  // write data to file
  JSONArray changes_json_array = new JSONArray();
  for (int i=1; i<imgYears.size(); i++) {
    ImageYear currentYear = imgYears.get(i);
    ImageYear previousYear = imgYears.get(i-1);

    JSONObject c_json = new JSONObject();
    c_json.setInt("year_start", previousYear.getYear());
    c_json.setInt("year_end", currentYear.getYear());
    c_json.setString("img_start", previousYear.getImgFilename());
    c_json.setString("img_end", currentYear.getImgFilename());

    JSONArray ic_json_array = new JSONArray();
    ArrayList<ImageChange> changes = currentYear.getChanges();
    for(int j=0; j<changes.size(); j++) {
      ImageChange ic = changes.get(j);
      JSONArray ic_json_pair = new JSONArray();
      ic_json_pair.append(ic.getX());
      ic_json_pair.append(ic.getY());
      ic_json_array.append(ic_json_pair);
    }
    c_json.setJSONArray("changes", ic_json_array);
    changes_json_array.append(c_json);
  }
  saveJSONArray(changes_json_array, changes_output_file);
  print("Wrote data to file: "+changes_output_file);
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

  boolean isChange(){
    return change_keys.size() > 1 || change_keys.size() == 1 && change_keys.get(0).getChange() != 0;
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

class ImageYear
{
  int year;
  String img;
  ArrayList<ImageChange> changes;
  
  float distThreshold = 10.0;

  ImageYear(int _year, String _img) {
    year = _year;
    img = _img;
    changes = new ArrayList<ImageChange>();
  }

  void compareYear(ImageYear y2) {
    PGraphics pg1, pg2;
    PImage img1, img2;
    color[] colors1, colors2;

    changes = new ArrayList<ImageChange>();
    pg1 = createGraphics(canvasW, canvasH);
    pg2 = createGraphics(canvasW, canvasH);
    img1 = loadImage(img);
    img2 = loadImage(y2.getImg());

    pg1.image(img1, 0, 0);
    pg2.image(img2, 0, 0);
    pg1.loadPixels();
    pg2.loadPixels();
    colors1 = pg1.pixels;
    colors2 = pg2.pixels;
    
    // add changes as we iterate through image
    for (int x=0; x<canvasW; x++) {
      for (int y=0; y<canvasH; y++) {
        color c1 = colors1[x+y*canvasW];
        color c2 = colors2[x+y*canvasW];
        float cDistance = dist(hue(c1), saturation(c1), brightness(c1), hue(c2), saturation(c2), brightness(c2));
  
        // only add change if above threshold
        if (cDistance > distThreshold) {
          changes.add(new ImageChange(x, y, c1, c2));
        }
      }
    }
  }

  ArrayList<ImageChange> getChanges(){
    return changes;
  }

  String getImgFilename(){
    String[] parts = split(img, '/');
    return parts[parts.length-1];
  }

  String getImg() {
    return img;
  }

  int getYear(){
    return year;
  }

  boolean _shouldTurn(int row, int col, int h, int w) {
    int same = 1;
    if(row > h-1-row) {
      row = h-1-row;
      same = 0; // Give precedence to top-left over bottom-left
    }
    if(col >= w-1-col) {
      col = w-1-col;
      same = 0; // Give precedence to top-right over top-left
    }
    row -= same; // When the row and col doesn't change, this will reduce row by 1
    return row==col;
  }

}

class ImageChange
{
  int x, y;
  color c1, c2;

  ImageChange(int _x, int _y, color _c1, color _c2) {
    x = _x;
    y = _y;
    c1 = _c1;
    c2 = _c2;
  }

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

  color getC1() {
    return c1;
  }

  color getC2() {
    return c2;
  }
}
