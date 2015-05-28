/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Lee and Jackson"
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
String paintings_file = "../data/paintings.csv";
String events_file = "../data/events.csv";
Table paintings_table, events_table;
ArrayList<Year> years;
int totalWidth = 0;
int maxWidth = -1;
int minYear = -1;
int maxYear = -1;

// images and graphics
PImage img_lee;
PImage img_jackson;
PShape arrow;
boolean drawArtists = false;

// components
int labelH = 48;
float lineW = 4;
color lineC = #ffffff;
float arrowW = 100;
color arrowC = #aa9e9e;
color highlightC = #e8272a;
float highlightW = 4;

// text
color textC = #ede1e1;
color textDarkC = #9b8d8d;
color textHighlightC = #fff7a3;
int fontSize = 22;
PFont font = createFont("OpenSans-Semibold", fontSize, true);
int fontSizeBig = 48;
PFont fontBig = createFont("OpenSans-Extrabold", fontSizeBig, true);

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
  // smooth();
  noStroke();  
  background(bgColor);
  
  img_lee = loadImage("lee-krasner.jpg");
  img_jackson = loadImage("jackson-pollock.jpg");
  arrow = loadShape("double_arrow_thin.svg");
  arrow.disableStyle();
  
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
  
  events_table = loadTable(events_file, "header");
  for (TableRow row : events_table.rows()) {
    Event evt = new Event(row);
    
    for(int i=0; i<years.size(); i++) {
      Year y = years.get(i);
      if (y.getYear() >= evt.getYear()) {
        years.get(i).setEvent(evt);
        break;
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
  
  // noLoop();
}

void draw(){  
  background(bgColor);  
  rectMode(CORNER);
  textFont(font);
  shapeMode(CENTER);
  
  // elapsedMs = millis();
  
  // check to draw artists
  if (drawArtists && elapsedMs < (cx / pxPerMs)) {
    float x = labelH - elapsedMs * pxPerMs;
    
    // images
    image(img_lee, x, labelH);
    image(img_jackson, x, labelH*2 + img_lee.height);
    
    // text
    fill(textC);
    textAlign(LEFT, CENTER);
    text("Lee Krasner (1908-1984)", x, 0.45*labelH);
    text("Jackson Pollock (1912-1956)", x, canvasH-0.6*labelH);
    
    // arrows
    fill(arrowC);
    shape(arrow, x + img_lee.width + labelH*2 , labelH + 0.5*img_lee.height, arrowW, arrowW);
    shape(arrow, x + img_jackson.width + labelH*2 , canvasH - labelH - 0.5*img_jackson.height, arrowW, arrowW);
  }
  
  // retrieve visible years
  for (Year year: years) {
    if (year.isInView(elapsedMs)) {
      
      float x = year.getX(elapsedMs);
      x = (float) round(x);
      
      // retrieve paintings
      textAlign(LEFT, CENTER);
      ArrayList<Painting> paintings = year.getPaintings();
      for (Painting p: paintings) {
        float pos = p.getPosition();
        float y = 1.0 * pos * p.getHeight() + (pos + 1) * labelH;
        PImage img = p.getImg();        
        
        // if active, highlight
        if (!(year.isActive(elapsedMs) && (year.getStart()+p.getDuration()) > elapsedMs)) {
          // place image
          image(img, x, y);
          fill(#000000, 99.999);
          noStroke();
          rect(x, y, img.width, img.height);          
        }
        
        // place title
        fill(textDarkC);
        String title = p.getTitle() + ", "+ p.getYear();
        if (pos <= 0) {
          text(title, x, y-0.55*labelH);
        } else {
          text(title, x, y+p.getHeight()+0.4*labelH);
        }
        
      }
      
      // place event
      Event evt = year.getEvent();
      if (evt.getYear() > 0) {
        fill(textHighlightC);
        String description = evt.getDescription() + " ("+ evt.getYear()+")";
        if (evt.getYear() < year.getYear()) {
          textAlign(CENTER, CENTER);
        } else {
          textAlign(LEFT, CENTER);
        }
        text(description, x, cy-5);      
      }
      
    }
  }
  
  // retrieve active years
  for (Year year: years) {
    if (year.isActive(elapsedMs)) {
      
      float x = year.getX(elapsedMs);
      x = (float) round(x);
      
      // retrieve paintings
      textAlign(LEFT, CENTER);
      ArrayList<Painting> paintings = year.getPaintings();
      for (Painting p: paintings) {
        float pos = p.getPosition();
        float y = 1.0 * pos * p.getHeight() + (pos + 1) * labelH;
        PImage img = p.getImg();
        
        // if active, highlight
        if ((year.getStart()+p.getDuration()) > elapsedMs) {
          // place image
          image(img, x, y);
          stroke(highlightC);
          strokeWeight(highlightW);
          noFill();
          rect(x, y, img.width, img.height);
        }       
        noStroke();
        
        // place title
        fill(textC);
        String title = p.getTitle() + ", "+ p.getYear();
        if (pos <= 0) {
          text(title, x, y-0.55*labelH);
        } else {
          text(title, x, y+p.getHeight()+0.4*labelH);
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

float roundP(float number, float decimal) {
  return (float)(floor((number*pow(10, decimal))))/pow(10, decimal);
}

class Event
{
  String description;
  int year;
  
  Event(TableRow _event) {    
    description = _event.getString("description");
    year = _event.getInt("year");
  }
  
  String getDescription(){
    return description;
  }
  
  int getYear() {
    return year; 
  }
}

class Painting
{
  String title, artist, file;
  int w, h, pw, position, beats;
  int year;
  PImage img;

  Painting(TableRow _painting) {
    year = _painting.getInt("year");
    title = _painting.getString("title");
    artist = _painting.getString("artist");
    position = _painting.getInt("position");
    file = _painting.getString("file");
    img = loadImage(file);
    w = img.width;
    h = img.height;
    
    beats = floor(w / pxPerBeat);
    pw = floor(beats * pxPerBeat);
    
    // println("Loaded "+file+", "+w+"x"+h);
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
  Event event;
  
  Year(Painting _p) {
    year = _p.getYear();
    paintings = new ArrayList<Painting>();
    addPainting(_p);
    start = 0;
    stop = 0;
    
    Table table = new Table();
    table.addColumn("year", Table.INT);
    table.addColumn("description", Table.STRING);
    TableRow row = table.addRow();
    row.setInt("year", -1);
    row.setString("description", "");
    event = new Event(row);
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
  
  Event getEvent(){
    return event;
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
    float padding = stop - start;
    
    return ms >= (vstart-padding) && ms < (vstop+padding);
  }
  
  void setEvent(Event _event) {
    event = _event; 
  }
  
  void setTime(float _start, float _stop, float _vstart, float _vstop) {
    start = _start;
    stop = _stop;
    vstart = _vstart;
    vstop = _vstop;
  }
  
}
