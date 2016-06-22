/***********************************************************************
 Code based on:
 MSAFluid library (www.memo.tv/msafluid_for_processing)
 OpenCV library  (https://github.com/atduskgreg/opencv-processing)
 blobDetection library  (http://www.v3ga.net/processing/BlobDetection)
 
 
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
//import blobDetection.*;


final float FLUID_WIDTH = 140;

float mtTime = 60; //mirror total time. total time of the experience, until desappear
int pNum = 10;  //particles init per second. when using blobs
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

int numPixels;

boolean drawFluid = true;

PVector location;
PVector locationB; // to blob

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
int timeEllapsed;
float blend = 0.0009;

//1.0
//float[] Accel_x = { .1, -1, -20, 14, .1, 10, -1, 15};
//float[] Accel_y = { .1, -1, 10, -2, .1, -10, 1, 5};

//2.0
float[] Accel_x = {.4, .7, .1, -1, -.3, -.3, .1, -.2, .3, -.2, -.1, -.1};
float[] Accel_y = {.4, .7, .1, -1, -.5, -.3, .1, -.2, .3, -.1, -.2, -.3};
float [] FanProb = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

//3.0 to blob
//float[] Accel_x = {.004, .007, .01, -.01, -.014, -.005, .001, -.002, .005, -.002, -.001, -.003};
//float[] Accel_y = {.004, .007, .01, -.01, -.014, -.005, .001, -.002, .005, -.001, -.002, -.001};
//float [] FanProb = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

//int[] FanTimes = { 10, 20, 30, 35, 40, 50};
int[] FanTimes = {1, 5, 10, 15, 20, 25};

int[] FanOnPins = {24, 26, 28, 30, 32, 34, 24, 24, 24};
int[] FanOffPins = {24, 26, 28, 30, 32, 34, 24, 24, 24};

float totalAlive = 0;

int radius = 45;
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

//focus of forces array 
int w = 0;
int z = 2;
int k = 0;


float mouseNormX, mouseNormY;


//OpenCV
PImage copyImgCV;

//blob detection
//BlobDetection theBlobDetection;
//PImage imgBlob;
//Blob b;
//EdgeVertex eA, eB;


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


  //blob
//  imgBlob = createImage(screenWidth/10, screenHeight/10, ARGB);
//  theBlobDetection = new BlobDetection(imgBlob.width, imgBlob.height);
//  theBlobDetection.setPosDiscrimination(true);
//  theBlobDetection.setThreshold(0.2f); // will detect bright areas whose luminosity > 0.2f;
  

  liveCam = new Capture(this, screenWidth, screenHeight);
  liveCam.start();

  int opencvW = screenWidth/8;
  int opencvH = screenHeight/8;

  opencv = new OpenCV(this, screenWidth/8, screenHeight/8);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  location = new PVector(screenWidth/2, screenHeight/2);
  //locationB = new PVector(screenWidth/2, screenHeight/2); //to blob
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
  //fluidSolver.enableRGB(true).setFadeSpeed(0.0009).setDeltaT(0.15).setVisc(0.0001); //to blob

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

  //FanForcesX = 0;
  //FanForcesY = 0;

  //println("appState: " + appState);
  background(255, 255, 255);
  //timeEllapsed = millis();

  // do nothing if no camera yet
  if (liveCam.pixels.length <= 0 ) return;

  // load pixels so we can manipulate
  stillFrame.loadPixels();
  liveCam.loadPixels();


  // update fluid solver
  fluidSolver.update();


  // update fading in and out states
  //and reseting everything
  if (appState == STATE_FADE_OUT) {
    if (totalAlive == 0) {
      startDust = false;
      appState = STATE_FADE_BACK_IN;
      timeStartedFace = 0;
      timeLastNoFace = 0;      
        faceXOff = 0;
        faceYOff = 0;
        faceWOff = 0;
        faceHOff = 0;     
        FanForcesX = Accel_x[0];
        FanForcesY = Accel_y[0];  
        for (int j=0; j<11; j++) {  FanProb[j] = 0;  }
      turnOFF = true;
      println ("timeStartedFace reseting ", timeStartedFace);

      //for (int i=0; i < 5; i++) {
      if (bUseSerial == true && turnOFF == true) {
        myPort.write(0);
      }
      //}
    }
  }

  if (appState == STATE_FADE_BACK_IN) {
    for ( int i = 0; i < screenWidth*screenHeight; i++) {
      stillFrame.pixels[i] = color(255, 255, 255, alphaFade);
    }
    stillFrame.updatePixels();

    if (alphaFade < 255) alphaFade += 2;
    else { 
      println("ALPHA 100% ");
      appState = STATE_PARTICLES;
      turnOFF = false;
      timeStartedFace = millis();  //get this value and goes out from this loop;
      //restartTime = millis();
    }
    //println("STATE_FADE_BACK_IN " + alphaFade);
  }

  // fade out all image after mtTime - 5.0 seconds
  // and reset the Fan forces
  if (timeStartedFace>0 && (millis()-timeStartedFace)/1000.0 > mtTime *.80 && totalAlive > 100) { 
    if (alphaFade > 0) alphaFade -= 2;
    if (alphaFade < 10) appState = STATE_FADE_OUT;
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



  // resize camera and set opencv for face tracking...
  copyImgCV.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/8, screenHeight/8);
  opencv.loadImage(copyImgCV);
  faces = opencv.detect();

  //...and/or blob detection
//  imgBlob.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/10, screenHeight/10);
//  fastblur(imgBlob, 2);
//  theBlobDetection.computeBlobs(imgBlob.pixels);


  // find closest face to center and get its parameters
  int closestDist = width*height*1000; // hack to start with big distance

  for (int i = 0; i < faces.length; i++) {
    int d = (int)dist(faces[i].x *8, faces[i].y *8, width*.5, height*.5);
    int faceSize = faces[i].width*faces[i].height;

    if (d < closestDist && d < 400) {
      closestDist = d;
      PosFaceX = (faces[i].x - faces[i].width*.5) *8 ;
      PosFaceY = (faces[i].y - faces[i].height*.15)  *8  ;
      WidthFace = (faces[i].width+faces[i].width*1) *8;
      HeightFace = (faces[i].height+faces[i].height*.5) *8;
    }
  }

  // if there is at least 1 face, start dust and the fans
  if (faces.length > 0) { //If we have a face, trigger startDust and tells Arduino
    if (appState == STATE_PARTICLES) {
      // wait 5.0 seconds to start the dust effect
      if ( (millis()-timeStartedFace)/1000.0 > 10 ) {
        startDust = true;
        println("ROLOU ");
        //if (bUseSerial)  myPort.write('1');
        radius = 45;
        //pNum = 100;  //to blob
      }

      // check if this is a new face (no faces for more than 5 seconds or the first time ever)
      if (timeStartedFace == -1 || (timeStartedFace==0 && (millis()-timeLastNoFace)/1000.0 > 5)) { 
        println("NEW FACE ");
        timeStartedFace = millis();
        timeLastNoFace = 0;
        faceXOff = 0;
        faceYOff = 0;
        faceWOff = 0;
        faceHOff = 0;
        println ("timeStartedFace inside NewFace ", timeStartedFace);
      }
    }
  }
  else {
    // if no faces found turn off fans and particles slowly
    //if (bUseSerial)  myPort.write('0');

    radius = 0;
    //pNum = 0; //to blob

    // record the time we have no faces
    timeLastNoFace = millis();

    //need this????
    //  if ((millis()-timeLastNoFace)/1000.0 > 5) {
    //    timeStartedFace = 0;
    //    startDust = false;
    //  }
  }

  // update the perlin noise animator
    location.x = PosFaceX-faceXOff + map(noise(noff.x), 0, 1, 0, WidthFace+faceWOff);
    location.y = (PosFaceY-140)+faceYOff + map(noise(noff.y), 0, 1, 0, HeightFace+faceHOff);
    noff.add(0.2, 0.2, 0);
    
    mouseNormX = location.x * invWidth;
    mouseNormY = location.y * invHeight;


  //using blob edges  
//  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
//  {
//    b=theBlobDetection.getBlob(n);
//    for (int m=0; m<b.getEdgeNb(); m++)
//    {
//      eA = b.getEdgeVertexA(m);
//      eB = b.getEdgeVertexB(m);
//      if (eA !=null && eB !=null)
//      {
////        strokeWeight(3);
////        stroke(0, 255, 0);
////        line(eA.x*screenWidth, eA.y*screenHeight, eB.x*screenWidth, eB.y*screenHeight); 
//
//        location.x = eA.x*screenWidth;
//        location.y = eA.y*screenHeight;
//        mouseNormX = location.x * invWidth;
//        mouseNormY = location.y * invHeight;
//
//        locationB.x = eB.x*screenWidth;
//        locationB.y = eB.y*screenHeight;        
//        float lBx = locationB.x * invWidth;
//        float lBy = locationB.y * invHeight;
//
//        if (startDust)  addForce(mouseNormX, mouseNormY, FanForcesX, FanForcesY);
//        //if (startDust)  addForce(mouseNormX, mouseNormY, lBx, lBy);
//      }
//    }
//  }


  // adjust the area of the face tracking so perlin mover has larger area over time
  if (faces.length>0 && (millis()-timeStartedFace)/1000.0 > mtTime *.50) {
    // grow in y+height direction until reach the bottom
    if (faceHOff < height-250) {
      faceHOff += 2 *growing;
    }    
    if ( faceWOff < WidthFace*1.5) {
      faceWOff += .6 *growing;
      faceXOff = faceWOff*.6;
    }
  }

  /*
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
   */

  /********
   //preciso na verdade trocar a zona de interesse do array 
   //dependendo do tempo ou qtde de particulas, indo e voltando
   ********/

  //version 2.0

  //  if (totalAlive < 20000) {k=0; println (k);}
  //  else if (totalAlive > 20001 && totalAlive < 40000) {k=3; println (k);}
  //  else if (totalAlive > 40001) { k=6; println (k);}

  if (appState == STATE_PARTICLES) {
    if ((millis()-timeStartedFace)/1000.0 < mtTime *.25) { 
      k=0; 
      println (k);
    }
    else if ((millis()-timeStartedFace)/1000.0 > mtTime *.25 && (millis()-timeStartedFace)/1000.0 < mtTime *.50) { 
      k=3; 
      println (k);
    }
    else if ((millis()-timeStartedFace)/1000.0 > mtTime *.50 && (millis()-timeStartedFace)/1000.0 < mtTime *.75) { 
      k=6; 
      println (k);
    }
    else if ((millis()-timeStartedFace)/1000.0 > mtTime *.75) { 
      k=9; 
      println (k);
    }
  }

  // - by Ewan
  float pThresh = 100000;
  
  for (int i=w; i<z; i++) {
    FanProb[i] = totalAlive/pThresh;
    //println("Fan prob ", FanProb[i] );

    if (FanProb[i] > random(1.0) && random(20) > 19) {
      FanForcesX += blend*FanForcesX + (1-blend)*Accel_x[i];
      FanForcesY += blend*FanForcesY + (1-blend)*Accel_y[i];
      //    println("FanForcesX ", FanForcesX);
      //    println("FanForcesY ", FanForcesY);

      if (bUseSerial) {
        myPort.write(FanOnPins[i]);  
        println("Fan ", FanOnPins[i]);
      }
    }
  }
  println("Total Alive: ", totalAlive);

  // update the particles and create new
  if (startDust) {
    addForce(mouseNormX, mouseNormY, FanForcesX, FanForcesY); //FanForcesX and FanForcesY means the velocity and direction
    addForce(mouseNormX, mouseNormY+.15, FanForcesX, FanForcesY); //FanForcesX and FanForcesY means the velocity and direction
  }

  // reset totalAlive before making the check of all particles
  totalAlive = 0;


  // draw everything
  pushMatrix();  
    image(ourBackground, 0, 0);
    scale(-1, 1);
    translate(-screenWidth, 0);
    //    pushMatrix(); // use this for rotate the aspect ratio into vertical mode;
    //      scale(1.3, 1.3);
    //      translate(-220, 15);
    image(stillFrame, 0, 0);
    //if (mousePressed) saveFrame("data/savedBackground.jpg");
    //    noFill();
    //    rect(PosFaceX-faceXOff, (PosFaceY-50)+faceYOff, WidthFace+faceWOff, HeightFace+faceHOff);
    //    ellipse(location.x, location.y, 10, 10);
    //    ellipse(location.x, ( mouseNormY+.25)*screenHeight, 10, 10);
    if (startDust==true) particleSystem.updateAndDraw();
    //    popMatrix();
  popMatrix();

  //println(frameRate);

  //reset the fan forces each loop, after drawing them
  FanForcesX = Accel_x[k];
  FanForcesY = Accel_y[k];
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
  //to blob
  //float speed = (_FanForcesX * _FanForcesX  + _FanForcesY * _FanForcesY * aspectRatio2) /10;    // balance the x and y components of speed with the screen aspect ratio
  float speed = _FanForcesX * _FanForcesX  + _FanForcesY * _FanForcesY * aspectRatio2;    // balance the x and y components of speed with the screen aspect ratio

  if (speed > 0) {
    if (x<0) x = 0; 
    else if (x>1) x = 1;
    if (y<0) y = 0; 
    else if (y>1) y = 1;

    float velocityMult = 3.0f;
    //float velocityMult = .3f; //to blob

    int index = fluidSolver.getIndexForNormalizedPosition(x, y);

    //particleSystem.addParticles(x * screenWidth, y * screenHeight);
    particleSystem.addParticles(x * screenWidth, y * screenHeight, pNum);

    //_FanForcesX = (mouseX)/ ( width /5);  // _FanForcesX and dy means the velocity and direction
    //_FanForcesY = -((mouseY)/ ( height /5));  // _FanForcesY and dy means the velocity and direction

    fluidSolver.uOld[index] += _FanForcesX * velocityMult;
    fluidSolver.vOld[index] += _FanForcesY * velocityMult;
  }
}

void captureEvent(Capture c) {
  c.read();
}

