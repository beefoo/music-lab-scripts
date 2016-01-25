/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */

// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = true;

// resolution
int canvasW = 1280;
int canvasH = 720;

// data
ArrayList<Movie> movies;
ArrayList<Race> races;
JSONArray races_json_array;
JSONArray movies_json_array;
String races_file = "../data/races.json";
String movies_file = "../data/top_10_movies_2011-2015.json";

// color
color bgColor = #232020;

// text
color textC = #f4f3ef;
int fontSize = 42;
PFont font = createFont("OpenSans-Semibold", fontSize, true);

// time
float startMs = 0;
float stopMs = 0;
float elapsedMs = startMs;
float frameMs = (1.0/fps) * 1000;
float movieMs = 1000;

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

  // draw the movie image and info
  fill(textC);
  textAlign(LEFT, TOP);
  textFont(font);
  text(current_movie.getName(), 20, 20);

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

  int getIndex(){
    return index;
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
  PImage image;
  JSONObject my_races;

  Person(JSONObject _person) {
    name = _person.getString("name");
    gender = _person.getString("gender");
    voice = (_person.getInt("voice") > 0);
    image = loadImage("people/"+_person.getString("imdb_id")+"_"+_person.getString("movie_id")+".jpg");
    my_races = _person.getJSONObject("races");
  }

  String getGender(){
    return gender;
  }

  PImage getImage(){
    return image;
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
