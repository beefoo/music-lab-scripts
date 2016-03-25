/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */

// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
String outputFrameFileMulti = "output/frames{i}/frames-#####.png";
boolean captureFrames = false;
int outputFolders = 2;

// resolution
int canvasW = 1280;
int canvasH = 720;

// data
ArrayList<Movie> movies;
ArrayList<Race> races;
ArrayList<Category> categories;
JSONArray races_json_array;
JSONArray movies_json_array;
String races_file = "../data/races.json";
String movies_file = "../data/top_10_movies_2006-2015.json";
boolean showLabels = true;
int castPerMovie = 5;

// color
color bgColor = #161414;
color labelBgColor = #0a0909;

// text
color textC = #f4f3ef;
int castFontSize = 16;
PFont castFont = createFont("OpenSans-Regular", castFontSize, true);
int categoryFontSize = 18;
PFont categoryFont = createFont("OpenSans-Regular", castFontSize, true);

// components
float movieW = 360;
float categoryW = (1.0 * canvasW - movieW) / 4;
float categoryH = 60;
float castMargin = 70;
float castW = categoryW - castMargin*2;
float castLabelH = 40;
float raceW = castW;
float raceH = 0;
float castH = castW + castLabelH + raceH;
float movieH = castH * castPerMovie;
int graphicsW = canvasW;
int graphicsH = int(movieH);

// labels
PGraphics pg_categories;

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;
float movieMs = 4000;
float movieStartPx = -movieH;
float movieStopPx = 1.0 * canvasH;

// to be define
float pxPerMs = 0;
float msPerPx = 0;
float movieLeadingMs = 0;
float totalFrames = 0;
float framesPerFolder = 0;

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();

  // make timing calculations
  pxPerMs = movieH / movieMs;
  msPerPx = 1.0 / pxPerMs;

  movieLeadingMs = (1.0 * canvasH - categoryH) * msPerPx;

  // load categories
  categories = new ArrayList<Category>();
  categories.add(new Category("Identifies as\nWhite Male", "#282828", "m", false, 0));
  categories.add(new Category("Identifies as\nWhite Female", "#333333", "f", false, 1));
  categories.add(new Category("Identifies as\nMale Person of Color", "#282828", "m", true, 2));
  categories.add(new Category("Identifies as\nFemale Person of Color", "#333333", "f", true, 3));

  // load the race data
  races = new ArrayList<Race>();
  races_json_array = loadJSONArray(races_file);
  for (int i = 0; i < races_json_array.size(); i++) {
    JSONObject race_json = races_json_array.getJSONObject(i);
    races.add(new Race(race_json));
  }

  // load the movie data
  movies = new ArrayList<Movie>();
  movies_json_array = loadJSONArray(movies_file);
  for (int i = 0; i < movies_json_array.size(); i++) {
    JSONObject movie_json = movies_json_array.getJSONObject(i);
    float start = movieMs * i;
    float duration = movieMs + movieLeadingMs;
    movies.add(new Movie(movie_json, i, start, start + duration));

    // if (i > 10) { break; }
  }

  // determine length
  if (stopMs <= 0) {
    stopMs = movies.get(movies.size()-1).getEndMs();
  }

  // determine the frames
  totalFrames = stopMs * 0.001 * fps;
  framesPerFolder = totalFrames / outputFolders;

  buildCategories();

  // noLoop();
}

void draw(){

  // get active movies
  boolean foundVisible = false;
  boolean foundActive = false;
  ArrayList<Movie> visible_movies = new ArrayList<Movie>();
  Movie active_movie = movies.get(0);
  for (int i=movies.size()-1; i>=0; i--) {
    Movie m = movies.get(i);
    // visible movie found
    if (m.isVisible(elapsedMs)) {
      visible_movies.add(0, m);
      foundVisible = true;

    // we're finished with this movie, free up memory and garbage collect
    } else if (foundVisible) {
      m.clearFromMemory();
      movies.remove(i);
      System.gc();
    }
    // active movie found
    if (m.isActive(elapsedMs)) {
      active_movie = m;
      foundActive = true;
    }
  }

  background(lerpColor(bgColor, #000000, 0.75));
  // background(bgColor);

  // draw movies
  for (Movie m : visible_movies) {
    float percentProgress = m.getProgress(elapsedMs);
    float y = lerp(movieStartPx, movieStopPx, percentProgress);
    if (!m.isGraphicsInitialized()) { m.buildGraphics(); }
    image(m.getGraphics(), 0, y, graphicsW, graphicsH);
  }

  // update categories if necessary
  if (foundActive) {
    Person active_person = active_movie.getPersonActive(elapsedMs);
    Category active_category = active_person.getCategory();
    updateCategories(active_category.getIndex(), active_person.getProgress(elapsedMs));
  }

  // draw category labels
  image(pg_categories, movieW, canvasH - categoryH, categoryW * 4, categoryH);

  // increment time
  elapsedMs += frameMs;

  // save image
  if(captureFrames) {
    // check which folder if more than one output folders
    if (outputFolders > 1) {
      int folder = floor(frameCount / framesPerFolder) + 1;
      outputFrameFile = outputFrameFileMulti.replace("{i}", ""+folder);
    }
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

void buildCategories(){
  // setup category graphics
  pg_categories = createGraphics(int(categoryW*4), int(categoryH));
  updateCategories(-1, -1);
}

void updateCategories(int active, float amount){
  pg_categories.beginDraw();
  pg_categories.clear();
  pg_categories.noStroke();
  pg_categories.textFont(categoryFont);
  pg_categories.textAlign(CENTER, CENTER);

  for(int i=0; i<categories.size(); i++){
    Category c = categories.get(i);
    if (i==active) {
      color lerpedColor = lerpColor(c.getColorActive(), c.getColor(), amount);
      pg_categories.fill(lerpedColor);
    } else {
      pg_categories.fill(c.getColor());
    }

    pg_categories.rect(i*categoryW, 0, categoryW, categoryH);
    pg_categories.fill(#ffffff);
    pg_categories.text(c.getLabel(), i*categoryW, 0, categoryW, categoryH);
  }

  pg_categories.endDraw();
}

class Movie
{
  boolean graphicsInitialized;
  int index;
  float start_ms, end_ms;
  String name, gross, year, imageFileString;
  ArrayList<Person> people;
  PImage image;
  PGraphics pg;

  Movie(JSONObject _movie, int _index, float _startMs, float _endMs) {
    index = _index;
    name = _movie.getString("name");
    gross = _movie.getString("gross_f");
    year = "" + _movie.getInt("year");
    start_ms = _startMs;
    end_ms = _endMs;
    imageFileString = "movies/"+_movie.getString("imdb_id")+".jpg";

    // look through movie's people
    people = new ArrayList<Person>();
    JSONArray people_json_array = _movie.getJSONArray("people");
    float person_duration = movieMs / castPerMovie;
    for (int i = 0; i < people_json_array.size(); i++) {
      JSONObject person_json = people_json_array.getJSONObject(i);
      float p_start_ms = start_ms+movieLeadingMs+person_duration*i;
      people.add(new Person(person_json, i, p_start_ms, p_start_ms+person_duration));
    }

    // build graphics
    graphicsInitialized = false;
    // buildGraphics();
  }

  void buildGraphics(){
    pg = createGraphics(graphicsW, graphicsH);

    image = loadImage(imageFileString);

    // init
    pg.beginDraw();
    if (index % 2 == 0) {
      //pg.background(lerpColor(bgColor, #000000, 0.75));
      pg.background(bgColor);
    } else {
      pg.background(bgColor);
    }

    pg.colorMode(RGB, 255, 255, 255, 100);
    pg.noStroke();
    pg.textAlign(CENTER, CENTER);

    float imgRatio = 1.0 * image.width / image.height;
    float imgW = movieW;
    float imgH = imgW / imgRatio;

    // place the movie image
    pg.image(image, 0, graphicsH - imgH, imgW, imgH);

    // place the cast
    float offsetY = 0;
    for (Person p : people) {
      float x = movieW;
      if (p.getGender().equals("f")) { x += categoryW; }
      if (p.isPoc()) { x += categoryW * 2; }
      float y = graphicsH - castH - offsetY;

      // draw person
      if (!p.isGraphicsInitialized()) { p.buildGraphics(); }
      pg.image(p.getGraphics(), x, y, categoryW, castH);

      offsetY += castH;
    }

    pg.endDraw();
    graphicsInitialized = true;
  }

  void clearFromMemory(){
    if (graphicsInitialized) {
      pg.beginDraw();
      pg.clear();
      pg.endDraw();
      g.removeCache(image);
      image = null;
      pg = null;
      for(Person p : people) {
        p.clearFromMemory();
      }
    }
  }

  float getEndMs(){
    return end_ms;
  }

  PGraphics getGraphics(){
    return pg;
  }

  Person getPersonActive(float ms){
    float p = getProgressActive(ms);
    int i = floor(p * castPerMovie);
    return people.get(i);
  }

  float getProgress(float ms){
    float p = (ms - start_ms) / (end_ms - start_ms);
    p = min(p, 1);
    p = max(p, 0);
    return p;
  }

  float getProgressActive(float ms){
    float p = (ms - (start_ms+movieLeadingMs)) / (end_ms - (start_ms+movieLeadingMs));
    p = min(p, 1);
    p = max(p, 0);
    return p;
  }

  boolean isActive(float ms) {
    return ms >= (start_ms+movieLeadingMs) && ms < end_ms;
  }

  boolean isGraphicsInitialized() {
    return graphicsInitialized;
  }

  boolean isVisible(float ms) {
    return ms >= start_ms && ms < end_ms;
  }

}

class Person
{
  String name, gender, imageFileName, imageCharFileName;
  boolean voice, poc, graphicsInitialized;
  PImage image, image_character;
  JSONObject my_races;
  PGraphics pg;
  Category category;
  int index;
  float start_ms, end_ms;

  Person(JSONObject _person, int _index, float _start_ms, float _end_ms) {
    name = _person.getString("name");
    gender = _person.getString("gender");
    voice = (_person.getInt("voice") > 0);
    poc = (_person.getInt("identifies_poc") > 0);
    imageFileName = "people/"+_person.getString("imdb_id")+"_"+_person.getString("movie_imdb_id")+".jpg";
    index = _index;
    start_ms = _start_ms;
    end_ms = _end_ms;
    imageCharFileName = "";
    if (voice) {
      imageCharFileName = "characters/"+_person.getString("imdb_id")+"_"+_person.getString("movie_imdb_id")+".jpg";
    }
    my_races = _person.getJSONObject("races");

    for(Category c : categories){
      if (gender.equals(c.getGender()) && poc == c.getPoc()) {
        category = c;
      }
    }

    // buildGraphics();
    graphicsInitialized = false;
  }

  void buildGraphics(){
    pg = createGraphics(int(categoryW), int(castH));

    image = loadImage(imageFileName);
    if (voice){
      image_character = loadImage(imageCharFileName);
    } else {
      image_character = createImage(10, 10, RGB);
    }

    // init
    pg.beginDraw();
    // pg.background(bgColor);
    pg.noStroke();
    pg.textFont(castFont);
    pg.textAlign(CENTER, CENTER);

    float x = castMargin;
    float y = 0;

    // place the image
    pg.image(image, x, y, castW, castW);
    // place character image
    if (voice){
      float resize = 0.5;
      float offset = (castW-castW*resize);
      pg.image(image_character, x + offset + castW*resize*0.6, y + offset, castW * resize, castW * resize);
    }
    y += castW;

    // place the races
    if (raceH > 0) {
      for(Race r : races) {
        if (my_races.isNull(r.getKey())) { continue; }
        float racePercent = my_races.getFloat(r.getKey());
        if (racePercent > 0) {
          float rw = racePercent * castW;
          pg.fill(r.getColor());
          pg.rect(x, y, rw, raceH);
          x += rw;
        }
      }
      x = 0;
      y += raceH;
    }

    // place the label
    // pg.fill(labelBgColor);
    // pg.rect(x, y, castW, castLabelH);
    x = 0;
    pg.fill(#ffffff);
    pg.text(getLabel(), x, y, categoryW, castLabelH);

    pg.endDraw();

    graphicsInitialized = true;
  }

  void clearFromMemory(){
    if (graphicsInitialized) {
      pg.beginDraw();
      pg.clear();
      pg.endDraw();
      g.removeCache(image);
      g.removeCache(image_character);
      image = null;
      image_character = null;
      pg = null;
    }
  }

  Category getCategory(){
    return category;
  }

  String getGender(){
    return gender;
  }

  PGraphics getGraphics(){
    return pg;
  }

  PImage getImage(){
    return image;
  }

  PImage getImageCharacter(){
    return image_character;
  }

  String getLabel(){
    String label = name;
    if (isVoice()) {
      label += " (voice)";
    }
    return label;
  }

  String getName(){
    return name;
  }

  float getProgress(float ms){
    float p = (ms - start_ms) / (end_ms - start_ms);
    p = min(p, 1);
    p = max(p, 0);
    return p;
  }

  JSONObject getRaces(){
    return my_races;
  }

  boolean isGraphicsInitialized() {
    return graphicsInitialized;
  }

  boolean isPoc(){
    return poc;
  }

  boolean isVoice(){
    return voice;
  }

}

class Race
{
  String my_key, label;
  color my_color;

  Race(JSONObject _race) {
    my_key = _race.getString("key");
    label = _race.getString("label");
    String color_string = _race.getString("color");
    color_string = "FF" + color_string.substring(1);
    my_color = unhex(color_string);
  }

  color getColor(){
    return my_color;
  }

  String getKey(){
    return my_key;
  }

  String getLabel(){
    return label;
  }

}

class Category
{
  int index;
  boolean poc;
  String label, gender;
  color my_color, active_color;

  Category(String _label, String _color, String _gender, boolean _poc, int _index) {
    label = _label;
    _color = "FF" + _color.substring(1);
    my_color = unhex(_color);
    gender = _gender;
    poc = _poc;
    index = _index;
    active_color = lerpColor(my_color, #ffffff, 0.5);
  }

  color getColor(){
    return my_color;
  }

  color getColorActive(){
    return active_color;
  }

  String getGender(){
    return gender;
  }

  int getIndex(){
    return index;
  }

  String getLabel(){
    return label;
  }

  boolean getPoc(){
    return poc;
  }

}
