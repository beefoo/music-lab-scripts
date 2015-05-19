/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This script analyzes a list of images to generate a song
 */
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// resolution
int canvasW = 1280;
int canvasH = 720;
float cx = 0.5 * canvasW;
float cy = 0.5 * canvasH;

// colors
color bgColor = #262222;

// data
String paintings_file = "paintings.csv";
String samples_file = "data/painting_samples.csv";
Boolean SAVE_TABLE = true;
Table paintings_table;
ArrayList<Year> years;
int totalWidth = 0;
int maxWidth = -1;
int minYear = -1;
int maxYear = -1;
int painting_segment_sample_size = 512;
int color_radius_h = 25;
int color_radius_s = 15;
int color_radius_b = 15;

// components
int labelH = 48;
float lineW = 4;
color lineC = #ffffff;

// time
float msPerBeat = 250;
float pxPerBeat = 10;
float pxPerMs = pxPerBeat / msPerBeat;
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(HSB, 360, 100, 100);
  frameRate(fps);
  smooth();
  noStroke();  
  background(bgColor);  
  
  // load the data
  paintings_table = loadTable(paintings_file, "header");
  years = new ArrayList<Year>();
  for (TableRow row : paintings_table.rows()) {   
    if (row.getInt("active") > 0) {
      Painting p = new Painting(row);
      boolean found = false;
      for(int i=0; i<years.size(); i++) {
        Year y = years.get(i);
        if (y.getYear() == p.getYear()) {
          found = true;
          years.get(i).addPainting(p);
          break; 
        }
      }
      if (!found) {
        years.add(new Year(p));
      }
    }
  }
  
  // calculate time
  for (Year y: years) {
    stopMs += y.getDuration();
  }
  println("Pixels per second: " + pxPerMs * 1000);
  println("Total duration: " + floor(stopMs/1000/60) + "m " + floor((stopMs/1000)%60) + "s");
  
  // update year start/stop times
  float startPx = 0.0;
  for(int i=0; i<years.size(); i++) {
    Year y = years.get(i);
    float stopPx = startPx + y.getWidth();
    years.get(i).setTime(startPx/pxPerMs, stopPx/pxPerMs, startPx/pxPerMs - 0.5*canvasW/pxPerMs, stopPx/pxPerMs + 0.5*canvasW/pxPerMs);
    startPx = stopPx;
  }
  
  // setup table for writing to file
  Table samples_table = new Table();
  
  // painting columns
  samples_table.addColumn("title");
  samples_table.addColumn("artist");
  samples_table.addColumn("position");
  samples_table.addColumn("year");
  samples_table.addColumn("file");
  samples_table.addColumn("painting_width");
  samples_table.addColumn("painting_height");
  samples_table.addColumn("year_start_ms");
  samples_table.addColumn("year_stop_ms");
  
  // sample columns
  samples_table.addColumn("hue");
  samples_table.addColumn("saturation");
  samples_table.addColumn("brightness");
  samples_table.addColumn("x");
  samples_table.addColumn("y");
  samples_table.addColumn("width");
  samples_table.addColumn("height");
  
  // build table
  for (Year year: years) {      
      ArrayList<Painting> paintings = year.getPaintings();
      for (Painting p: paintings) {        
        ArrayList<PaintingSample> samples = p.getSamples();
        for (PaintingSample ps: samples) {
          TableRow newRow = samples_table.addRow();
          
          newRow.setString("title", p.getTitle());
          newRow.setString("artist", p.getArtist());
          newRow.setInt("position", p.getPosition());
          newRow.setInt("year", year.getYear());
          newRow.setString("file", p.getFile());
          newRow.setInt("painting_width", p.getWidth());
          newRow.setInt("painting_height", p.getHeight());
          newRow.setInt("year_start_ms", int(year.getStart()));
          newRow.setInt("year_stop_ms", int(year.getStop()));
          
          color c = ps.getColor();
          newRow.setInt("hue", int(hue(c)));
          newRow.setInt("saturation", int(saturation(c)));
          newRow.setInt("brightness", int(brightness(c)));
          newRow.setInt("x", ps.getX());
          newRow.setInt("y", ps.getY());
          newRow.setInt("width", ps.getW());
          newRow.setInt("height", ps.getH());
        }
      }
  } 
  
  // save table
  if (SAVE_TABLE) {
    saveTable(samples_table, samples_file);
  }  
  
  // noLoop();
}

void draw(){  
  background(bgColor);
  
  rectMode(CORNER);  
  
  // retrieve visible years
  for (Year year: years) {
    if (year.isInView(elapsedMs)) {
      
      float x = year.getX(elapsedMs);
      
      // retrieve paintings
      ArrayList<Painting> paintings = year.getPaintings();
      for (Painting p: paintings) {
        float pos = p.getPosition();
        float y = 1.0 * pos * p.getHeight() + (pos + 1) * labelH;
        fill(#ffffff);
        rect(x, y, p.getWidth(), p.getHeight());
        
        // place image
        image(p.getImg(), x, y);
        
        // place samples
        ArrayList<PaintingSample> samples = p.getSamples();
        for (PaintingSample ps: samples) {
          color c = color(hue(ps.getColor()), 100, 100);
          fill(c, 90);
          rect(x+ps.getX(), y+ps.getY(), ps.getW(), ps.getH());
        }
      }
      
    }
  }
  
  // draw a line
  rectMode(CENTER);
  fill(lineC, 50);
  rect(cx, cy, lineW, canvasH);
  
  // increment time
  elapsedMs += (1.0/fps) * 1000;
  
  // save image
  if(captureFrames) {
    saveFrame(outputFrameFile);
  }
  
  // check if we should exit
  if (elapsedMs > stopMs) {
    exit(); 
  }
}

void mousePressed() {
  exit();
}

float halton(int hIndex, int hBase) {    
  float result = 0;
  float f = 1.0 / hBase;
  int i = hIndex;
  while(i > 0) {
    result = result + f * float(i % hBase);
    
    i = floor(i / hBase);
    f = f / float(hBase);
  }
  return result;
}

class PaintingSample
{
  color c;
  int x, y, w, h, area;
  
  PaintingSample(color _c, int _x, int _y, int _w, int _h) {
    c = _c;
    x = _x;
    y = _y;
    w = _w;
    h = _h;
    area = w * h;
  }
  
  color getColor(){
    return c;
  }
  
  int getH(){
    return h;
  }
  
  int getW(){
    return w;
  }
  
  int getX(){
    return x;
  }
  
  int getY(){
    return y;
  }
}

class Painting
{
  String title, artist, file;
  int w, h, pw, position, beats;
  int year;
  PImage img;
  PGraphics pg;
  color[] colors;
  ArrayList<PaintingSample> samples;

  Painting(TableRow _painting) {
    year = _painting.getInt("year");
    title = _painting.getString("title");
    artist = _painting.getString("artist");
    position = _painting.getInt("position");
    file = _painting.getString("file");
    img = loadImage(file);
    w = img.width;
    h = img.height;
    pg = createGraphics(w, h);
    pg.image(img, 0, 0);
    pg.loadPixels();
    colors = pg.pixels;
    
    beats = floor(w / pxPerBeat);
    pw = floor(beats * pxPerBeat);
    samples = new ArrayList<PaintingSample>();  
    doAnalysis();
    
    // println("Loaded "+file+", "+w+"x"+h);
  }
  
  void doAnalysis() {
    for(int i=1; i<=painting_segment_sample_size; i++) {
      float hx = halton(i, 3),
            hy = halton(i, 5);    
      int x = floor(hx*w),
          y = floor(hy*h);       
      
      PaintingSample sample = doSample(x, y);
      samples.add(sample);
    }    
  }
  
  PaintingSample doSample(int x, int y) {
    color c1 = colors[x + y*w],
          c2 = c1;
    int x1 = x, x2 = x, y1 = y, y2 = y, _x = x, _y = y,
        sample_w = 0, sample_h = 0;
    
    // go north
    do {      
      c2 = colors[x + _y*w];
      _y--;
    } while(isSameColor(c1, c2) && _y>0);
    y1 = _y;
    _y = y;    
    
    // go south
    do {      
      c2 = colors[x + _y*w];
      _y++;
    } while(isSameColor(c1, c2) && _y<h-1);
    y2 = _y;
    _y = y;
    
    // go west
    do {      
      c2 = colors[_x + y*w];
      _x--;
    } while(isSameColor(c1, c2) && _x>0);
    x1 = _x;
    _x = x;
    
    // go east
    do {      
      c2 = colors[_x + y*w];
      _x++;
    } while(isSameColor(c1, c2) && _x<w-1);
    x2 = _x;
   
    sample_w = x2 - x1;
    sample_h = y2 - y1;   
    return new PaintingSample(c1, max(x1,0), max(y1,0), sample_w, sample_h);
  }
  
  boolean isSameColor(color c1, color c2) {
    float hue1 = hue(c1),
        hue2 = hue(c2);
    
    // fix colors on opposite sides of hue gradient
    if (hue1 < color_radius_h && hue2 > 360-color_radius_h) {
      hue1 = 360 + hue1;
      
    } else if (hue2 < color_radius_h && hue1 > 360-color_radius_h) {
      hue2 = 360 + hue2;
    }    
    
    float h_delta = abs(hue1 - hue2),
        s_delta = abs(saturation(c1) - saturation(c2)),
        b_delta = abs(brightness(c1) - brightness(c2));
    
    return h_delta < color_radius_h && s_delta < color_radius_s && b_delta < color_radius_b;
  }
  
  String getArtist(){
    return artist;
  }
  
  int getBeats(){
    return beats;
  }
  
  float getDuration() {
    return msPerBeat * beats;
  }
  
  String getFile(){
    return file;
  }
  
  int getHeight() {
    return h;
  }
  
  PImage getImg() {
    return img; 
  }
  
  int getPosition() {
    return position;
  }
  
  ArrayList<PaintingSample> getSamples(){
    return samples;
  }
  
  String getTitle(){
    return title;
  }
  
  int getWidth() {
    return pw; 
  }
  
  int getYear() {
    return year; 
  }
}

class Year
{
  ArrayList<Painting> paintings;
  int year;
  float start, stop, vstart, vstop;
  
  Year(Painting _p) {
    year = _p.getYear();
    paintings = new ArrayList<Painting>();
    addPainting(_p);
    start = 0;
    stop = 0;
  }
  
  void addPainting(Painting _p) {
    paintings.add(_p);
  }
  
  ArrayList<Painting> getPaintings(){
    return paintings;
  }
  
  float getDuration() {
    float d = 0;
    for (Painting p : paintings) {
      if (p.getDuration() > d) {
        d = p.getDuration();
      }
    }
    return d;
  }
  
  float getStart() {
    return start; 
  }
  
  float getStop() {
    return stop; 
  }
  
  int getWidth() {
    int w = 0;
    for (Painting p : paintings) {
      if (p.getWidth() > w) {
        w = p.getWidth();
      }
    }
    return w;
  }
  
  float getX(float ms) {
    float diff_ms = vstart - ms,
          diff_px = diff_ms * pxPerMs;
   
    return diff_px + canvasW; 
  }
  
  int getYear() {
    return year;
  }
  
  boolean isActive(float ms) {
    return ms >= start && ms < stop;
  }
  
  boolean isInView(float ms) {
    return ms >= vstart && ms < vstop;
  } 
  
  void setTime(float _start, float _stop, float _vstart, float _vstop) {
    start = _start;
    stop = _stop;
    vstart = _vstart;
    vstop = _vstop;
  }
  
}
