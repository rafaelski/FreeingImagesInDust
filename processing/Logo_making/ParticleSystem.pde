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

import java.nio.FloatBuffer;
import com.sun.opengl.util.*;

boolean renderUsingVA = false;

void fadeToColor(GL2 gl, float r, float g, float b, float speed) {
  gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA);
  gl.glColor4f(r, g, b, speed);
  gl.glBegin(gl.GL_QUADS);
  gl.glVertex2f(0, 0);
  gl.glVertex2f(width, 0);
  gl.glVertex2f(width, height);
  gl.glVertex2f(0, height);
  gl.glEnd();
}


class ParticleSystem {
  FloatBuffer posArray;
  FloatBuffer colArray;

  final static int maxParticles = 150000;
  int curIndex;

  Particle[] particles;

  ParticleSystem() {
    particles = new Particle[maxParticles];
    for (int i=0; i<maxParticles; i++) particles[i] = new Particle();
    curIndex = 0;

    posArray = BufferUtil.newFloatBuffer(maxParticles * 2 * 2);// 2 coordinates per point, 2 points per particle (current and previous)
    colArray = BufferUtil.newFloatBuffer(maxParticles * 3 * 2);
  }


  void updateAndDraw() {
    //OPENGL Processing 2.1
    PGL pgl;                                  // JOGL's GL object
    pgl = beginPGL();
    GL2 gl = ((PJOGL)pgl).gl.getGL2();       // processings opengl graphics object               

    gl.glEnable( GL2.GL_BLEND );             // enable blending
    if (!drawFluid) fadeToColor(gl, 0, 0, 0, 0.05);

    // gl.glBlendFunc(GL2.GL_ONE, GL2.GL_ONE);  // additive blending (ignore alpha)
    gl.glEnable(GL2.GL_LINE_SMOOTH);        // make points round
    gl.glLineWidth(1);


    if (renderUsingVA) {
      for (int i=0; i<maxParticles; i++) {
        if (particles[i].alpha > 0) {
          particles[i].update();
          particles[i].updateVertexArrays(i, posArray, colArray);
        }
      }    
      gl.glEnableClientState(GL2.GL_VERTEX_ARRAY);
      gl.glVertexPointer(2, GL2.GL_FLOAT, 0, posArray);

      gl.glEnableClientState(GL2.GL_COLOR_ARRAY);
      gl.glColorPointer(3, GL2.GL_FLOAT, 0, colArray);

      gl.glDrawArrays(GL2.GL_LINES, 0, maxParticles * 2);
    } 
    else {
      gl.glBegin(gl.GL_LINES);               // start drawing points
      for (int i=0; i<maxParticles; i++) {
        if (particles[i].alpha > 0) {
          particles[i].update();
          particles[i].drawOldSchool(gl);    // use oldschool renderng
        }
      }
      gl.glEnd();
    }

    gl.glDisable(GL2.GL_BLEND);
    endPGL();
  }


  void addParticles(float x, float y, int count ) {

    float r = 32;
    float r2 = r*r;

    for (float i = x-r; i < x+r; i++) {
      for (float j = y-r; j < y+r; j++) {  

        float sqD = ((i-x)*(i-x))+((j-y)*(j-y)); //Square distance from center (x, y) and the square (i, j)

        if ( sqD < r2 && random(20) > 19) {   //drawing a circle with the "r" radius inside the square (i, j). Chances of 19 in 20 to appear;
          addParticle(i, j );
        }
      }
    }

    //for(int i=0; i<count; i++) addParticle(x + random(-50, 50), y + random(-50, 50));

    /* 
     for (int t=0; t<count; t++) { 
     float nx = x + random(-50, 50);
     float ny = y + random(-50, 50);
     for (float i = nx-r; i < nx+r; i++) {
     for (float j = ny-r; j < ny+r; j++) {  
     
     float sqD =  ((i-nx)*(i-nx))+((j-ny)*(j-ny)); //Square distance from center (x, y) and the square (i, j)
     
     if ( sqD < r2 ) {   //drawing a circle with the "r" radius inside the square (i, j);
     addParticle(i, j );
     }
     }
     }
     //addParticle(x + random(-50, 50), y + random(-50, 50));
     }
     */
     
    // for(int i=0; i<100; i++) addParticle(x + random(-50, 50), y + random(-50, 50));
    //addParticle(random(width-1), random(height-1));    //random into the entire screen
  }


  void addParticle(float x, float y) {

    if (x >= width) x = width-1;
    if ( y >= height) y = height-1;
    if (x < 0 ) x = 0;
    if ( y < 0 ) y = 0;
    
    int pixIndex = int(x) + int(y)*width;
    color c = Beyonce.pixels[pixIndex];  //Pick the color of the pixels at the mouse position;
    
    if ( brightness(c) > 0 ) {
      Beyonce.pixels[pixIndex]=color(0);    //Turn the Image Pixels into Black;
      
      particles[curIndex].init(x, y, red(c), green(c), blue(c));    //Colorize the particles in (x, y) mouse position with the colors of the image;
      
      curIndex++;
      if (curIndex >= maxParticles) curIndex = 0;
    }
  }
}

//      for(int i = 0; i<10; i++){
//        for(int j = 0; j<2; j++){
//        Beyonce.set((int)(x* randomGaussian()), (int)(y*  randomGaussian()),color(0));
//      }
//      }

// println(red(c));
//      float currR = (c >> 16) & 0xFF;
//      float currG = (c >> 8) & 0xFF;
//      float currB = c & 0xFF;




