;/********************************************************************************
;* main.asm: Demonstration av timerkretsar Timer 0 - Timer 2 i C. Tre lysdioder 
;*           anslutna till pin 8 - 10 (PORTB0 - PORTB2) togglas via var sin
;*           timerkrets. Varje timerkrets genererar ett avbrott var 16.384:e ms.
;*
;*           LED1 ansluten till pin 8 (PORTB0) togglas var 100:e ms via Timer 0.
;*           LED2 ansluten till pin 9 (PORTB1) togglas var 200:e ms via Timer 1.
;*           LED3 ansluten till pin 10 (PORTB2) togglas var 500:e ms via Timer 2.
;*
;*           Eftersom ett timeravbrott sker var 16.384:e ms r�knas antalet
;*           avbrott N som kr�vs f�r en viss f�rdr�jningstid T enligt nedan:
;*
;*                                    N = T / 16.384,
;*
;*           d�r resultatet avrundas till n�rmaste heltal.
;* 
;*           Vi har en klockfrekvens F_CPU p� 16 MHz. Vi anv�nder en prescaler
;*           p� 1024 f�r timerkretsarna, vilket medf�r att uppr�kningsfrekvensen
;*           f�r respektive timerkrets blir 16M / 1024 = 15 625 Hz. D�rmed sker
;*           inkrementering av respektive timer var 1 / 15 625 = 0.064:e ms.
;*           Eftersom varje timerkrets r�knar upp till 256 innan avbrott 
;*           passerar d�rmed 0.064 * 256 = 16.384 ms mellan varje avbrott.
;*
;*           - Assemblerdirektiv:
;*              .EQU (Equal) : Allm�na makrodefinitioner.
;*              .DEF (Define): Makrodefinitioner f�r CPU-register.
;*              .ORG (Origin): Anv�nds f�r att specificera en adress.
;*
;*           - Assemblerinstruktioner:
;*              RJMP (Relativ Jump)         : Hoppar till angiven adress.
;*              RETI (Return From Interrupt): Hoppar tillbaka fr�n avbrottsrutin.
;*              LDI (Load Immediate)        : L�ser in v�rde till CPU-register.
;*              OUT (Store to I/O location) : Skriver till I/O-register.
;*              SEI (Set Interrupt Flag)    : Ettst�ller interrupt-flaggan.
;*              STS (Store To Dataspace)    : Skriver till dataminnet.
;*              LDS (Load From Dataspace)   : L�ser fr�n dataminnet.
;*              INC (Increment)             : Inkrementerar v�rde i CPU-register.
;*              CPI (Compare Immediate)     : J�mf�r inneh�ll i CPU-register
;*                                            med ett v�rde.
;*              BRLO (Branch If Lower)      : Hoppar till angiven adress om
;*                                            resultatet fr�n f�reg�ende
;*                                            j�mf�relse blev negativt, vilket
;*                                            indikeras genom att N-flaggan
;*                                            (Negative) i statusregistret
;*                                            SREG �r lika med noll.
;********************************************************************************/

; Makrodefinitioner:
.EQU LED1 = PORTB0 ; Lysdiod 1 ansluten till pin 8 (PORTB0).
.EQU LED2 = PORTB1 ; Lysdiod 2 ansluten till pin 9 (PORTB1).
.EQU LED3 = PORTB2 ; Lysdiod 3 ansluten till pin 10 (PORTB2).

.EQU TIMER0_MAX_COUNT = 6  ; 6 timeravbrott f�r 100 ms f�rdr�jning.
.EQU TIMER1_MAX_COUNT = 12 ; 12 timeravbrott f�r 200 ms f�rdr�jning.
.EQU TIMER2_MAX_COUNT = 31 ; 31 timeravbrott f�r 500 ms f�rdr�jning.

.EQU RESET_vect        = 0x00 ; Reset-vektor, utg�r programmets startpunkt.
.EQU TIMER2_OVF_vect   = 0x12 ; Avbrottsvektor f�r Timer 2 i Normal Mode.
.EQU TIMER1_COMPA_vect = 0x16 ; Avbrottsvektor f�r Timer 1 i CTC Mode.
.EQU TIMER0_OVF_vect   = 0x20 ; Avbrottsvektor f�r Timer 0 i Normal Mode.

.DEF LED1_REG    = R16 ; CPU-register som lagrar (1 << LED1).
.DEF LED2_REG    = R17 ; CPU-register som lagrar (1 << LED2).
.DEF LED3_REG    = R18 ; CPU-register som lagrar (1 << LED3).
.DEF COUNTER_REG = R24 ; CPU-register f�r uppr�kning och j�mf�relse av r�knarvariablerna.

;/********************************************************************************
;* .DSEG (Data Segment): Dataminnet - H�r lagras statiska variabler.
;********************************************************************************/
.DSEG
.ORG SRAM_START ; Deklaration av statiska variabler i b�rjan av dataminnet.
   timer0_counter: .byte 1 ; static uint8_t timer0_counter = 0;
   timer1_counter: .byte 1 ; static uint8_t timer1_counter = 0;
   timer2_counter: .byte 1 ; static uint8_t timer2_counter = 0;

;/********************************************************************************
;* .CSEG (Code Segment): Programminnet - H�r lagras programkod och konstanter.
;********************************************************************************/
.CSEG ; Kodsegmentet (programminnet) - H�r lagras programkoden.

;/********************************************************************************
;* RESET_vect: Programmet startpunkt, som �ven hoppas till vid system�terst�llning.
;*             Programhopp sker till subrutinen main f�r att starta programmet.
;********************************************************************************/
.ORG RESET_vect
   RJMP main

;/********************************************************************************
;* TIMER2_OVF_vect: Avbrottsvektor f�r Timer 2 i Normal Mode, som hoppas till
;*                  var 16.384:e ms. Programhopp sker till motsvarande
;*                  avbrottsrutin ISR_TIMER2_OVF f�r att hantera avbrottet.
;********************************************************************************/
.ORG TIMER2_OVF_vect
   RJMP ISR_TIMER2_OVF

;/********************************************************************************
;* TIMER1_COMPA_vect: Avbrottsvektor f�r Timer 1 i CTC Mode, som hoppas till
;*                    var 16.384:e ms. Programhopp sker till motsvarande
;*                    avbrottsrutin ISR_TIMER1_COMPA f�r att hantera avbrottet.
;********************************************************************************/
.ORG TIMER1_COMPA_vect
   RJMP ISR_TIMER1_COMPA

;/********************************************************************************
;* TIMER0_OVF_vect: Avbrottsvektor f�r Timer 0 i Normal Mode, som hoppas till
;*                  var 16.384:e ms. Programhopp sker till motsvarande
;*                  avbrottsrutin ISR_TIMER0_OVF f�r att hantera avbrottet.
;********************************************************************************/
.ORG TIMER0_OVF_vect
   RJMP ISR_TIMER0_OVF

;/********************************************************************************
;* ISR_TIMER0_OVF: Avbrottsrutin f�r Timer 0 i Normal Mode, som �ger rum var 
;*                 16.384:e ms vid overflow (uppr�kning till 256, d� r�knaren 
;*                 blir �verfull). Ungef�r var 100:e ms (var 6:e avbrott) 
;*                 togglas lysdiod LED1.
;********************************************************************************/
ISR_TIMER0_OVF:
   LDS COUNTER_REG, timer0_counter   ; L�ser in v�rdet p� timer0_counter fr�n dataminnet.
   INC COUNTER_REG                   ; R�knar upp antalet exekverade avbrott.
   CPI COUNTER_REG, TIMER0_MAX_COUNT ; J�mf�r antalet avbrott med heltalet 6.
   BRLO ISR_TIMER0_OVF_end           ; Om mindre �n 6 avbrott har skett avslutas avbrottsrutinen.
   OUT PINB, LED1_REG                ; Annars togglas lysdiod 1.
   LDI COUNTER_REG, 0x00             ; Nollst�ller r�knaren inf�r n�sta uppr�kning.
ISR_TIMER0_OVF_end:
   STS timer0_counter, COUNTER_REG   ; Skriver det uppdaterade v�rdet p� timer0_counter till dataminnet.
   RETI                              ; Avslutar avbrottsrutinen, �terst�ller diverse register med mera.
   
;/********************************************************************************
;* ISR_TIMER1_COMPA: Avbrottsrutin f�r Timer 1 i CTC Mode, som �ger rum var 
;*                   16.384:e ms vid vid uppr�kning till 256. Ungef�r var 
;*                   200:e ms (var 12:e avbrott) togglas lysdiod LED2.
;********************************************************************************/
ISR_TIMER1_COMPA:
   LDS COUNTER_REG, timer1_counter   ; L�ser in v�rdet p� timer1_counter fr�n dataminnet.
   INC COUNTER_REG                   ; R�knar upp antalet exekverade avbrott.
   CPI COUNTER_REG, TIMER1_MAX_COUNT ; J�mf�r antalet avbrott med heltalet 12.
   BRLO ISR_TIMER1_COMPA_end         ; Om mindre �n 12 avbrott har skett avslutas avbrottsrutinen.
   OUT PINB, LED2_REG                ; Annars togglas lysdiod 2.
   LDI COUNTER_REG, 0x00             ; Nollst�ller r�knaren inf�r n�sta uppr�kning.
ISR_TIMER1_COMPA_end :
   STS timer1_counter, COUNTER_REG   ; Skriver det uppdaterade v�rdet p� timer1_counter till dataminnet.
   RETI                              ; Avslutar avbrottsrutinen, �terst�ller diverse register med mera.

;/********************************************************************************
;* ISR_TIMER2_OVF: Avbrottsrutin f�r Timer 2 i Normal Mode, som �ger rum var 
;*                 16.384:e ms vid overflow (uppr�kning till 256, d� r�knaren 
;*                 blir �verfull). Ungef�r var 500:e ms (var 31:e avbrott) 
;*                 togglas lysdiod LED3.
;********************************************************************************/
ISR_TIMER2_OVF:
   LDS COUNTER_REG, timer2_counter   ; L�ser in v�rdet p� timer1_counter fr�n dataminnet.
   INC COUNTER_REG                   ; R�knar upp antalet exekverade avbrott.
   CPI COUNTER_REG, TIMER2_MAX_COUNT ; J�mf�r antalet avbrott med heltalet 31.
   BRLO ISR_TIMER2_OVF_end           ; Om mindre �n 31 avbrott har skett avslutas avbrottsrutinen.
   OUT PINB, LED3_REG                ; Annars togglas lysdiod 3.
   LDI COUNTER_REG, 0x00             ; Nollst�ller r�knaren inf�r n�sta uppr�kning.
ISR_TIMER2_OVF_end:
   STS timer2_counter, COUNTER_REG   ; Skriver det uppdaterade v�rdet p� timer2_counter till dataminnet.
   RETI                              ; Avslutar avbrottsrutinen, �terst�ller diverse register med mera.

;/********************************************************************************
;* main: Initierar systemet vid start. Programmet h�lls sedan ig�ng s� l�nge
;*       matningssp�nning tillf�rs.
;********************************************************************************/
main:
;/********************************************************************************
;* setup: S�tter lysdiodernas pinnar till utportar samt aktiverar timerkretsarna
;*        s� att avbrott sker var 16.384:e millisekund f�r respektive timer.
;*        Notering: 256 = 1 0000 0000, som skrivs till OCR1AH respektive OCR1AL.
;********************************************************************************/
setup:
   LDI R16, (1 << LED1) | (1 << LED2) | (1 << LED3)  ; Lagrar 0000 0111 i R16.
   OUT DDRB, R16                                     ; S�tter lysdioderna till utportar.
   SEI                                               ; Aktiverar avbrott globalt.
init_timer0:
   LDI R16, (1 << CS02) | (1 << CS00)                ; S�tter prescaler till 1024.
   OUT TCCR0B, R16                                   ; Aktiverar Timer 0 i Normal Mode.
   LDI R18, (1 << TOIE0)                             ; Ettst�ller bit f�r avbrott i Normal Mode.
   STS TIMSK0, R18                                   ; Aktiverar OVF-avbrott f�r Timer 0.
init_timer1:
   LDI R16, (1 << CS12) | (1 << CS10) | (1 << WGM12) ; S�tter prescaler till 1024.
   STS TCCR1B, R16                                   ; Aktiverar Timer 1 i CTC Mode.
   LDI R17, 0x01                                     ; Lagrar 0000 0001 i R17.
   LDI R16, 0x00                                     ; Lagrar 0000 0000 i R16.
   STS OCR1AH, R17                                   ; Tilldelar �tta mest signifikanta bitar av 256.
   STS OCR1AL, R16                                   ; Tilldelar �tta minst signifikanta bitar av 256.
   LDI R16, (1 << OCIE1A)                            ; Ettst�ller bit f�r avbrott i CTC Mode.
   STS TIMSK1, R16                                   ; Aktiverar CTC-avbrott f�r Timer 1.
init_timer2:
   LDI R16, (1 << CS22) | (1 << CS21) | (1 << CS20)  ; S�tter prescaler till 1024.
   STS TCCR2B, R16                                   ; Aktiverar Timer 2 i Normal Mode.
   STS TIMSK2, R18                                   ; Aktiverar OVF-avbrott f�r Timer 2.
init_registers:
   LDI LED1_REG, (1 << LED1)                         ; Anv�nds f�r att toggla lysdiod 1.
   LDI LED2_REG, (1 << LED2)                         ; Anv�nds f�r att toggla lysdiod 2.
   LDI LED3_REG, (1 << LED3)                         ; Anv�nds f�r att toggla lysdiod 3.
   
/********************************************************************************
* main_loop: Kontinuerlig loop som h�ller ig�ng programmet.
********************************************************************************/
main_loop:   
   RJMP main_loop ; �terstartar kontinuerligt loopen.