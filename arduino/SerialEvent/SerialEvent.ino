#define RELAY_ON 0
#define RELAY_OFF 1

//String inputString = "";         // a string to hold incoming data
//boolean stringComplete = false;  // whether the string is complete

unsigned int Relays[] = {24, 26, 28, 30, 32, 34,   28, 30, 32};

//int mtTime = 30;  // mirrot total Time
//boolean passHalf = false;

//char inChar;
//char last_inChar;


void setup() {
  // initialize serial:
  Serial.begin(9600);
  // reserve 200 bytes for the inputString:
  //inputString.reserve(200);

  for (int k = 0; k < 9; k++) {
    pinMode(Relays[k], OUTPUT);
    digitalWrite(Relays[k], RELAY_OFF);
    delay(10); //Check that all relays are inactive at Reset
  }
}


void loop() {
  // print the string when a newline arrives:
  //  if (stringComplete) {
  //    Serial.println(inputString);
  //    // clear the string:
  //    inputString = "";
  //    stringComplete = false;
  //  }
}

/*
  SerialEvent occurs whenever a new data comes in the
  hardware serial RX.  This routine is run between each
  time loop() runs, so using delay inside loop can delay
  response.  Multiple bytes of data may be available.
*/
void serialEvent() {
  while (Serial.available()) {

    // get the new byte:
    char inChar = (char)Serial.read();

    // if the incoming character is a newline, set a flag
    // so the main loop can do something about it:
    //    if (inChar == '\n') {
    //      stringComplete = true;
    //    }


    // 1.0
    // turn everything on/off based on message received
    //    if (inChar == '1') {
    //        for (int k = 0; k < 6; k++) {
    //          digitalWrite(Relays[k], RELAY_ON);
    //          delay(10);
    //        }
    //    }
    //    if (inChar == '0') {
    //      for (int k = 0; k < 6; k++) {
    //        digitalWrite(Relays[k], RELAY_OFF);
    //        delay(10);
    //      }
    //    }


    // 2.0
    // turn on the inChar Pin and turn off the rest
    //    for (int i = 0; i < 6; i++) {
    //      if (i == inChar)  {
    //        digitalWrite(Relays[inChar], RELAY_ON);
    //      } else {
    //        digitalWrite(Relays[i], RELAY_OFF);
    //        delay(10);
    //        }
    //    }
    // when the time (in processing) is over, turn everyone off
    //    if (inChar == '0') {
    //      for (int k = 0; k < 6; k++) {
    //        digitalWrite(Relays[k], RELAY_OFF);
    //        delay(10);
    //      }
    //    }


    // 3.0
    // turn on the inChar Pin and turn off the rest
    for (int i = 0; i < 9; i++) {
      if (i == inChar)  {
        digitalWrite(Relays[inChar], RELAY_ON);
      } else if (inChar != 'f' && inChar != 'o') {
        digitalWrite(Relays[i], RELAY_OFF);
        //delay(10);
        }
    }
          // trying to accumulate some fans turned on
    //    else if (inChar != 6 && inChar != 7 && inChar != 8) {
    //          digitalWrite(Relays[i], RELAY_OFF);
    //          delay(10);
    //          }
    //    }

    // when the time (in processing) is over, turn everyone off
    if (inChar == 'f') {
      for (int i = 6; i < 9; i++) {
        digitalWrite(Relays[i], RELAY_OFF);
      }
      digitalWrite(Relays[1], RELAY_ON);
    }

    if (inChar == 'o') {
      for (int i = 0; i < 9; i++) {
        digitalWrite(Relays[i], RELAY_OFF);
        delay(10);
      }
    }

  }
}





