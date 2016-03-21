/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 */

ArrayList<Movie> movies;
JSONArray movies_json_array;
String movies_file = "../data/top_10_movies_2006-2015.json";
String image_dir = "../visualization/data/";
int imgW = 40;
int imgH = imgW;
int imgPerRow = 50;
int peoplePerMovie = 5;
int canvasW, canvasH;

void setup() {
  // load the movie data
  movies = new ArrayList<Movie>();
  movies_json_array = loadJSONArray(movies_file);
  for (int i = 0; i < movies_json_array.size(); i++) {
    if (i >= 50) break;
    // if (i < 50) continue;

    JSONObject movie_json = movies_json_array.getJSONObject(i);
    movies.add(new Movie(movie_json));


  }

  // set the stage
  canvasW = floor(imgW * imgPerRow);
  canvasH = ceil(1.0 * movies.size() * peoplePerMovie / imgPerRow * imgH);
  size(canvasW, canvasH);
  colorMode(RGB, 255, 255, 255, 100);
  noStroke();
  noFill();
  noLoop();
}

void draw(){
  int x = 0;
  int y = 0;

  for(Movie m : movies){

    for(Person p : m.getPeople()) {
      image(p.getImage(), x, y, imgW, imgH);

      x += imgW;

      if (x >= canvasW) {
        x = 0;
        y += imgH;
      }
    }

  }
}

void mousePressed() {
  saveFrame("output/frame.png");
  exit();
}

class Movie
{
  ArrayList<Person> people;

  Movie(JSONObject _movie) {

    // look through movie's people
    people = new ArrayList<Person>();
    JSONArray people_json_array = _movie.getJSONArray("people");
    for (int i = 0; i < people_json_array.size(); i++) {
      JSONObject person_json = people_json_array.getJSONObject(i);
      people.add(new Person(person_json));
    }
  }

  ArrayList<Person> getPeople(){
    return people;
  }

}

class Person
{
  boolean voice;
  PImage image, image_character;

  Person(JSONObject _person) {
    voice = (_person.getInt("voice") > 0);
    image = loadImage(image_dir+"people/"+_person.getString("imdb_id")+"_"+_person.getString("movie_imdb_id")+".jpg");
    if (voice) {
      image_character = loadImage(image_dir+"characters/"+_person.getString("imdb_id")+"_"+_person.getString("movie_imdb_id")+".jpg");
    }
  }

  PImage getImage(){
    return image;
  }

  PImage getImageCharacter(){
    return image_character;
  }

}
