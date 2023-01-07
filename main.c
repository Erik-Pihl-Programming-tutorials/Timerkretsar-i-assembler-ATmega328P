/********************************************************************************
* main.c: Demonstration av timerkretsar Timer 0 - Timer 2 i C. Tre lysdioder 
*         anslutna till pin 8 - 10 (PORTB0 - PORTB2) togglas via var sin
*         timerkrets. Varje timerkrets genererar ett avbrott var 16.384:e ms.
*
*         LED1 ansluten till pin 8 (PORTB0) togglas var 100:e ms via Timer 0.
*         LED2 ansluten till pin 9 (PORTB1) togglas var 200:e ms via Timer 1.
*         LED3 ansluten till pin 10 (PORTB2) togglas var 500:e ms via Timer 2.
*
*         Eftersom ett timeravbrott sker var 16.384:e ms räknas antalet
*         avbrott N som krävs för en viss fördröjningstid T enligt nedan:
*
*                                  N = T / 16.384,
*
*         där resultatet avrundas till närmaste heltal.
*
*         Vi har en klockfrekvens F_CPU på 16 MHz. Vi använder en prescaler
*         på 1024 för timerkretsarna, vilket medför att uppräkningsfrekvensen
*         för respektive timerkrets blir 16M / 1024 = 15 625 Hz. Därmed sker
*         inkrementering av respektive timer var 1 / 15 625 = 0.064:e ms.
*         Eftersom varje timerkrets räknar upp till 256 innan avbrott passerar
*         därmed 0.064 * 256 = 16.384 ms mellan varje avbrott.
********************************************************************************/
#include <avr/io.h>
#include <avr/interrupt.h>

/* Makrodefinitioner: */
#define LED1 PORTB0 /* Lysdiod 1 ansluten till pin 8 (PORTB0). */
#define LED2 PORTB1 /* Lysdiod 2 ansluten till pin 9 (PORTB1). */
#define LED3 PORTB2 /* Lysdiod 3 ansluten till pin 10 (PORTB2). */

#define LED1_TOGGLE PINB = (1 << LED1) /* Togglar lysdiod 1. */
#define LED2_TOGGLE PINB = (1 << LED2) /* Togglar lysdiod 2. */
#define LED3_TOGGLE PINB = (1 << LED3) /* Togglar lysdiod 3. */

#define TIMER0_MAX_COUNT 6  /* 6 timeravbrott för 100 ms fördröjning. */
#define TIMER1_MAX_COUNT 12 /* 12 timeravbrott för 200 ms fördröjning. */
#define TIMER2_MAX_COUNT 31 /* 31 timeravbrott för 500 ms fördröjning. */

/********************************************************************************
* ISR: Avbrottsrutin för Timer 0 i Normal Mode, som äger rum var 16.384:e ms
*      vid overflow (uppräkning till 256, då räknaren blir överfull). 
*      Ungefär var 100:e ms (var 6:e avbrott) togglas lysdiod LED1.
*
*      - TIMER0_OVF_vect: Avbrottsvektor 0x20 för Timer 0 i Normal Mode.
********************************************************************************/
ISR (TIMER0_OVF_vect)
{
   static volatile uint8_t timer0_counter = 0;

   if (++timer0_counter >= TIMER0_MAX_COUNT)
   {
      LED1_TOGGLE;
      timer0_counter = 0;
   }
   return;
}

/********************************************************************************
* ISR: Avbrottsrutin för Timer 1 i CTC Mode, som äger rum var 16.384:e ms
*      vid uppräkning till 256, som har sätts till maxvärde för uppräkning.
*      Ungefär var 200:e ms (var 12:e avbrott) togglas lysdiod LED2.
*
*      - TIMER1_COMPA_vect: Avbrottsvektor 0x16 för Timer 1 i CTC Mode.
********************************************************************************/
ISR (TIMER1_COMPA_vect)
{
   static volatile uint8_t timer1_counter = 0;

   if (++timer1_counter >= TIMER1_MAX_COUNT)
   {
      LED2_TOGGLE;
      timer1_counter = 0;
   }
   return;
}

/********************************************************************************
* ISR: Avbrottsrutin för Timer 2 i Normal Mode, som äger rum var 16.384:e ms
*      vid overflow (uppräkning till 256, då räknaren blir överfull).
*      Ungefär var 500:e ms (var 31:e avbrott) togglas lysdiod LED3.
*
*      - TIMER2_OVF_vect: Avbrottsvektor 0x12 för Timer 2 i Normal Mode.
********************************************************************************/
ISR (TIMER2_OVF_vect)
{
   static volatile uint8_t timer2_counter = 0;

   if (++timer2_counter >= TIMER2_MAX_COUNT)
   {
      LED3_TOGGLE;
      timer2_counter = 0;
   }
   return;
}

/********************************************************************************
* setup: Sätter lysdiodernas pinnar till utportar samt aktiverar timerkretsarna
*        så att avbrott sker var 16.384:e millisekund för respektive timer.
********************************************************************************/
static inline void setup(void)
{
   DDRB = (1 << LED1) | (1 << LED2) | (1 << LED3);
   asm("SEI");

   TCCR0B = (1 << CS02) | (1 << CS00);
   TIMSK0 = (1 << TOIE0);

   TCCR1B = (1 << CS12) | (1 << CS10) | (1 << WGM12);
   OCR1A = 256;
   TIMSK1 = (1 << OCIE1A);

   TCCR2B = (1 << CS22) | (1 << CS21) | (1 << CS20);
   TIMSK2 = (1 << TOIE2);
   return;
}

/********************************************************************************
* main: Initierar systemet vid start. Programmet hålls sedan igång så länge
*       matningsspänning tillförs.
********************************************************************************/
int main(void)
{
   setup();

   while (1)
   {

   }

   return 0;
}

