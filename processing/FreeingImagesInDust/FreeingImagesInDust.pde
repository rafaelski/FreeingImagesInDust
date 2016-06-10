/***********************************************************************
 
 Demo of the MSAFluid library (www.memo.tv/msafluid_for_processing)
 Move mouse to add dye and forces to the fluid.
 Click mouse to turn off fluid rendering seeing only particles and their paths.
 Demonstrates feeding input into the fluid and reading data back (to update the particles).
 Also demonstrates using Vertex Arrays for particle rendering.
 
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


final float FLUID_WIDTH = 120;

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
//boolean CopyBG = false;
boolean startDust = false;

boolean OFF = false;

// Face Tracking
float PosFaceX, PosFaceY, WidthFace, HeightFace;

float faceXOff = 0;
float faceYOff = 0;
float faceWOff = 0;
float faceHOff = 0;
float growing = .8;


float FanForcesX, FanForcesY;
float[] Accel_x = {  
  .1, -1, -20, 14, .1, 10, -1, 15
};
float[] Accel_y = {  
  .1, -1, 10, -2, .1, 10, 1, 15
};
int timeEllapsed;

int[] FanTimes = {  
  10, 20, 30, 40, 50, 60, 70, 80
};

boolean bUseSerial = false;
float totalAlive = 0;

int radius = 60;
int timeStartedFace = 0;
int timeLastNoFace = 0;
float alphaFade = 255;

void setup() {
  //size(screenWidth, screenHeight, P3D);    // use OPENGL rendering for bilinear filtering on texture
  size(1152, 768, P3D);

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
}


void draw() {
  background(255, 255, 255);
  timeEllapsed = millis();

  if (liveCam.pixels.length <= 0 ) return;

  stillFrame.loadPixels();
  liveCam.loadPixels();

  if (!setOnce) {
    setOnce = true;
    for ( int i = 0; i < screenWidth*screenHeight; i++) {
      stillFrame.pixels[i] = color(255, 255, 255, 255);
    }
    stillFrame.updatePixels();
  }

  if (totalAlive == 0) {
    for ( int i = 0; i < screenWidth*screenHeight; i++) {
      stillFrame.pixels[i] = color(255, 255, 255, 255);
    }
    stillFrame.updatePixels();
  }


  copyImgCV.copy(liveCam, 0, 0, screenWidth, screenHeight, 0, 0, screenWidth/8, screenHeight/8);
  opencv.loadImage(copyImgCV);


  if (timeStartedFace>0 && (millis()-timeStartedFace)/1000.0 > 15){ 
    if(alphaFade > 0)alphaFade-=2;
  }

  for ( int i = 0; i < screenWidth*screenHeight; i++) {
    color c = stillFrame.pixels[i];

    //color c3 = color (red(c2), green(c2), blue(c2), 255); //Simpler but slower method;





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
  fluidSolver.update();
  faces = opencv.detect();

  int largestFace = 0;
  int closestDist = width*height*1000; // hack to great big number

  for (int i = 0; i < faces.length; i++) {
    int d = (int)dist(faces[i].x * 8, faces[i].y  * 8, width*.5, height*.5);
    int faceSize = faces[i].width*faces[i].height;
    //if(faceSize > largestFace){
    //largestFace = faceSize;
    if (d < closestDist && d < 400) {
      closestDist = d;
      PosFaceX = (faces[i].x - faces[i].width*.5) * 8 ;
      PosFaceY = (faces[i].y - faces[i].height*.15)  * 8  ;
      WidthFace = (faces[i].width+faces[i].width*1) * 8;
      HeightFace = (faces[i].height+faces[i].height*.5) * 8;
      //}
    }
    //PosFaceX = faces[i].x * 8 ;
    //PosFaceY = faces[i].y  * 8 ;
    //WidthFace = faces[i].width * 8;
    //HeightFace = faces[i].height * 8;
    //println(i + " w " + faces[i].width + " h " + faces[i].height);
  }
  //  if( faces.length > 0 ){
  //  PosFaceX = faces[0].x * 8 ;
  //    PosFaceY = faces[0].y  * 8 ;
  //    WidthFace = faces[0].width * 8;
  //    HeightFace = faces[0].height * 8;
  //  }
  //  

  if (faces.length > 0) { //If we have a face, trigger startDust and tells Arduino
    startDust =true; 
    if (bUseSerial)  myPort.write('1');
    radius = 60;

    stroke(255, 0, 0);
    strokeWeight(3);
    noFill();

    if (timeStartedFace==0 && (millis()-timeLastNoFace)/1000.0 > 5) { 
      timeStartedFace = millis();
      timeLastNoFace = 0;
      alphaFade = 255;
    }
  } 
  else {
    if (bUseSerial)  myPort.write('0');
    radius = 0;

    noStroke(); 
    timeStartedFace = 0;
    timeLastNoFace = millis();
  }

  PVector ploc = location;
  location.x = PosFaceX-faceXOff + map(noise(noff.x), 0, 1, 0, WidthFace+faceWOff);
  location.y = (PosFaceY-50)+faceYOff + map(noise(noff.y), 0, 1, 0, HeightFace+faceHOff);

  //  stroke(255, 0, 0);
  //  strokeWeight(3);
  //  rect(PosFaceX-faceXOff, (PosFaceY-50)+faceYOff, WidthFace+faceWOff, HeightFace+faceHOff);

  noff.add(0.15, 0.15, 0);

  float mouseNormX = location.x * invWidth;
  float mouseNormY = location.y * invHeight;
  //  float mouseVelX = (location.x - ploc.x) * invWidth;
  //  float mouseVelY = (location.y - ploc.y) * invHeight;


  for (int i=0; i < 7; i++) {
    if (timeEllapsed/1000 > FanTimes[i]/2 && timeEllapsed/1000 < FanTimes[i+1]/2) {
      FanForcesX = Accel_x[i];
      FanForcesY = Accel_y[i];
      if (timeEllapsed/1000 > FanTimes[7]) timeEllapsed = 0;
      break;
    }
  }

  if (startDust) { 
    addForce(mouseNormX, mouseNormY, FanForcesX, FanForcesY); //dx and dy means the velocity and direction
    addForce(mouseNormX, mouseNormY+.25, FanForcesX, FanForcesY); //dx and dy means the velocity and direction
  }
  //  if (faceXOff <= 160 && faces.length>0) {
  //    faceXOff += .45 *growing;
  //    faceYOff += .2 *growing;
  //    faceWOff += .9 *growing;
  //    faceHOff += .5 *growing;
  //  } else if (faceYOff <= 300 && faces.length>0) {
  //    faceXOff += .1 *growing;
  //    faceYOff += .2 *growing;
  //    faceWOff += .2 *growing;
  //    faceHOff -= .05 *growing;
  //  }
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

  //  println(timeEllapsed); 
  //  println("fans", FanForcesX);
  totalAlive = 0;
  println ( "frameRate ", frameRate );

  // draw everything
  pushMatrix();  
  scale(-1, 1);
  translate(-screenWidth, 0);
  image(ourBackground, 0, 0);
  image(stillFrame, 0, 0);

  rect(PosFaceX-faceXOff, (PosFaceY-50)+faceYOff, WidthFace+faceWOff, HeightFace+faceHOff);
  ellipse(location.x, location.y, 10, 10);
  ellipse(location.x, ( mouseNormY+.25)*screenHeight, 10, 10);


  if (startDust==true) particleSystem.updateAndDraw();
  popMatrix();

  println("total alive "+ totalAlive);
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
    saveFrame("data/savedBackground.jpg");
    break;
  }
  //println(frameRate);
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

    particleSystem.addParticles(x * screenWidth, y * screenHeight);//, 900);

    //_FanForcesX = (mouseX)/ ( width /5);  // _FanForcesX and dy means the velocity and direction
    //_FanForcesY = -((mouseY)/ ( height /5));  // _FanForcesY and dy means the velocity and direction

    fluidSolver.uOld[index] += _FanForcesX * velocityMult;
    fluidSolver.vOld[index] += _FanForcesY * velocityMult;
  }
}

void captureEvent(Capture c) {
  c.read();
}

