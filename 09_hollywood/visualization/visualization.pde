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
ArrayList<Movie> movies;
ArrayList<Race> races;
JSONArray races_json_array;
JSONArray movies_json_array;
String races_file = "../data/races.json";
String movies_file = "../data/top_10_movies_2006-2015.json";
boolean showLabels = true;

// color
color bgColor = #232020;

// text
color textC = #f4f3ef;

// components
float componentMargin = 30;
float componentMarginSmall = 10;

// race
float raceH = 10;

// cast component
float castW = 180;
float castH = castW;
float castLeft = 100;
float castTextH = 60;
float featuredLeft = ((castW * 3 + componentMargin*2) - (castW * 2 + componentMargin)) / 2;
int castFontSize = 18;
PFont castFont = createFont("OpenSans-Regular", castFontSize, true);
int castTextLeading = castFontSize + 6;
float castTop = (1.0 * canvasH - (castH * 2 + castTextH * 2 + componentMarginSmall*4 + raceH*2)) / 2;
float voicePercent = 0.8;
float animatedPercent = 0.4;
float animatedW = castW * animatedPercent;
float animatedH = animatedW;

// movie component
float movieW = 300;
float movieTop = 80;
float movieLeft = (1.0 * canvasW - (movieW + castW * 3 + componentMargin * 2 + castLeft)) / 2;
int movieFontSize = 24;
PFont movieFont = createFont("OpenSans-Semibold", movieFontSize, true);
int movieTextLeading = movieFontSize + 6;
float movieTextH = 100;

// legend
float legendH = 30;
float legendW = castW * 3 + componentMargin * 2;
int legendFontSize = 16;
float legendColW = 0;
PFont legendFont = createFont("OpenSans-Regular", legendFontSize, true);
int legendTextLeading = int(legendH);

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;
float movieMs = 10000;

void setup() {
  // set the stage
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();
  noFill();

  // load the race data
  races = new ArrayList<Race>();
  races_json_array = loadJSONArray(races_file);
  for (int i = 0; i < races_json_array.size(); i++) {
    JSONObject race_json = races_json_array.getJSONObject(i);
    races.add(new Race(race_json));
  }
  legendColW = 1.0 * canvasW / races.size();

  // load the movie data
  movies = new ArrayList<Movie>();
  movies_json_array = loadJSONArray(movies_file);
  for (int i = 0; i < movies_json_array.size(); i++) {
    JSONObject movie_json = movies_json_array.getJSONObject(i);
    movies.add(new Movie(movie_json, i, movieMs));
  }

  // determine length
  stopMs = movies.get(movies.size()-1).getEndMs();

  // noLoop();
}

void draw(){

  // get current movie
  Movie current_movie = movies.get(movies.size()-1);
  for (int i = 0; i < movies.size(); i++) {
    Movie m = movies.get(i);
    if (m.isActive(elapsedMs)) {
      current_movie = m;
      break;
    }
  }

  background(bgColor);

  float marginY = movieTop;
  float marginX = movieLeft;

  // draw the movie image
  float movieH = movieW / current_movie.getImageRatio();
  image(current_movie.getImage(), marginX, marginY, movieW, movieH);

  // draw the movie text
  marginY += movieH + componentMargin;
  fill(textC);
  textAlign(CENTER, TOP);
  textFont(movieFont);
  textLeading(movieTextLeading);
  text(current_movie.getLabel(), marginX, marginY, movieW, movieTextH);

  // draw the cast
  float movieLeftOffset = marginX + movieW + castLeft;
  marginY = castTop;
  marginX = movieLeftOffset + featuredLeft;
  textFont(castFont);
  textLeading(castTextLeading);
  ArrayList<Person> cast = current_movie.getPeople();
  for(int i=0; i<2; i++) {
    Person p = cast.get(i);
    drawPerson(p, marginX, marginY);
    marginX += componentMargin + castW;
  }
  marginX = movieLeftOffset;
  marginY += componentMarginSmall*2 + castH + castTextH + raceH;
  for(int i=2; i<5; i++) {
    Person p = cast.get(i);
    drawPerson(p, marginX, marginY);
    marginX += componentMargin + castW;
  }

  // draw legend
  if (showLabels) {
    marginY = canvasH - legendH;
    marginX = 0;
    textAlign(CENTER, CENTER);
    textFont(legendFont);
    textLeading(legendTextLeading);
    for (int i = 0; i < races.size(); i++) {
      Race r = races.get(i);
      fill(r.getColor());
      rect(marginX, marginY, legendColW, legendH);
      fill(bgColor);
      text(r.getLabel(), marginX, marginY - 2, legendColW, legendH);
      marginX += legendColW;
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

void drawPerson(Person p, float marginX, float marginY){
  if (p.isVoice()) {
    image(p.getImage(), marginX, marginY, castW*voicePercent, castH*voicePercent);
    image(p.getImageCharacter(), marginX + (castW-animatedW), marginY + (castH-animatedH), animatedW, animatedH);
  } else {
    image(p.getImage(), marginX, marginY, castW, castH);
  }
  if (showLabels) {
    drawPersonRace(marginX, marginY + castH, castW, raceH, p.getRaces(), races);
  }
  fill(textC);
  text(p.getLabel(), marginX, marginY + componentMarginSmall + castH + raceH, castW, castTextH);
}

void drawPersonRace(float x, float y, float w, float h, JSONObject race, ArrayList<Race> race_list) {
  for(int i=0; i<race_list.size(); i++) {
    Race r = race_list.get(i);
    if (race.isNull(r.getKey())) {
      continue;
    }
    float racePercent = race.getFloat(r.getKey());
    if (racePercent > 0) {
      float rw = racePercent * w;
      fill(r.getColor());
      rect(x, y, rw, h);
      x += rw;
    }
  }
}

class Movie
{
  int index;
  float start_ms, end_ms;
  String name, gross, year;
  ArrayList<Person> people;
  PImage image;

  Movie(JSONObject _movie, int _index, float _movieMs) {
    index = _index;
    name = _movie.getString("name");
    gross = _movie.getString("gross_f");
    year = "" + _movie.getInt("year");
    start_ms = _index * _movieMs;
    end_ms = (_index+1) * _movieMs;
    image = loadImage("movies/"+_movie.getString("imdb_id")+".jpg");

    // look through movie's people
    people = new ArrayList<Person>();
    JSONArray people_json_array = _movie.getJSONArray("people");
    for (int i = 0; i < people_json_array.size(); i++) {
      JSONObject person_json = people_json_array.getJSONObject(i);
      people.add(new Person(person_json));
    }
  }

  float getEndMs(){
    return end_ms;
  }

  String getGross(){
    return gross;
  }

  PImage getImage(){
    return image;
  }

  float getImageRatio(){
    return 1.0 * image.width / image.height;
  }

  String getLabel(){
    return name + " (" + year + ")";
  }

  String getName(){
    return name;
  }

  ArrayList<Person> getPeople(){
    return people;
  }

  String getYear(){
    return year;
  }

  boolean isActive(float ms) {
    return ms >= start_ms && ms < end_ms;
  }

}

class Person
{
  String name, gender;
  boolean voice;
  PImage image, image_character;
  JSONObject my_races;

  Person(JSONObject _person) {
    name = _person.getString("name");
    gender = _person.getString("gender");
    voice = (_person.getInt("voice") > 0);
    image = loadImage("people/"+_person.getString("imdb_id")+"_"+_person.getString("movie_imdb_id")+".jpg");
    if (voice) {
      image_character = loadImage("characters/"+_person.getString("imdb_id")+"_"+_person.getString("movie_imdb_id")+".jpg");
    } else {
      image_character = createImage(10, 10, RGB);
    }
    my_races = _person.getJSONObject("races");
  }

  String getGender(){
    return gender;
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

  JSONObject getRaces(){
    return my_races;
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
