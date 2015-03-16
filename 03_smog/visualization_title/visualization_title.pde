/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Air Play"
 */
 
// output
int fps = 30;
String outputFrameFile = "output/frames/frames-#####.png";
boolean captureFrames = false;

// resolution
int canvasW = 1280;
int canvasH = 720;

// color palette
color bgColor = #262222;
color particleColor = #3f3a3a;

// time
float startMs = 0;
float stopMs = 5000;
float elapsedMs = startMs;

// particles
int particleCount = 400;
ArrayList<Particle> particles = new ArrayList<Particle>();
float particleW = 12;
float particleMoveUnit = 1;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();  
  background(bgColor); 
  fill(particleColor);
  
  // create particles
  for (int i = 0; i < particleCount; i++) {
    particles.add(new Particle(random(0, canvasW), random(0, canvasH), random(1, 360)));
  }
  
  // noLoop();
}

void draw(){
  
  background(bgColor);
  
  for (int i = 0; i < particleCount; i++) {
    Particle p = particles.get(i);
    ellipse(p.getX(), p.getY(), particleW, particleW);
    p.move(particleMoveUnit);
  }
  
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

float[] translatePoint(float x, float y, float angle, float distance){
  float[] newPoint = new float[2];
  float r = radians(angle);
  
  newPoint[0] = x + distance*cos(r);
  newPoint[1] = y + distance*sin(r);
  
  return newPoint;
}

class Particle
{
  float x, y, a;
  
  Particle(float _x, float _y, float _angle){
    x = _x;
    y = _y;
    a = _angle;
  }
  
  float getX(){
    return x;
  }
  
  float getY(){
    return y;
  }
  
  void move(float distance) {
    float[] p = translatePoint(x, y, a, distance);
    if (p[1] < 0) {
      a = random(180, 360);
    } else if (p[0] < 0 || p[1] < 0 || p[0] > canvasW || p[1] > canvasH) {
      a = random(0, 180);
    } else {
      x = p[0];
      y = p[1];
    }    
  } 
  
}

