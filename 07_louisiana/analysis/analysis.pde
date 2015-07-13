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
ArrayList<TimeRange> ranges;
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
  ranges = new ArrayList<TimeRange>();
  for (TableRow row : color_table.rows()) {
    Change c = new Change(row);
    boolean range_exists = false;
    for(int i=0; i<ranges.size(); i++) {
      TimeRange tr = ranges.get(i);
      if (tr.equalsChange(c)) {
        ranges.get(i).addChange(c);
        range_exists = true;
      }      
    }
    if (!range_exists) {
      ranges.add(new TimeRange(c)); 
    }
  }
  Collections.sort(ranges);
  
  // load the image data
  img = loadImage(img_file);
  pg = createGraphics(canvasW, canvasH);
  pg.image(img, 0, 0);
  pg.loadPixels();
  img_colors = pg.pixels;
  
  float[] distances = new float[canvasH*canvasW];
  
  for (int y=0; y<canvasH; y++) {
    for (int x=0; x<canvasW; x++) {
      color c = img_colors[x+y*canvasW];
      int h = (int) hue(c),
          s = (int) saturation(c),
          b = (int) brightness(c);
      float[] tr_distances = new float[color_table.getRowCount()];
      int i = 0;
      for(TimeRange tr : ranges) {
        for(Change trc : tr.getChanges()) {
          float d = dist(h, s, b, trc.getHue(), trc.getSaturation(), trc.getBrightness());
          tr_distances[i] = d;
          i++;
        }
      }
      tr_distances = sort(tr_distances);
      distances[x+y*canvasW] = tr_distances[1] - tr_distances[0];
    }        
  }
  
  print(min(distances));
  
  // add gain/loss data to ranges
  /* for(int i=0; i<ranges.size(); i++) {
    TimeRange tr = ranges.get(i);
    
    for(Change c : tr.getChanges()) {
      for (int y; y<canvasH; y++) {
        for (int x; x<canvasW; x++) {
          color c = img_colors[x+y*canvasW];
        }        
      }
    }
  } */
  
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
  ArrayList<Change> changes;
  
  TimeRange(Change c) {
    changes = new ArrayList<Change>();    
    changes.add(c);
  }
  
  void addChange(Change c) {
    changes.add(c);
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
  
  int getEnd() {
    return end;
  }
  
  int getStart() {
    return start; 
  }
  
  boolean equalsChange(Change c) {
    return c.getYearStart() == start && c.getYearEnd() == end;
  }
    
}

class Change
{
  int h, s, b, year_start, year_end, change;
  
  Change(TableRow _c) {    
    h = _c.getInt("h");
    s = _c.getInt("s");
    b = _c.getInt("b");
    year_start = _c.getInt("year_start");
    year_end = _c.getInt("year_end");
    change = _c.getInt("change");
  }
  
  int getBrightness() {
    return b;
  }
  
  int getHue() {
    return h;
  }
  
  int getSaturation() {
    return s;
  }
  
  int getYearEnd() {
    return year_end;
  }
  
  int getYearStart() {
    return year_start; 
  }
  
  

  boolean isActive(int year) {
    return year >= year_start && year < year_end;
  }  
    
}

