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
import blobDetection.*;
import codeanticode.syphon.*;

// syphon
PImage imgSyphon;
PGraphics canvas;
SyphonClient client;

final float FLUID_WIDTH = 100;

float mtTime = 60; //mirror total time. total time of the experience, until desappear
int pNum = 25;  //particles init per second. when using blobs
boolean useBlobs = false;
boolean bUseSerial = true;  // use or not the serial port to control the Arduino
boolean bRotate90 = false;
boolean bWebcam = true;
boolean bSyphon = false;
boolean bPrintRectFaces = true;

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

//int screenWidth = 720; 
//int screenHeight = 1280;
int screenWidth = 1280; 
int screenHeight = 720;
// syphon canon
//int screenWidth = 1056; 
//int screenHeight = 704;

Capture liveCam;

PImage ourBackground;
PImage stillFrame; //particles comes from here
PVector noff;

boolean setOnce = false;
boolean startDust = false;


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
float[] Accel_x = { .2, .1, .1, -.3, -.2, -.14, .1, -.3, .2, -.02, -.01, -.01 };
float[] Accel_y = { .2, .1, .1, -.3, -.35, -.14, .1, -.3, .2, -.01, -.1, -.1 };
float [] FanProb = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

//3.0 to blob
//float[] Accel_x = {.004, .007, .01, -.01, -.014, -.005, .001, -.002, .005, -.002, -.001, -.003};
//float[] Accel_y = {.004, .007, .01, -.01, -.014, -.005, .001, -.002, .005, -.001, -.002, -.001};
//float [] FanProb = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

//int[] FanTimes = { 10, 20, 30, 35, 40, 50};
//int[] FanTimes = {1, 5, 10, 15, 20, 25};

//int[] FanOnPins = {24, 26, 28, 30, 32, 34, 24, 24, 24};
//int[] FanOffPins = {24, 26, 28, 30, 32, 34, 36, 24, 24};
int[] FanOnPins = { 0, 1, 2, 3, 4, 5, 6, 7, 8 };

float totalAlive = 0;

int radius = 30;
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


//focus of forces array 
int w = 0;
int z = 2;
int k = 0;

//OpenCV
PImage copyImgCV;

//blob detection
BlobDetection theBlobDetection;
PImage imgBlob;
Blob b;
EdgeVertex eA, eB;



void setup() {
  size(screenWidth, screenHeight, P3D);    // use OPENGL rendering for bilinear filtering on texture
  //size(720, 1280, P3D);  // size of the camera
  //size(704, 1056, P3D);  // canon syphon

  if (bSyphon) client = new SyphonClient(this);  

  if (bUseSerial) {
    String portName = Serial.list()[1];
    myPort = new Serial(this, portName, 9600);
  }

  stillFrame = createImage(screenWidth, screenHeight, ARGB);
  ourBackground = createImage(screenWidth, screenHeight, ARGB);
  ourBackground = loadImage("savedBackground.jpg"); 

  copyImgCV = createImage(screenWidth/8, screenHeight/8, ARGB);

  //blob
  imgBlob = createImage(screenWidth/8, screenHeight/8, ARGB);
  theBlobDetection = new BlobDetection(imgBlob.width, imgBlob.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(0.2f); // will detect bright areas whose luminosity > 0.2f;

  if (bWebcam) {
    String[] cameras = {"FaceTime HD Camera", "HP Webcam HD-4110", "Venus USB2.0 Camera"};
    liveCam = new Capture(this, screenWidth, screenHeight, cameras[0], 30);
    liveCam.start();
  }

  opencv = new OpenCV(this, screenWidth/8, screenHeight/8);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  location = new PVector(screenWidth/2, screenHeight/2);
  locationB = new PVector(screenWidth/2, screenHeight/2); //to blob
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
}


void draw() {
  //println("appState: " + appState);
  
  if (bWebcam) {
    // do nothing if no camera yet  
    if (liveCam.pixels.length <= 0 ) return;
  }

  if (bSyphon) {
    // do nothing if no syphon client yet  
    if (!client.available()) return;
  }
  
   if (bSyphon) imgSyphon = client.getImage(imgSyphon); // load the pixels array with the updated image info (slow)
// if (bSyphon) imgSyphon = client.getImage(imgSyphon, false); // does not load the pixels array (faster)

  // load pixels so we can manipulate
  if (bSyphon) imgSyphon.loadPixels();
  stillFrame.loadPixels();
  if (bWebcam) liveCam.loadPixels();


  // update fluid solver
  fluidSolver.update();


  // update fading in and out states
  // and reseting everything
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
      useBlobs = false;  // to blob
      //println ("timeStartedFace reseting ", timeStartedFace);
    }
    
  }


  if (appState == STATE_FADE_BACK_IN) {

    for ( int i = 0; i < screenWidth*screenHeight; i++) {
      stillFrame.pixels[i] = color(255, 255, 255, alphaFade);
    }
    stillFrame.updatePixels(); 

    if (alphaFade < 255) alphaFade += 2;
    else { 
      //println("ALPHA 100% ");
      appState = STATE_PARTICLES;
      FanForcesX = Accel_x[0];
      FanForcesY = Accel_y[0];
    }
    
  }


  // fade out all image after 80% of mtTime
  if (timeStartedFace>0 && (millis()-timeStartedFace)/1000.0 > mtTime *.80 && totalAlive > 100) {
    if (alphaFade > 10) {
      alphaFade -= 2;
      if (bUseSerial) myPort.write('f');
    }
    if (alphaFade < 10) {
      alphaFade -= 2;
      appState = STATE_FADE_OUT;
      if (bUseSerial)  myPort.write('o');
    }
  }

  if (bWebcam) {
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
  }
  
  if (bSyphon) {
    //println("OPAAAA");
    // setting the overlay image values to syphon camera when not faded out already
    for ( int i = 0; i < screenWidth*screenHeight; i++) {
      color c = stillFrame.pixels[i];
      if ( alpha(c) > 0 ) {
  
        color c2 = imgSyphon.pixels[i];
        float c3R = c2 >> 16 & 0xFF;
        float c3G = c2 >> 8 & 0xFF;
        float c3B = c2 & 0xFF;
        color c3 = color(c3R, c3G, c3B, alphaFade);
  
        stillFrame.pixels[i] = c3;
      }
    }
  }
  
  stillFrame.updatePixels();
  if (bSyphon) imgSyphon.updatePixels();


  // resize camera and set opencv for face tracking...
  if (bWebcam) copyImgCV.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/8, screenHeight/8);
  if (bSyphon) copyImgCV.copy(imgSyphon, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/8, screenHeight/8);
  opencv.loadImage(copyImgCV);
  faces = opencv.detect();


  //...and/or blob detection
  if (bWebcam) imgBlob.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/8, screenHeight/8);
  if (bSyphon) imgBlob.copy(imgSyphon, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/8, screenHeight/8);
  fastblur(imgBlob, 2);
  theBlobDetection.computeBlobs(imgBlob.pixels);

  
  // find closest face to center and get its parameters
  int closestDist = screenWidth*screenHeight *1000; // hack to start with big distance
//  int closestDist = width*height*1000; // hack to start with big distance

  for (int i = 0; i < faces.length; i++) {
    int d = (int)dist(faces[i].x *8, faces[i].y *8, screenWidth*.5, screenHeight*.5);
//  int d = (int)dist(faces[i].x *8, faces[i].y *8, width*.5, height*.5);
    int faceSize = faces[i].width *faces[i].height;

    if (d < closestDist && d < 400) {
      closestDist = d;
      PosFaceX = (faces[i].x - faces[i].width*.5) *8;
      PosFaceY = (faces[i].y - faces[i].height*.15)  *8;
      WidthFace = (faces[i].width+faces[i].width*1) *8;
      HeightFace = (faces[i].height+faces[i].height*.5) *8;
    }
  }

  //  // find faces and get its parameters
  //  for (int i = 0; i < faces.length; i++) {
  //    PosFaceX = (faces[i].x - faces[i].width*.5) *8;
  //    PosFaceY = (faces[i].y - faces[i].height*.15)  *8;
  //    WidthFace = (faces[i].width+faces[i].width*1) *8;
  //    HeightFace = (faces[i].height+faces[i].height*.5) *8;
  //  }


  // if there is at least 1 face, start dust and the fans
  if (faces.length > 0) {
  
    //println("timeStartedFace: ", timeStartedFace);    
    if (appState == STATE_PARTICLES) {
      // wait 5.0 seconds to start the dust effect
      if ( (millis()-timeStartedFace)/1000.0 > 5 ) {
        startDust = true;
        //if (bUseSerial)  myPort.write('1');  // turn on everything if there is a face and particles
        radius = 30;
        pNum = 50;  //to blob
      }

      // check if this is a new face (no faces for more than 5 seconds or the first time ever)
      if (timeStartedFace == -1 || (timeStartedFace==0 && (millis()-timeLastNoFace)/1000.0 > 5)) {
        timeStartedFace = millis();
        timeLastNoFace = 0;
        faceXOff = 0;
        faceYOff = 0;
        faceWOff = 0;
        faceHOff = 0;
        println ("timeStartedFace inside NewFace ", timeStartedFace);
        // set the 1st fan on, acordinly with the 1st force of particles
        if (bUseSerial) myPort.write(FanOnPins[0]);
        
        //appState = STATE_FADE_BACK_IN;        
        println ("appState: ", appState);
      }
    }
    
   } else {
      // if no faces found turn off s and particles slowly
      radius = 0;
      pNum = 0; //to blob
      // record the time we have no faces
//      if (appState == STATE_PARTICLES)  timeLastNoFace = millis();  
      timeLastNoFace = millis();   
      
//      if (timeStartedFace>0 && (millis()-timeLastNoFace)/1000.0 > 5) { 
//        appState = STATE_FADE_OUT;   
//        println ("appState: ", appState);
//      }
   }

  // update the perlin noise animator
  //    location.x = PosFaceX-faceXOff + map(noise(noff.x), 0, 1, 0, WidthFace+faceWOff);
  //    location.y = (PosFaceY-140)+faceYOff + map(noise(noff.y), 0, 1, 0, HeightFace+faceHOff);
  location.x = (PosFaceX-faceXOff + map(noise(noff.x), 0, 1, 0, WidthFace+faceWOff)) *invWidth;
  location.y = ((PosFaceY-140)+faceYOff + map(noise(noff.y), 0, 1, 0, HeightFace+faceHOff)) *invHeight;
  noff.add(0.2, 0.2, 0);


  // after 40% of time, adjust the area of the face tracking so perlin mover has larger area over time and starts using blobs
   if (appState == STATE_PARTICLES) {
       if (faces.length>0 && (millis()-timeStartedFace)/1000.0 > mtTime *.40) { 
        // grow in y+height direction until reach the bottom
        if (faceHOff < screenHeight-50) {
          faceHOff += 8 *growing;
        }    
        if ( faceWOff < WidthFace*1.5) {
          faceWOff += .6 *growing;
          faceXOff = faceWOff*.6;
        }
      } // if no face for 10seconds or at beginnig of time, reset the tracking face position
//      else {//if ((millis()-timeLastNoFace)/1000.0 > 5) {
//        faceXOff = 0;
//        faceYOff = 0;
//        faceWOff = 0;
//        faceHOff = 0;
//      }
   }

  //start using blobs after the 50% mark and before the 74%
  if (timeStartedFace>0 && (millis()-timeStartedFace)/1000.0 > mtTime *.50 && (millis()-timeStartedFace)/1000.0 < mtTime *.74) {
    useBlobs = true;  // to blob
    println("BLOOOOB");
  }

  //stop using blobs after the 74% mark
  if (timeStartedFace>0 && (millis()-timeStartedFace)/1000.0 > mtTime *.74 && totalAlive > 100) {
    useBlobs = false;  // to blob
    println("STOOOOOP BLOOOOB");
  }



  // doing some things w fans need to check it out
  //   // version 1.0
  //   for (int i=0; i < 5; i++) {
  //     int timeSinceRestart = millis() - restartTime;
  //     //if (timeEllapsed/1000 > FanTimes[i] && timeEllapsed/1000 < FanTimes[i+1]) {
  //     if ((timeEllapsed-restartTime)/1000.0 > FanTimes[i] && (timeEllapsed-restartTime)/1000.0 < FanTimes[i+1]) {
  //       FanForcesX = Accel_x[i];
  //       FanForcesY = Accel_y[i];
  //       if (timeEllapsed/1000 > FanTimes[5]) {
  //         timeEllapsed = 0;
  //         // turnOFF = true;
  //       }
  //       if (bUseSerial == true && turnOFF == false) {
  //         myPort.write(FanOnPins[i]);  
  //         //println("Fan ", FanOnPins[i]);
  //       }
  //     }
  //   }
  //   println("turnOff val " + turnOFF);
  //   

  /////////
  //preciso na verdade trocar a zona de interesse do array 
  //dependendo do tempo ou qtde de particulas, indo e voltando
  /////////


  //version 2.0
  //if (appState == STATE_PARTICLES) {
  if (timeStartedFace > 0 && (millis()-timeStartedFace)/1000.0 < mtTime *.3) { k=0; }// println (k);  } 
  else if (timeStartedFace > 0 && (millis()-timeStartedFace)/1000.0 > mtTime *.3 && (millis()-timeStartedFace)/1000.0 < mtTime *.55) { k=3; }// println (k);  } 
  else if (timeStartedFace > 0 && (millis()-timeStartedFace)/1000.0 > mtTime *.55 && (millis()-timeStartedFace)/1000.0 < mtTime *.8) { k=6; }// println (k);  } 
  else if (timeStartedFace > 0 && (millis()-timeStartedFace)/1000.0 > mtTime *.8) { k=9; }// println (k); }
  //}

  float pThresh = 150000;


  if (appState == STATE_PARTICLES) {
    for (int i=w+k; i<=z+k; i++) {
      FanProb[i] = totalAlive/pThresh;
      //println("Fan prob ", FanProb[i] );
      // - by Ewan
      if (FanProb[i] > random(1.0) && random(20) > 19) {
        //FanForcesX += blend*FanForcesX + (1-blend)*Accel_x[i];
        //FanForcesY += blend*FanForcesY + (1-blend)*Accel_y[i];
        FanForcesX = Accel_x[i];
        FanForcesY = Accel_y[i];
        //println("FanForcesX ", FanForcesX);
        //println("FanForcesY ", FanForcesY);
  
        if (bUseSerial && k < 9) {
          myPort.write(FanOnPins[i]);
          //println("Fan ", FanOnPins[i]);
        }
      }    
    }
  }
  //println("Total Alive: ", totalAlive);


  //using blob edges  
  for (int n=0; n<theBlobDetection.getBlobNb (); n++) {
    b=theBlobDetection.getBlob(n);
    for (int m=0; m<b.getEdgeNb (); m++)
    {
      eA = b.getEdgeVertexA(m);
      eB = b.getEdgeVertexB(m);
      if (eA !=null && eB !=null)
      {
        //strokeWeight(3);
        //stroke(0, 255, 0);
        //line(eA.x*screenWidth , eA.y*screenHeight , eB.x*screenWidth , eB.y*screenHeight ); 

        locationB.x = eA.x *screenWidth *invWidth;
        locationB.y = eA.y *screenHeight *invHeight;
        //locationB.x = eA.x *screenWidth ;
        //locationB.y = eA.y *screenHeight ;   

        if (startDust && useBlobs)  addForceBlobs(locationB.x, locationB.y, FanForcesX/15, FanForcesY/15);
      }
    }
    
  }


  // update the particles and create new
  if (startDust==true) {
    addForce(location.x, location.y, FanForcesX, FanForcesY); //FanForcesX and FanForcesY means the velocity and direction
    addForce(location.x+.02, location.y+.20, FanForcesX, FanForcesY); 
    addForce(location.x-.04, location.y+.40, FanForcesX, FanForcesY); 
    //addForce(mouseNormX, mouseNormY, FanForcesX, FanForcesY); 
  }


  // reset totalAlive before making the check of all particles
  totalAlive = 0;

  //  // draw everything
  //  pushMatrix();  
  //    image(ourBackground, 0, 0);
  //    scale(-1, 1);
  //    translate(-screenWidth, 0);
  //    pushMatrix(); // use this for rotate the aspect ratio into vertical mode;
  //      scale(1.3, 1.3);
  //      translate(-220, 15);
  //      image(stillFrame, 0, 0);
  //        if (mousePressed) saveFrame("data/savedBackground.jpg");
  //  //    noFill();
  //  //    rect(PosFaceX-faceXOff, (PosFaceY-50)+faceYOff, WidthFace+faceWOff, HeightFace+faceHOff);
  //  //    ellipse(location.x, location.y, 10, 10);
  //  //    ellipse(location.x, ( mouseNormY+.25)*screenHeight, 10, 10);
  //      if (startDust==true) particleSystem.updateAndDraw();
  //    popMatrix();
  //popMatrix();


  //  pushMatrix();  
  //    scale(-1, 1);
  //    translate(-screenWidth+150, 0);
  //  //    image(ourBackground, 0, 0);
  //  //      pushMatrix(); // use this for rotate the aspect ratio into vertical mode;
  //        scale(1.6, 1.6);
  //        translate(-160, 0);
  //        image(ourBackground, 0, 0);
  //        image(stillFrame, 0, 0);
  //        if (startDust==true) particleSystem.updateAndDraw();
  //  //     popMatrix();
  //    popMatrix();

  pushMatrix();  
    scale(-1, 1);
    translate(-screenWidth, 0);
    background(0, 0, 0);
    
    image(ourBackground, 0, 0);
    image(stillFrame, 0, 0);
            if (mousePressed) saveFrame("data/savedBackground.jpg");
    
    if (bPrintRectFaces) {
      //fill(255);
      noStroke();
      for (int i = 0; i < faces.length; i++)  rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
      noFill();
      rect(PosFaceX-faceXOff, (PosFaceY-50)+faceYOff, WidthFace+faceWOff, HeightFace+faceHOff);
    }
    
    if (startDust==true) particleSystem.updateAndDraw();
  popMatrix();

  //println(frameRate);

  //reset the fan forces each loop, after drawing them
  //FanForcesX = Accel_x[0];
  //FanForcesY = Accel_y[0];
  
}//draw


// add force and dye to fluid, and create particles
void addForce(float x, float y, float _FanForcesX, float _FanForcesY) {

  // balance the x and y components of speed with the screen aspect ratio
  float speed = _FanForcesX * _FanForcesX  + _FanForcesY * _FanForcesY * aspectRatio2;    
  if (speed > 0) {
    if (x<0) x = 0; 
    else if (x>1) x = 1;
    if (y<0) y = 0; 
    else if (y>1) y = 1;

    float velocityMult = 3.0f;
    int index = fluidSolver.getIndexForNormalizedPosition(x, y);

    particleSystem.addParticles(x *screenWidth, y *screenHeight);

    //_FanForcesX = (mouseX)/ ( width /5);  // _FanForcesX and dy means the velocity and direction
    //_FanForcesY = -((mouseY)/ ( height /5));  // _FanForcesY and dy means the velocity and direction
    fluidSolver.uOld[index] += _FanForcesX * velocityMult;
    fluidSolver.vOld[index] += _FanForcesY * velocityMult;
  }
}


// add force to blobs
void addForceBlobs(float x, float y, float _FanForcesX, float _FanForcesY) {

  // balance the x and y components of speed with the screen aspect ratio
  float speed = _FanForcesX * _FanForcesX  + _FanForcesY * _FanForcesY * aspectRatio2;    
  if (speed > 0) {
    if (x<0) x = 0; 
    else if (x>1) x = 1;
    if (y<0) y = 0; 
    else if (y>1) y = 1;
    float velocityMult = 1.3f;
    int index = fluidSolver.getIndexForNormalizedPosition(x, y);

    particleSystem.addParticlesBlobs(x *screenWidth, y *screenHeight, pNum);

    fluidSolver.uOld[index] += _FanForcesX * velocityMult;
    fluidSolver.vOld[index] += _FanForcesY * velocityMult;
  }
}



void keyPressed() {
  switch(key) {
  case 'r':
    renderUsingVA ^= true; 
    //println("renderUsingVA: " + renderUsingVA);
    break;

  case 'b':
    //CopyBG = true;
    //if (bWebcam) ourBackground.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth, screenHeight);
    //if (bSyphon) ourBackground.copy(imgSyphon, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth, screenHeight);
    ourBackground.copy(stillFrame, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth, screenHeight);
    ourBackground.save("data/savedBackground.jpg");
    break;

  case '1':
    ourBackground.save("data/savedBackground.jpg");
    //saveFrame("data/savedBackground.jpg");
    break;
  }
}


void captureEvent(Capture c) {
  c.read();
}

