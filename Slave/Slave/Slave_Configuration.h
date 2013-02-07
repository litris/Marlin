/*
   Slave processor code for RepRapPro mult-extruder machines
   
   Adrian Bowyer 7 August 2012
   RepRapPro Ltd
   http://reprappro.com
   
   Licence: GPL
*/



// Commands

#define GET_T 't'      // Get temperature
#define SET_T 'T'      // Set temperature
#define SET_PID 'P'    // Set PID parameters
#define Q_DDA 'Q'      // Queue DDA parameters
#define SET_DDA 'D'    // Set DDA parameters from head of queue
#define STOP 'S'       // Shut down everything
#define NO_OP 'N'      // Do nothing
#define TEST 'A'       // For debugging
#define EXTR 'E'       // Set current extruder
#define DIR_F 'F'      // Set direction forward
#define DIR_B 'B'      // Set direction backwards

// Various...

#define MYSERIAL1 Serial1  // comms here
#define BAUD 250000        // comms speed
#define TEMP_INTERVAL 112  // check temperature this many milliseconds
#define BUFLEN 64          // input string
#define RING_B 32          // DDA parameter ring buffer
#define HOT_ENDS 2         // number of heaters controlled
#define DRIVES 4           // number of steppers controlled

// === Pin definitions ===
// Sanguinololu V 1.2 or higher

#define ENABLE 0
#define DISABLE 1

#define FORWARDS 1
#define BACKWARDS 0

#define STEPS   { 15, 22, 3, 1 }
#define DIRS    { 21, 23, 2, 0 }
#define ENABLES { 14, 14, 26, 14 } 
 

#define THERMS { 7, 6 } // Analogue
#define HEATERS { 13, 14 }
#define INTERRUPT_PIN 17

//===========================================================================
//=============================Thermal Settings  ============================
//===========================================================================

// Set this if you want to define the constants in the thermistor circuit
// and work out temperatures algebraically - added by AB.

// See http://en.wikipedia.org/wiki/Thermistor#B_or_.CE.B2_parameter_equation

// BETA is the B value
// RS is the value of the series resistor in ohms
// R_INF is R0.exp(-BETA/T0), where R0 is the thermistor resistance at T0 (T0 is in kelvin)
// Normally T0 is 298.15K (25 C).  If you write that expression in brackets in the #define the compiler 
// should compute it for you (i.e. it won't need to be calculated at run time).

// If the A->D converter has a range of 0..16383 and the measured voltage is V (between 0 and 16383)
// then the thermistor resistance, R = V.RS/(16383 - V)
// and the temperature, T = BETA/ln(R/R_INF)
// To get degrees celsius (instead of kelvin) add -273.15 to T

// This DOES assume that all extruders use the same thermistor type.

#define ABS_ZERO -273.15
//#define AD_RANGE 16383.0
#define AD_RANGE 1023.0

// RS 198-961
#define TH_BETA 3960.0
#define TH_RS 4700.0
#define TH_R_INF ( 100000.0*exp(-TH_BETA/298.15) )

// PID constants

#define PID_MAX 255 // limits current to nozzle
#define PID_I_MAX 80
#define KP 2.0
#define KI 0.01
#define KD 20.0

// Incoming master-clock interrupt on D17 (chip pin 23, PCINT17)






