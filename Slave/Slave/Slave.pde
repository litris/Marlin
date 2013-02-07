/*
   Slave processor code for RepRapPro mult-extruder machines
   
   Adrian Bowyer 7 August 2012
   RepRapPro Ltd
   http://reprappro.com
   
   Licence: GPL
*/

// Function prototypes

char* strplus(char* a, char* b);
void error(char* s);
void stop();
void setTemperature(int8_t e, int t);
int getRawTemperature(int8_t e);
float getTemperature(int8_t e);
int getRawTargetTemperature(float t);
void heatControl();
void tempCheck();
void step(int8_t e);
void test();
void command();
void incomming();
void configureInterrupt();
ISR ( PCINT17_void );
void setDirection(int8_t e, bool d);
void enable(int8_t e);
void disable(int8_t e);

#include "Slave_Configuration.h"

unsigned long time;
char buf[BUFLEN];
char scratch[2*BUFLEN];
int bp;

// Pin arrays

int8_t steps[DRIVES] = STEPS;
int8_t dirs[DRIVES] = DIRS;
int8_t enables[DRIVES] = ENABLES;
int8_t therms[HOT_ENDS] = THERMS;
int8_t heaters[HOT_ENDS] = HEATERS;
volatile int8_t currentExtruder = 0;

// Drive arrays


// Heater arrays

float setTemps[HOT_ENDS];

// PID variables

int temp_iState_max_min[HOT_ENDS];
float Kp[HOT_ENDS];
float Ki[HOT_ENDS];
float Kd[HOT_ENDS];
long temp_iState[HOT_ENDS];
int temp_dState[HOT_ENDS];


/* *******************************************************************

   General administration and utilities
*/

void setup() 
{
  int8_t i;
  MYSERIAL1.begin(BAUD); 
  bp = 0;

  for(i = 0; i < DRIVES; i++)
  {
    pinMode(steps[i], OUTPUT);
    pinMode(dirs[i], OUTPUT);
    pinMode(enables[i], OUTPUT);
    disable(i);
    setDirection(i, FORWARDS);
  }
  currentExtruder = 1;
  enable(currentExtruder);
  
  for(i = 0; i < HOT_ENDS; i++)
  {
    pinMode(therms[i], INPUT);
    pinMode(heaters[i], OUTPUT);
    analogWrite(heaters[i], 0);
    Kp[i] = KP;
    Ki[i] = KI;
    Kd[i] = KD;
    temp_iState[i] = 0;
    temp_dState[i] = 0;
    temp_iState_max_min[i] = PID_I_MAX/KI;
    setTemperature(i, 0);
  }
  configureInterrupt();
  time = millis() + TEMP_INTERVAL;
}

inline char* strplus(char* a, char* b)
{
  strcpy(scratch, a);
  return strcat(scratch, b);
}

inline void error(char* s)
{
}

void stop()
{
  int8_t i;
  for(i = 0; i < DRIVES; i++)
    digitalWrite(enables[i], DISABLE);
  for(i = 0; i < HOT_ENDS; i++)
    setTemperature(i, 0); 
}

/* **********************************************************************

   Heaters and temperature
*/


inline void setTemperature(int8_t e, int t)
{
  setTemps[e]=t;
}

inline int getRawTemperature(int8_t e)
{
  return analogRead(therms[e]);
}

inline float getTemperature(int8_t e)
{
  float raw = (float)getRawTemperature(e);
  return ABS_ZERO + TH_BETA/log( (raw*TH_RS/(AD_RANGE - raw)) /TH_R_INF );
}

inline int getRawTargetTemperature(float t)
{
  float et = TH_R_INF*exp(TH_BETA/(t - ABS_ZERO));
  return (int)(0.5 + et*AD_RANGE/(et + TH_RS));  
}


void heatControl()
{
  int error, pTerm, dTerm, output, target_raw, current_raw;
  long iTerm;
  
  for(int8_t e = 0; e < HOT_ENDS; e++)
  {
     target_raw = getRawTargetTemperature(setTemps[e]);
     current_raw = getRawTemperature(e);
     error =  current_raw - target_raw;
     pTerm = Kp[e] * error;
     temp_iState[e] += error;
     temp_iState[e] = constrain(temp_iState[e], -temp_iState_max_min[e], temp_iState_max_min[e]);
     iTerm = Ki[e] * temp_iState[e];
     dTerm = Kd[e] * (current_raw - temp_dState[e]);
     temp_dState[e] = current_raw;
     output = constrain(pTerm + iTerm - dTerm, 0, PID_MAX);
     analogWrite(heaters[e], output);
  }
}

inline void tempCheck()
{
  if( (long)(millis() - time) < 0)
    return;
  time += TEMP_INTERVAL;
  heatControl();
}

/* *********************************************************************

   Stepper motors and DDA
*/

inline void stepExtruder(int8_t e)
{
  digitalWrite(steps[e],1);
  digitalWrite(steps[e],0);
}

inline void setDirection(int8_t e, bool d)
{
  digitalWrite(dirs[e], d);
}

inline void enable(int8_t e)
{
  digitalWrite(enables[e], ENABLE);
}

inline void disable(int8_t e)
{
  digitalWrite(enables[e], DISABLE);
}

/* *********************************************************************

   The main loop and command interpreter
*/

void test()
{
  for(int i = 0; i < 1000; i++)
  {
    stepExtruder(1);
    delay(1);
  }
}

void command()
{
  switch(buf[0])
  {
    case GET_T: // Get temperature of an extruder
      MYSERIAL1.println(getTemperature(buf[2]-'0'), 1); // 1 dec place
      break;
    
    case SET_T: // Set temperature of an extruder
      setTemperature(buf[2]-'0', atoi(&buf[4]));
      break;
      
    case EXTR:  // Set the current extruder
      disable(currentExtruder);
      currentExtruder = buf[2]-'0';
      enable(currentExtruder);
      break;
      
    case DIR_F:  // Set an extruder's direction forwards
      setDirection(buf[2]-'0', FORWARDS);
      break;
    
    case DIR_B:   // Set an extruder's direction backwards
      setDirection(buf[2]-'0', BACKWARDS);
      break;
    
    case SET_PID: // Set PID parameters
    /*
        if(code_seen('P')) Kp = code_value();
        if(code_seen('I')) Ki = code_value();
        if(code_seen('D')) Kd = code_value();
        if(code_seen('F')) pid_max = code_value();
        if(code_seen('Z')) nzone = code_value();
        if(code_seen('W')) pid_i_max = code_value();
        temp_iState_min = -pid_i_max / Ki;
        temp_iState_max = pid_i_max / Ki;
        */
        break;
    
    case Q_DDA: // Queue DDA parameters
    
    case SET_DDA: // Set DDA parameters from head of queue
    
    case STOP: // Shut everything down; carry on listening for commands
      stop();
      break;
      
    case NO_OP:
      break;
      
    case TEST:
      test();
      break;
      
    default:
      error(strplus("dud command: ", buf));
      break;
  }
}

inline void incomming()
{
  if(MYSERIAL1.available())
  {
    buf[bp] = (char)MYSERIAL1.read();
    if(buf[bp] == '\n')
    {
       buf[bp] = 0;
       command();
       bp = 0;
    } else
       bp++;
    if(bp >= BUFLEN)
    {
      bp = BUFLEN-1;
      error(strplus("command overflow: ", buf));
    }
  }  
}


void loop() 
{ 
  incomming();
  tempCheck();   
} 


/* *******************************************************************

  The master clock interrupt
*/

ISR ( PCINT2_vect ) 
{
  stepExtruder(currentExtruder);
}

void configureInterrupt()
{
 PCICR |= (1<<PCIE2);
 PCMSK2 |= (1<<PCINT17);
 MCUCR = (1<<ISC01) | (1<<ISC00); // Falling edge trigger
 pinMode(INTERRUPT_PIN, INPUT);
 digitalWrite(INTERRUPT_PIN, HIGH); // Set pullup
 interrupts();
}
