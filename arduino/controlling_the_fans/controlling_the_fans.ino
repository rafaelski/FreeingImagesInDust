#include <elapsedMillis.h>

elapsedMillis timeElapsed;

#define RELAY_ON 0
#define RELAY_OFF 1

//unsigned int FansON[] = {5000, 9000, 11000, 14000, 17000, 20000, 22000};
//unsigned int FansOFF[] = {36000, 28000, 38000, 40000, 30000, 32000, 34000};
//Order to TurnOff the Relays: (03, 06, 07, 08, 02, 03, 04, 01)
//
//unsigned int Fan_1[] = {2000, 7000, 15500, 44000};
//unsigned int Pin_1 = 22;

//LEDS
//unsigned int RelaysON[] = {3, 4, 5, 6, 7, 8, 9};
//unsigned int RelaysOFF[] = {9, 8, 7, 6, 5, 4, 3};

//RELAYS
unsigned int Relays[] = {24, 26, 28, 32, 34, 36};

//unsigned int FaceTrigger[] = {0, 1};
char w;


void setup() {
  Serial.begin(9600);

  for (int k = 0; k < 5; k++) {
    pinMode(Relays[k], OUTPUT);
    digitalWrite(Relays[k], RELAY_OFF);
  delay(100); //Check that all relays are inactive at Reset
  }

  //  pinMode(13, OUTPUT);
  //  digitalWrite(13, LOW);
  delay(100); //Check that all relays are inactive at Reset

}


void loop() {
  //elapsedmillisloop();

  if (Serial.available() > 0) {
    w = Serial.read();
  delay(100); //Check that all relays are inactive at Reset

    if (w == 0) {
//    for (int k = 0; k < 5; k++) digitalWrite(Relays[k], RELAY_OFF);
      digitalWrite(Relays[0], RELAY_OFF);
  delay(100); //Check that all relays are inactive at Reset
      digitalWrite(Relays[1], RELAY_OFF);
  delay(100); //Check that all relays are inactive at Reset
      digitalWrite(Relays[2], RELAY_OFF);
  delay(100); //Check that all relays are inactive at Reset
      digitalWrite(Relays[3], RELAY_OFF);
  delay(100); //Check that all relays are inactive at Reset
      digitalWrite(Relays[4], RELAY_OFF);
  delay(100); //Check that all relays are inactive at Reset
      digitalWrite(Relays[5], RELAY_OFF);
  delay(100); //Check that all relays are inactive at Reset
     } else {      
      digitalWrite(w, RELAY_ON);
  delay(100); //Check that all relays are inactive at Reset
    }
  }
}


/*
  void elapsedmillisloop() {
    for (int i = 0; i <= 6; i++) {
      if (timeElapsed > FansON[i] && timeElapsed < FansOFF[i])
      {
        digitalWrite(Relays[i], RELAY_ON);
        delay(10);
      }
    }
  }

    //Exception for the FAN01 that turns on/off in other way
    if (timeElapsed > Fan_1[0] && timeElapsed < Fan_1[1]) {
      digitalWrite(Pin_1, RELAY_ON);
        delay(10);
    } else if (timeElapsed > Fan_1[1] && timeElapsed < Fan_1[2]) {
      digitalWrite(Pin_1, RELAY_OFF);
        delay(10);
    } else if (timeElapsed > Fan_1[2] && timeElapsed < Fan_1[3]) {
      digitalWrite(Pin_1, RELAY_ON);
        delay(10);
    } else if (timeElapsed > Fan_1[3]) {
      digitalWrite(Pin_1, RELAY_OFF);
        delay(10);
    }


    for (int j = 0; j <= 6; j++) {
      if (timeElapsed > FansOFF[j])
      {
        digitalWrite(Relays[j], RELAY_OFF);
        delay(10);
      }
    }
  }
*/

