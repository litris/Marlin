#ifndef LCD4D_H
#define LCD4D_H
#include "Marlin.h"

#define LCD4D_WIDTH 57
#define LCD4D_UPDATE_INTERVAL 100

#define MESSAGE_ID "M:"
#define HOTEND0_ID "H0:"
#define HOTEND1_ID "H1:"
#define THOTEND0_ID "T0:"
#define THOTEND1_ID "T1:"
#define TBED_ID "B:"
#define TTBED_ID "TB:"
#define TIME_ID "t:"
#define ZPOS_ID "Z:"
#define SDPERCENT_ID "S:"
#define FEEDMULTIPLY_ID "F:"
#define SOUND_ID "s:"

#define LCD4D_CHECKDATA lcd4d_incoming();
#define LCD_FORCE_UPDATE lcd4d_force_update();

void lcd4d_init();
void lcd4d_update();
void lcd4d_status();
void lcd4d_status(const char* message);
void lcd4d_status();
void lcd4d_statuspgm(const char* message);
void lcd4d_showStatus();
void lcd4d_finishSound();
void lcd4d_incoming();
void lcd4d_force_update();


char *ftostr3(const float &x);
char *itostr2(const uint8_t &x);
char *ftostr31(const float &x);
char *ftostr32(const float &x);
char *itostr31(const int &xx);
char *itostr3(const int &xx);
char *itostr4(const int &xx);
char *ftostr51(const float &x);
//void beep();
//void buttons_init();
//void buttons_check();

#endif // LCD4D
