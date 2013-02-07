#include "language.h"
#include "temperature.h"
#include "ultralcd.h"
#include "lcd4d.h"
#include "Marlin.h"
#include "language.h"
#include "temperature.h"
//#include "EEPROMwrite.h"


//===========================================================================
//=============================imported variables============================
//===========================================================================

extern volatile int feedmultiply;
extern volatile bool feedmultiplychanged;

extern volatile int extrudemultiply;

extern long position[4];   
#ifdef SDSUPPORT
#include "cardreader.h"
extern CardReader card;
#endif



//===========================================================================
//=============================public variables============================
//===========================================================================


//===========================================================================
//=============================private  variables============================
//===========================================================================

static char messagetext[LCD4D_WIDTH]="";

boolean force_lcd_update=false;

//return for string conversion routines
static char conv[8];

#define BUFFLEN 30
static char cmd_buff[BUFFLEN];
static int  buff_index=0;

static unsigned long previous_millis_lcd=0;

#ifdef SDSUPPORT
static uint8_t oldpercent=101;
#endif

static int olddegHotEnd0=0;
static int oldtargetHotEnd0=0;
 
#if defined BED_USES_THERMISTOR || defined BED_USES_AD595 
  static int oldtBed=-1;
  static int oldtargetBed=0; 
#endif
#if EXTRUDERS > 1
 static int olddegHotEnd1=-1;
 static int oldtargetHotEnd1=-1;
#endif
static uint16_t oldtime_m=0;
static uint16_t oldtime_h=0;
static int oldzpos=0;
static int oldfeedmultiply=0;

 
  
//===========================================================================
//=============================functions         ============================
//===========================================================================

int intround(const float &x){return int(0.5+x);}


void lcd4d_incoming()
{
  while(MYSERIAL1.available()>0)
  {
    cmd_buff[buff_index] = (char)MYSERIAL1.read();
    if(cmd_buff[buff_index] == '\n')
    {
       cmd_buff[buff_index] = 0;
       enquecommand(cmd_buff);
       buff_index = 0;
    } else
       buff_index++;
    if(buff_index >= BUFFLEN)
    {
      buff_index = BUFFLEN-1;
    }
  }  
}


void lcd4d_init()
{
   MYSERIAL1.begin(115200);
   SERIAL1_PROTOCOLPGM(MESSAGE_ID)
   SERIAL1_PROTOCOLLNPGM(WELCOME_MSG)

}

void lcd4d_force_update()
{
  force_lcd_update=true;
}

void lcd4d_status(const char* message)
{
  strncpy(messagetext,message,LCD4D_WIDTH);
  messagetext[strlen(message)]=0;
}

void lcd4d_statuspgm(const char* message)
{
  char ch=pgm_read_byte(message);
  char *target=messagetext;
  uint8_t cnt=0;
  while(ch &&cnt<LCD4D_WIDTH)
  {
    *target=ch;
    target++;
    cnt++;
    ch=pgm_read_byte(++message);
  }
  *target=0;
}

void lcd4d_status()
{
    if(!force_lcd_update)
      if((millis() - previous_millis_lcd) < LCD4D_UPDATE_INTERVAL)
        return;
     
     lcd4d_update();
     previous_millis_lcd=millis();
}

void lcd4d_update() {
  lcd4d_showStatus();
}

void zeroFill(int value) 
{
  if(value < 100)
     SERIAL1_PROTOCOLPGM("0");
   if(value < 10)
     SERIAL1_PROTOCOLPGM("0");
}

void lcd4d_showStatus()
{ 

  //HotEnd0  
  int tHotEnd0=intround(degHotend0());
  if(tHotEnd0!=olddegHotEnd0 || force_lcd_update)
  {
    SERIAL1_PROTOCOLPGM(HOTEND0_ID)
    zeroFill(tHotEnd0);
    SERIAL1_PROTOCOLLN(tHotEnd0)
    olddegHotEnd0=tHotEnd0;
  }
  
  int ttHotEnd0=intround(degTargetHotend0());
  if(ttHotEnd0!=oldtargetHotEnd0 || force_lcd_update)
  {
    SERIAL1_PROTOCOLPGM(THOTEND0_ID)
    if(ttHotEnd0==-272) // First time, force update
    {
       SERIAL1_PROTOCOLLN("000")
       oldtargetHotEnd0=0;     
    }
    else
    {
    zeroFill(ttHotEnd0);
    SERIAL1_PROTOCOLLN(ttHotEnd0)
    oldtargetHotEnd0=ttHotEnd0;
    }
  }
  
  #if defined BED_USES_THERMISTOR || defined BED_USES_AD595 
    int tBed=intround(degBed());
    if(tBed!=oldtBed || force_lcd_update)
    {
      SERIAL1_PROTOCOLPGM(TBED_ID)
      zeroFill(tBed);
      SERIAL1_PROTOCOLLN(tBed)
      oldtBed=tBed;
    }
    int targetBed=intround(degTargetBed());
    if(targetBed!=oldtargetBed || force_lcd_update)
    {
      SERIAL1_PROTOCOLPGM(TTBED_ID)
      if(targetBed==-272) // First time, force update
      {
       SERIAL1_PROTOCOLLN("000")
       oldtargetBed=0; 
      }
      else
      {
        zeroFill(targetBed);
        SERIAL1_PROTOCOLLN(targetBed)
        oldtargetBed=targetBed;
      }
    }
   #endif
     
  #if EXTRUDERS > 1

    int tHotEnd1=intround(degHotend1());
    if(tHotEnd1!=olddegHotEnd1 || force_lcd_update )
    {
      SERIAL1_PROTOCOLPGM(THOTEND1_ID)
      SERIAL1_PROTOCOLLN(ttHotEnd1)
      olddegHotEnd1=tHotEnd1;
    }
    int ttHotEnd1=intround(degTargetHotend1());
    if(ttHotEnd1!=oldtargetHotEnd1 || force_lcd_update)
    {
      SERIAL1_PROTOCOLPGM(THOTEND1_ID)
      if(ttHotEnnd1==-272) {  // First time, force update
        SERIAL1_PROTOCOLLN("000")
        oldtargetHotEnd1=0;        
      }
      else
      {
        zeroFill(targetBed);
        SERIAL1_PROTOCOLLN(ttHotEnd1)
        oldtargetHotEnd1=ttHotEnd1;
      }
    }
  #endif
  
  if(starttime!=0)
  {
    uint16_t time=millis()/60000-starttime/60000;
    
      uint16_t m=time%60;
      uint16_t h=time/60;
    
    if( ((time/60)!=oldtime_h || (time%60)!=oldtime_m ) || force_lcd_update )
    {
      SERIAL1_PROTOCOLPGM(TIME_ID)
      SERIAL1_PROTOCOL(itostr2(h))
      SERIAL1_PROTOCOLPGM("h");
      SERIAL1_PROTOCOL(itostr2(m))
      SERIAL1_PROTOCOLLNPGM("m");
      oldtime_h=h;
      oldtime_m=m;
    }
  }
  
  int currentz=current_position[Z_AXIS]*100;
  if(currentz!=oldzpos || force_lcd_update)
  {
    SERIAL1_PROTOCOLPGM(ZPOS_ID)
    SERIAL1_PROTOCOLLN(ftostr52(current_position[Z_AXIS]))
    oldzpos=currentz;
  }
  
  int curfeedmultiply=feedmultiply;
  
  if(feedmultiplychanged == true) {
    feedmultiplychanged = false;
  }
  
  /*
  if(encoderpos!=curfeedmultiply||force_lcd_update)
  {
   curfeedmultiply=encoderpos;
   if(curfeedmultiply<10)
     curfeedmultiply=10;
   if(curfeedmultiply>999)
     curfeedmultiply=999;
   feedmultiply=curfeedmultiply;
   encoderpos=curfeedmultiply;
  } */
  
  if((curfeedmultiply!=oldfeedmultiply)||force_lcd_update)
  {
   oldfeedmultiply=curfeedmultiply;
   SERIAL1_PROTOCOLPGM(FEEDMULTIPLY_ID)
   SERIAL1_PROTOCOLLN(itostr3(curfeedmultiply));
  }
  
  
  if(messagetext[0]!='\0')
  {
    SERIAL1_PROTOCOLPGM(MESSAGE_ID)
    SERIAL1_PROTOCOLLN(messagetext);
    messagetext[0]='\0';
  }
  
  uint8_t percent=card.percentDone();
#ifdef SDSUPPORT
  if(oldpercent!=percent || force_lcd_update)
  {
    SERIAL1_PROTOCOLPGM(SDPERCENT_ID)
    SERIAL1_PROTOCOLLN(itostr3((int)percent))
    oldpercent=percent;
  }
#endif

  force_lcd_update=false;
}
  
void lcd4d_finishSound() {
    SERIAL1_PROTOCOLLNPGM(SOUND_ID);
}
  
  
  //  convert float to string with +123.4 format
char *ftostr3(const float &x)
{
  //sprintf(conv,"%5.1f",x);
  int xx=x;
  conv[0]=(xx/100)%10+'0';
  conv[1]=(xx/10)%10+'0';
  conv[2]=(xx)%10+'0';
  conv[3]=0;
  return conv;
}

char *itostr2(const uint8_t &x)
{
  //sprintf(conv,"%5.1f",x);
  int xx=x;
  conv[0]=(xx/10)%10+'0';
  conv[1]=(xx)%10+'0';
  conv[2]=0;
  return conv;
}

//  convert float to string with +123.4 format
char *ftostr31(const float &x)
{
  int xx=x*10;
  conv[0]=(xx>=0)?'+':'-';
  xx=abs(xx);
  conv[1]=(xx/1000)%10+'0';
  conv[2]=(xx/100)%10+'0';
  conv[3]=(xx/10)%10+'0';
  conv[4]='.';
  conv[5]=(xx)%10+'0';
  conv[6]=0;
  return conv;
}

char *ftostr32(const float &x)
{
  int xx=x*100;
  conv[0]=(xx>=0)?'+':'-';
  xx=abs(xx);
  conv[1]=(xx/100)%10+'0';
  conv[2]='.';
  conv[3]=(xx/10)%10+'0';
  conv[4]=(xx)%10+'0';
  conv[6]=0;
  return conv;
}

char *itostr31(const int &xx)
{
  conv[0]=(xx>=0)?'+':'-';
  conv[1]=(xx/1000)%10+'0';
  conv[2]=(xx/100)%10+'0';
  conv[3]=(xx/10)%10+'0';
  conv[4]='.';
  conv[5]=(xx)%10+'0';
  conv[6]=0;
  return conv;
}

char *itostr3(const int &xx)
{
  conv[0]=(xx/100)%10+'0';
  conv[1]=(xx/10)%10+'0';
  conv[2]=(xx)%10+'0';
  conv[3]=0;
  return conv;
}

char *itostr4(const int &xx)
{
  conv[0]=(xx/1000)%10+'0';
  conv[1]=(xx/100)%10+'0';
  conv[2]=(xx/10)%10+'0';
  conv[3]=(xx)%10+'0';
  conv[4]=0;
  return conv;
}

//  convert float to string with +1234.5 format
char *ftostr51(const float &x)
{
  int xx=x*10;
  conv[0]=(xx>=0)?'+':'-';
  xx=abs(xx);
  conv[1]=(xx/10000)%10+'0';
  conv[2]=(xx/1000)%10+'0';
  conv[3]=(xx/100)%10+'0';
  conv[4]=(xx/10)%10+'0';
  conv[5]='.';
  conv[6]=(xx)%10+'0';
  conv[7]=0;
  return conv;
}

//  convert float to string with +123.45 format
char *ftostr52(const float &x)
{
  int xx=x*100;
  conv[0]=(xx>=0)?'+':'-';
  xx=abs(xx);
  conv[1]=(xx/10000)%10+'0';
  conv[2]=(xx/1000)%10+'0';
  conv[3]=(xx/100)%10+'0';
  conv[4]='.';
  conv[5]=(xx/10)%10+'0';
  conv[6]=(xx)%10+'0';
  conv[7]=0;
  return conv;
}



