/***********************************************************************
Code based on MSAFluid library (www.memo.tv/msafluid_for_processing)

Developed by:
Rafael SKi - promoter
Won Jik Yang - colaborator
Chris Sugrue - Mentor

 
/***********************************************************************
 
 Copyright (c) 2008, 2009, Memo Akten, www.memo.tv
 *** The Mega Super Awesome Visuals Company ***
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of MSA Visuals nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
 * ***********************************************************************/
import gab.opencv.*;
import processing.video.*;
import processing.serial.*;
import msafluid.*;
import java.awt.*;
import javax.media.opengl.GL2;


final float FLUID_WIDTH = 180;

boolean bUseSerial = false;  // use or not the serial port to control the Arduino

float invWidth, invHeight;    // inverse of screen dimensions
float aspectRatio, aspectRatio2;

MSAFluidSolver2D fluidSolver;
ParticleSystem particleSystem;
//FanForces fanforces;
OpenCV opencv;
Serial myPort;
Rectangle[] faces;

PImage imgFluid;

PImage copyImgCV;
int numPixels;

boolean drawFluid = true;

PVector location;

int screenWidth = 1280; 
int screenHeight = 720;

Capture liveCam;

PImage ourBackground;
PImage stillFrame; //particles comes from here
PVector noff;

boolean setOnce = false;
boolean startDust = false;

boolean turnOFF = false;

// Face Tracking
float PosFaceX, PosFaceY, WidthFace, HeightFace;

float faceXOff = 0;
float faceYOff = 0;
float faceWOff = 0;
float faceHOff = 0;
float growing = .8;


float FanForcesX, FanForcesY;
float[] Accel_x = { .1, -1, -20, 14, .1, 10, -1, 15};
float[] Accel_y = { .1, -1, 10, -2, .1, -10, 1, 5};
int timeEllapsed;

//2.0
//float[] Accel_x = {15, -15, -20, 14, .1, 10};
//float[] Accel_y = {13, 13, 10, -2, .1, 10};
//float [] FanProb = {0,0,0,0,0,0};

//int[] FanTimes = { 10, 20, 30, 35, 40, 50};
int[] FanTimes = { 1, 5, 10, 15, 20, 25};

int[] FanOnPins = { 24, 26, 28, 30, 32, 34};
int[] FanOffPins = { 24, 26, 28, 30, 32, 34};


float totalAlive = 0;

int radius = 60;
float timeStartedFace = -1;
float timeLastNoFace = 0;
float alphaFade = 255;

// not using all yet
int STATE_PARTICLES = 0;
int STATE_ALL_DEAD = 1;
int STATE_FADE_BACK_IN = 2;
int STATE_FADE_OUT = 3;
int STATE_NOBODY_HERE = 4;
int appState = 0;
int restartTime;

void setup() {
  //size(screenWidth, screenHeight, P3D);    // use OPENGL rendering for bilinear filtering on texture
  size(1152, 768, P3D);  // size of the camera

  if (bUseSerial) {
    String portName = Serial.list()[2];
    myPort = new Serial(this, portName, 9600);
  }

  stillFrame = createImage(screenWidth, screenHeight, ARGB);
  ourBackground = createImage(screenWidth, screenHeight, RGB);
  ourBackground = loadImage("savedBackground.jpg"); 

  copyImgCV = createImage(screenWidth/8, screenHeight/8, ARGB);

  liveCam = new Capture(this, screenWidth, screenHeight);
  liveCam.start();

  int opencvW = screenWidth/8;
  int opencvH = screenHeight/8;

  opencv = new OpenCV(this, screenWidth/8, screenHeight/8);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  location = new PVector(screenWidth/2, screenHeight/2);
  noff = new PVector(random(1000), random(1000));

  FanForcesX = Accel_x[0];
  FanForcesY = Accel_y[0];

  invWidth = 1.0f/screenWidth;
  invHeight = 1.0f/screenHeight;
  aspectRatio = screenWidth * invHeight;
  aspectRatio2 = aspectRatio * aspectRatio;

  // create fluid and set options
  fluidSolver = new MSAFluidSolver2D((int)(FLUID_WIDTH), (int)(FLUID_WIDTH * screenHeight/screenWidth));
  fluidSolver.enableRGB(true).setFadeSpeed(0.003).setDeltaT(0.5).setVisc(0.0001);

  // create image to hold fluid picture
  imgFluid = createImage(fluidSolver.getWidth(), fluidSolver.getHeight(), RGB);

  // create particle system
  particleSystem = new ParticleSystem();

  stillFrame.loadPixels();
  for ( int i = 0; i < screenWidth*screenHeight; i++) {
    stillFrame.pixels[i] = color(255, 255, 255, 255);
  }
  stillFrame.updatePixels();
  
  restartTime = millis();
}


void draw() {
  println("appState: " + appState);
  background(255, 255, 255);
  timeEllapsed = millis();

  // do nothing if no camera yet
  if (liveCam.pixels.length <= 0 ) return;

  // load pixels so we can manipulate
  stillFrame.loadPixels();
  liveCam.loadPixels();


  // update fluid solver
  fluidSolver.update();


  // update fading in and out states
  if (totalAlive == 0) {
    startDust = false;
    appState = STATE_FADE_BACK_IN;
    timeStartedFace = 0;
    timeLastNoFace = 0;
    turnOFF = true;
     
    //for (int i=0; i < 5; i++) {
    if (bUseSerial == true && turnOFF == true) {
      myPort.write(0);    
    }
    //}
    
  }


  if (appState == STATE_FADE_BACK_IN) {
    for ( int i = 0; i < screenWidth*screenHeight; i++) {
      stillFrame.pixels[i] = color(255, 255, 255, alphaFade);
    }
    stillFrame.updatePixels();
     
    if (alphaFade < 255) alphaFade += 2;
    else { 
      appState = STATE_PARTICLES;
      startDust = true;
      turnOFF = false;
      restartTime = millis();
    }
    //println("STATE_FADE_BACK_IN " + alphaFade);
  }

  // fade out all image after 30 seconds
  // and turn off all the fans  
  if (timeStartedFace>0 && (millis()-timeStartedFace)/1000.0 > 30 && totalAlive > 100) { 
    if (alphaFade > 0) alphaFade -= 2;   
  }


  // setting the overlay image values to live camera when not faded out already
  for ( int i = 0; i < screenWidth*screenHeight; i++) {
    color c = stillFrame.pixels[i];
    if ( alpha(c) > 0 ) {

      color c2 = liveCam.pixels[i];
      float c3R = c2 >> 16 & 0xFF;
      float c3G = c2 >> 8 & 0xFF;
      float c3B = c2 & 0xFF;
      color c3 = color(c3R, c3G, c3B, alphaFade);

      stillFrame.pixels[i] = c3;
    }
  }
  stillFrame.updatePixels();



  // resize camera and set opencv for face tracking
  copyImgCV.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/8, screenHeight/8);
  opencv.loadImage(copyImgCV);
  faces = opencv.detect();

  // find closest face to center and get its parameters
  int closestDist = width*height*1000; // hack to start with big distance

  for (int i = 0; i < faces.length; i++) {
    int d = (int)dist(faces[i].x * 8, faces[i].y  * 8, width*.5, height*.5);
    int faceSize = faces[i].width*faces[i].height;
    if (d < closestDist && d < 400) {
      closestDist = d;
      PosFaceX = (faces[i].x - faces[i].width*.5) * 8 ;
      PosFaceY = (faces[i].y - faces[i].height*.15)  * 8  ;
      WidthFace = (faces[i].width+faces[i].width*1) * 8;
      HeightFace = (faces[i].height+faces[i].height*.5) * 8;
    }
  }

  // if there is at least 1 face, start dust and the fans
  if (faces.length > 0) { //If we have a face, trigger startDust and tells Arduino

    if ( appState == STATE_PARTICLES) {
      startDust = true; 
      //if (bUseSerial)  myPort.write('1');
      radius = 60;
    }

    // check if this is a new face (no faces for more than 5 seconds or the first time ever)
    if (timeStartedFace == -1 || (timeStartedFace==0 && (millis()-timeLastNoFace)/1000.0 > 5)) { 
      //println("NEW FACE ");
      timeStartedFace = millis();
      timeLastNoFace = 0;
      faceXOff = 0;
      faceYOff = 0;
      faceWOff = 0;
      faceHOff = 0;
    }
  }
  else {

    // if no faces found turn off fans and particles slowly
    //if (bUseSerial)  myPort.write('0');
    radius = 0;

    // record the time we have no faces
    timeLastNoFace = millis();
    // need this????
    //    if ((millis()-timeLastNoFace)/1000.0 > 5) {
    //      timeStartedFace = 0;
    //    }
  }

  // update the perlin noise animator
  location.x = PosFaceX-faceXOff + map(noise(noff.x), 0, 1, 0, WidthFace+faceWOff);
  location.y = (PosFaceY-50)+faceYOff + map(noise(noff.y), 0, 1, 0, HeightFace+faceHOff);
  noff.add(0.18, 0.18, 0);

  float mouseNormX = location.x * invWidth;
  float mouseNormY = location.y * invHeight;

  // adjust the area of the face tracking so perlin mover has larger area over time
  if (faces.length>0 && (millis()-timeStartedFace)/1000.0 > 20) {
    // grow in y+height direction until reach the bottom
    if (faceHOff < height-250) {
      faceHOff += 2 *growing;
    }    
    if ( faceWOff < WidthFace*1.5) {
      faceWOff += .5 *growing;
      faceXOff = faceWOff*.5;
    }
  }


  // doing some things w fans need to check it out
  // version 1.0
  for (int i=0; i < 5; i++) {
    int timeSinceRestart = millis() - restartTime;
    //if (timeEllapsed/1000 > FanTimes[i] && timeEllapsed/1000 < FanTimes[i+1]) {
      if ((timeEllapsed-restartTime)/1000.0 > FanTimes[i] && (timeEllapsed-restartTime)/1000.0 < FanTimes[i+1]) {
        FanForcesX = Accel_x[i];
        FanForcesY = Accel_y[i];
     
      if (timeEllapsed/1000 > FanTimes[5]) {
        timeEllapsed = 0;
       // turnOFF = true;
      }  
      
      if (bUseSerial == true && turnOFF == false) {
        myPort.write(FanOnPins[i]);  
        //println("Fan ", FanOnPins[i]);
      }
    }
  }
  
  println("turnOff val " + turnOFF);
  /*
  //version 2.0 - Ewan
   float pThresh = 50000, blend = 0.9;
   // doing some things w fans need to check it out
   for (int i=0; i < 5; i++) {
   FanProb[i] = totalAlive/pThresh;
   //println("Fan prob ", FanProb[i] );
   
   if(FanProb[i] > random(1.0)) {
   FanForcesX += blend*FanForcesX + (1-blend)*Accel_x[i];
   FanForcesY += blend*FanForcesY + (1-blend)*Accel_y[i];
   
   if (bUseSerial) {
   myPort.write(FanOnPins[i]);  
   println("Fan ", FanOnPins[i]);    
   }
   }
   }
   */

  // update the particles and create new
  if (startDust) {
    addForce(mouseNormX, mouseNormY, FanForcesX, FanForcesY); //FanForcesX and FanForcesY means the velocity and direction
    addForce(mouseNormX, mouseNormY+.25, FanForcesX, FanForcesY); //FanForcesX and FanForcesY means the velocity and direction
  }

  // reset totalAlive before making the check of all particles
  totalAlive = 0;

  // draw everything
  pushMatrix();  
    image(ourBackground, 0, 0);
    scale(-1, 1);
    translate(-screenWidth, 0);
    pushMatrix(); // use this for rotate the aspect ratio into vertical mode;
      scale(1.3, 1.3);
      translate(-220, 15);
      image(stillFrame, 0, 0);
        if (mousePressed) saveFrame("data/savedBackground.jpg");
  //    noFill();
  //    rect(PosFaceX-faceXOff, (PosFaceY-50)+faceYOff, WidthFace+faceWOff, HeightFace+faceHOff);
  //    ellipse(location.x, location.y, 10, 10);
  //    ellipse(location.x, ( mouseNormY+.25)*screenHeight, 10, 10);
      if (startDust==true) particleSystem.updateAndDraw();
    popMatrix();
  popMatrix();
}


void keyPressed() {
  switch(key) {
  case 'r':
    renderUsingVA ^= true; 
    println("renderUsingVA: " + renderUsingVA);
    break;

  case 'b':
    //CopyBG = true;
    ourBackground.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth, screenHeight);
    break;

  case '1':
    ourBackground.save("data/savedBackground.jpg");
    //saveFrame("data/savedBackground.jpg");
    break;
  }
}


// add force and dye to fluid, and create particles
void addForce(float x, float y, float _FanForcesX, float _FanForcesY) {
  float speed = _FanForcesX * _FanForcesX  + _FanForcesY * _FanForcesY * aspectRatio2;    // balance the x and y components of speed with the screen aspect ratio

  if (speed > 0) {
    if (x<0) x = 0; 
    else if (x>1) x = 1;
    if (y<0) y = 0; 
    else if (y>1) y = 1;

    float colorMult = 5;
    float velocityMult = 3.0f;

    int index = fluidSolver.getIndexForNormalizedPosition(x, y);

    particleSystem.addParticles(x * screenWidth, y * screenHeight);

    //_FanForcesX = (mouseX)/ ( width /5);  // _FanForcesX and dy means the velocity and direction
    //_FanForcesY = -((mouseY)/ ( height /5));  // _FanForcesY and dy means the velocity and direction

    fluidSolver.uOld[index] += _FanForcesX * velocityMult;
    fluidSolver.vOld[index] += _FanForcesY * velocityMult;
  }
}

void captureEvent(Capture c) {
  c.read();
}

