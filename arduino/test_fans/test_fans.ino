#define RELAY_ON 0
#define RELAY_OFF 1

unsigned int Relays[] = {24, 26, 28,   30, 32, 34,   36, 38};


void setup() {
  Serial.begin(9600);

  for (int k = 0; k < 9; k++) {
    pinMode(Relays[k], OUTPUT);
    digitalWrite(Relays[k], RELAY_ON);
    delay(3000); 
  }
    delay(10000);
    
//  for (int k = 0; k < 9; k++) {
//    pinMode(Relays[k], OUTPUT);
//    digitalWrite(Relays[k], RELAY_OFF);
//  }
}


void loop() {
}

void serialEvent() {
}





