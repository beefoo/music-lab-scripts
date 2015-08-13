/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */

import java.util.Collections;

// jobs
boolean WRITE_DATA = true;
boolean WRITE_DATA_VIS = true;

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

  if (WRITE_DATA || WRITE_DATA_VIS) {
    analyzeData();
  }

  noLoop();
}

void draw(){

}

void mousePressed() {
  exit();
}

void analyzeData() {
  String image_dir = "../data/img/";
  String year_table_file = "../data/years.csv";
  Table year_table = loadTable(year_table_file, "header");
  ArrayList<Year> years = new ArrayList<Year>();

  // read csv data
  for (TableRow row : year_table.rows()) {
    int year = row.getInt("year_start");
    String img = image_dir + row.getString("image");
    years.add(new Year(year, img));
  }

  // calculate changes year-over-year
  for (int i=1; i<years.size(); i++) {
    Year currentYear = years.get(i);
    Year previousYear = years.get(i-1);
    currentYear.compareYear(previousYear);
  }

  // write data to file
  if (WRITE_DATA) {
    writeData(years);
  }

  // write data to file
  if (WRITE_DATA_VIS) {
    writeDataVis(years);
  }

}

void writeData(ArrayList<Year> years) {
  String changes_output_file = "../data/land_loss.json";

  int total_change = 0;
  for (int i=1; i<years.size(); i++) {
    Year currentYear = years.get(i);
    total_change += currentYear.getChange();
  }

  JSONArray changes_json_array = new JSONArray();
  for (int i=1; i<years.size(); i++) {
    Year currentYear = years.get(i);
    Year previousYear = years.get(i-1);

    JSONObject c_json = new JSONObject();
    c_json.setInt("year_start", previousYear.getYear());
    c_json.setInt("year_end", currentYear.getYear());
    c_json.setFloat("loss", 1.0*currentYear.getChange()/total_change);

    JSONArray ic_json_array = new JSONArray();
    ArrayList<Change> changes = currentYear.getChanges();
    for(int j=0; j<changes.size(); j++) {
      Change ic = changes.get(j);
      if (ic.getChange() < 0) {
        JSONArray ic_json_pair = new JSONArray();
        ic_json_pair.append(round(1.0*ic.getX()/canvasW*100));
        ic_json_pair.append(round(1.0*ic.getY()/canvasH*100));
        ic_json_array.append(ic_json_pair);
      }
    }
    c_json.setJSONArray("losses", ic_json_array);
    changes_json_array.append(c_json);
  }
  saveJSONArray(changes_json_array, changes_output_file);
  print("Wrote data to file: "+changes_output_file);
}

void writeDataVis(ArrayList<Year> years) {
  String changes_output_file = "../visualization/data/changes.json";

  JSONArray changes_json_array = new JSONArray();
  for (int i=1; i<years.size(); i++) {
    Year currentYear = years.get(i);
    Year previousYear = years.get(i-1);

    JSONObject c_json = new JSONObject();
    c_json.setInt("year_start", previousYear.getYear());
    c_json.setInt("year_end", currentYear.getYear());
    c_json.setString("img_start", previousYear.getImg());
    c_json.setString("img_end", currentYear.getImg());

    JSONArray ic_json_array = new JSONArray();
    ArrayList<Change> changes = currentYear.getChanges();
    for(int j=0; j<changes.size(); j++) {
      Change ic = changes.get(j);
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

float roundToNearest(float n, float nearest) {
  return 1.0 * round(n/nearest) * nearest;
}

int sum(int[] list) {
  int total = 0;
  for (int i = 0; i < list.length; i++) {
    total += list[i];
  }
  return total;
}

class Year
{
  int year, total_change;
  String img;
  ArrayList<Change> changes;

  float distThreshold = 10.0;

  Year(int _year, String _img) {
    year = _year;
    img = _img;
    changes = new ArrayList<Change>();
    total_change = 0;
  }

  void compareYear(Year y2) {
    PGraphics pg1, pg2;
    PImage img1, img2;
    color[] colors1, colors2;

    changes = new ArrayList<Change>();
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
          Change c = new Change(x, y, c1, c2);
          changes.add(c);
          total_change += c.getChange();
        }
      }
    }
  }

  ArrayList<Change> getChanges(){
    return changes;
  }

  String getImg() {
    return img;
  }

  int getChange(){
    return total_change;
  }

  int getYear(){
    return year;
  }

}

class Change
{
  int x, y;
  color c1, c2;

  Change(int _x, int _y, color _c1, color _c2) {
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

  int getChange(){
    int c = 0;
    // blue has a higher hue than green
    if (hue(c1) > hue(c2)) {
      c = 1;
    } else if (hue(c1) < hue(c2)) {
      c = -1;
    }
    return c;
  }
}
