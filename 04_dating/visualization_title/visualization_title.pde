/*
 * Data-Driven DJ (https://datadrivendj.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This is a visualization of the song "Mixed Attraction"
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

// color palette
color bgColor = #262222;
color colorA = #262222;
color colorB = #382323;

// heart
PShape heart;
float pulse = 2000;
float minW = 500;
float maxW = 600;

// time
float startMs = 0;
float stopMs = 5000;
float elapsedMs = startMs;

void setup() {  
  // set the stage
  size(canvasW, canvasH);  
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(fps);
  smooth();
  noStroke();  
  background(bgColor);  
  heart = loadShape("heart.svg");
  heart.disableStyle();
  
  // noLoop();
}

void draw(){
  
  background(bgColor);
  shapeMode(CENTER);
  
  float percent_complete = (elapsedMs % pulse) / pulse;
  float radians = percent_complete * PI;
  float multiplier = sin(radians);
  float w = multiplier * (maxW - minW) + minW;
  color c = lerpColor(colorA, colorB, multiplier);
  
  fill(c);
  shape(heart, cx, cy, w, w);
  
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

