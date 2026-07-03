
BuffSize EQU       1024                     ; velikost bufferu souboru

;DEBUG    EQU       1                        ; pøíznak testovacího módu

DELKOBR  EQU       (16*16/8)*4              ; délka jednoho obrázku

POCVECI  EQU       20                       ; poèet vìcí

LOK      EQU       1                        ; lokomotiva
LO1      EQU       LOK + 0                  ; lokomotiva VLEVO
LO2      EQU       LOK + 1                  ; lokomotiva NAHORU
LO3      EQU       LOK + 2                  ; lokomotiva VPRAVO
LO4      EQU       LOK + 3                  ; lokomotiva DOLÙ

LO5      EQU       LOK + 4                  ; lokomotiva VLEVO
LO6      EQU       LOK + 5                  ; lokomotiva NAHORU
LO7      EQU       LOK + 6                  ; lokomotiva VPRAVO
LO8      EQU       LOK + 7                  ; lokomotiva DOLÙ

LO9      EQU       LOK + 8                  ; lokomotiva VLEVO
LOA      EQU       LOK + 9                  ; lokomotiva NAHORU
LOB      EQU       LOK + 10                 ; lokomotiva VPRAVO
LOC      EQU       LOK + 11                 ; lokomotiva DOLÙ

SRAZKA   EQU       LOK+12                   ; srážka (10 fází)
SR1      EQU       SRAZKA+0
SR2      EQU       SRAZKA+1
SR3      EQU       SRAZKA+2
SR4      EQU       SRAZKA+3
SR5      EQU       SRAZKA+4
SR6      EQU       SRAZKA+5
SR7      EQU       SRAZKA+6
SR8      EQU       SRAZKA+7
SR9      EQU       SRAZKA+8
SRA      EQU       SRAZKA+9

ZED      EQU       SRAZKA+10                ; zeï

VRA      EQU       ZED+1                    ; vrata (6 fází)

VAGONY   EQU       VRA+6                    ; vagony (každý vagon 4 smìry)

VECI     EQU       VAGONY + 4*POCVECI       ; vìci

;KRY      EQU       0  * 3 + VECI            ; 1: krystal
;KOR      EQU       1  * 3 + VECI            ; 2: koruna
;STO      EQU       2  * 3 + VECI            ; 3: strom
;JAB      EQU       3  * 3 + VECI            ; 4: jablko
;KRA      EQU       4  * 3 + VECI            ; 5: kráva
;TRE      EQU       5  * 3 + VECI            ; 6: tøešnì
;RYB      EQU       6  * 3 + VECI            ; 7: rybník
;ZIR      EQU       7  * 3 + VECI            ; 8: žirafa
;ZMR      EQU       8  * 3 + VECI            ; 9: zmrzlina
;DOR      EQU       9  * 3 + VECI            ; 10: dort
;POC      EQU       10 * 3 + VECI            ; 11: poèítaè
;AUT      EQU       11 * 3 + VECI            ; 12: auto
;BAL      EQU       12 * 3 + VECI            ; 13: balón
;BUD      EQU       13 * 3 + VECI            ; 14: budík
;SLO      EQU       14 * 3 + VECI            ; 15: slon
;VIN      EQU       15 * 3 + VECI            ; 16: víno
;PEN      EQU       16 * 3 + VECI            ; 17: peníze
;LET      EQU       17 * 3 + VECI            ; 18: letadlo
;RZ1      EQU       18 * 3 + VECI            ; 19: ... rezerva 1
;RZ2      EQU       19 * 3 + VECI            ; 20: ... rezerva 2

Code     SEGMENT
         ASSUME    cs:Code,ds:Data

; ------ inicializace registrù

Start:   mov       ax,SEG Data
         mov       ds,ax
         mov       ds:[SegmPSP],es          ; segment PSP

; ------ zmenšení bloku programu

         mov       bx,ss                    ; segment zásobníku
         add       bx,(2*200h + 100h)/ 16   ; pøiètení velikosti zásobníku
         mov       ax,es
         sub       bx,ax                    ; velikost programu
         mov       ah,4ah
         int       21h                      ; zmenšení alokaèního bloku

; ------ naètení souboru obrázkù PCX

         call      ReadPCX                  ; naètení souboru obrázkù PCX
         mov       dx,offset PCXTxt         ; text - chyba PCX
         jc        Start11                  ; chyba PCX

; ------ naètení souboru scén SCN

         call      ReadSCN                  ; naètení souboru scén SCN
         mov       dx,offset SCNTxt         ; text - chyba SCN
         jc        Start11                  ; chyba SCN

; ------ inicializace videokarty

         call      InitVMod                 ; inicializace videomódu
         jnc       Start1                   ; inicializace je OK

; ------ chyba - nepovolená videokarta

Start10: mov       dx,offset CardTxt        ; text - není karta EGA/VGA
Start11: mov       ah,9
         int       21h                      ; zobrazení textu DOS
         mov       ax,4c01h
         int       21h

; ------ inicializace hodin

Start1:  call      CekInit                  ; inicializace hodin

; ------ inicializace adres obrázkù

         call      InitObr                  ; inicializace adres obrázkù

; ------ obsluha demonstrace

Start2:  call      Demo                     ; obsluha demonstrace

; ------ zrušení znaku klávesy

         mov       ah,0
         int       16h

; ------ ESC nebo Ctrl-Break - pøerušení hry

         or        ax,ax
         jz        Start3
         cmp       al,27
         jne       Start4

; ------ ukonèení hry

Start3:  call      SoundOff                 ; vypnutí zvuku
         mov       ah,0
         mov       al,ds:[OldVMod]          ; pùvodní videomód
         call      Int10                    ; návrat videomódu

         push      ds
         mov       dx,ds:[UvTxt]            ; adresa úvodního textu
         mov       ax,SEG ScenSegm
         mov       ds,ax
         mov       ah,9
         int       21h                      ; zobrazení úvodního textu
         pop       ds

         mov       ax,4c00h
         int       21h                      ; konec programu

; ------ start scény

Start4:  mov       al,ds:[AktScen]
         call      InitScen                 ; inicializace scény AL (0=DEMO)
         call      DispScen
         call      DispInf                  ; zobrazení informaèního øádku
Start41: call      FlushKey                 ; vyprázdìní bufferu klávesnice
         mov       word ptr ds:[Autom],0    ; není automat

; ------ èekání na èas pro jeden krok

Start5:  call      TestTime                 ; inicializace èítaèe èasu
         jc        Start5                   ; není krok

; ------ test stisku klávesy

         mov       ah,1
         int       16h                      ; je stisk klávesy ?
         jz        Start535                 ; není stisk klávesy

; ------ F4 zadání hesla

         cmp       ax,3e00h                 ; F4
         jne       Start530
         mov       ah,0
         int       16h
         jmp       Heslo

; ------ ESC nebo Ctrl-Break - pøerušení hry

Start530:or        ax,ax
         jz        Start531
         cmp       al,27
         jne       Start532
Start531:mov       ah,0
         int       16h
         jmp       Start61

; ------ F1 - automatický režim

Start532:cmp       ax,3b00h                 ; F1
         jne       Start534                 ; není F1
         cmp       word ptr ds:[Smer],0     ; pohybuje se již vlak ?
         jne       Start534                 ; pohybuje se již
         cmp       word ptr ds:[Autom],0    ; je již automatický režim ?
         jne       Start534                 ; je již automatický režim
         mov       ah,0
         int       16h                      ; zrušení znaku z klávesnice
         call      InitAuto                 ; inicializace automatického režimu

; ------ F2 - zvuk

Start534:cmp       ax,3c00h                 ; F2
         jne       Start535
         mov       ah,0
         int       16h
         xor       byte ptr ds:[Zvuk],1

; ------ zvýšení fáze objektù

Start535:call      IncFaze                  ; zvýšení fáze
         call      OpenVrat                 ; otevøení vrat

; ------ smìr lze zmìnit pouze pøi fázi 0

         cmp       byte ptr ds:[Faze],0     ; je fáze 0 ?
         jne       Start5                   ; ne - další krok

; ------ zmìna smìru automatem

         call      GetAuto                  ; smìr z automatického režimu
         jnc       Start652                 ; je automat - posun

; ------ naètení další klávesy

STart60: mov       ah,1
         int       16h
         jz        Start69                  ; není klávesa
Start603:mov       ah,0
         int       16h                      ; naètení klávesy

; ------ F2 - zvuk

         cmp       ax,3c00h                 ; F2
         jne       Start604
         xor       byte ptr ds:[Zvuk],1
         jmp       short Start60

; ------ F4 - zadání hesla

Start604:cmp       ax,3e00h                 ; F4
         jne       Start606
         jmp       Heslo                    ; zadání hesla

; ------ pøerušení scény ESC nebo Ctrl-Break

Start606:or        ax,ax
         jz        Start61
         cmp       al,27
         jne       Start62
Start61: call      SoundOff
         jmp       Start2

; ------ zmìna smìru pøi stisku klávesy

Start62: cmp       ah,48h
         jne       Start63
         mov       dx,0ff00h                ; nahoru
         jmp       short Start652

Start63: cmp       ah,4bh
         jne       Start64
         mov       dx,0ffh                  ; vlevo
         jmp       short Start652

Start64: cmp       ah,4dh
         jne       Start65
         mov       dx,1                     ; vpravo
         jmp       short Start652

Start65: cmp       ah,50h
         jne       Start60
         mov       dx,1*256                 ; dolù

; ------ nastavení nového smìru podle DX

Start652:cmp       dx,word ptr ds:[Smer]
         je        Start60                  ; smìr je již nastaven
         mov       ds:[Smer],dx             ; nový smìr

; ------ test, zda bude posun vlaku

Start69: mov       dx,ds:[Smer]
         or        dx,dx
         jz        Start6

; ------ test srážky na nové pozici pøi posunu o DX

         call      TestSraz                 ; test srážky vlaku
         jnc       Start6a                  ; není srážka
         jmp       Start8                   ; havárie

; ------ posun vlaku smìrem DX

Start6a: call      PosVlak                  ; posun vlaku ve smìru DX

; ------ test, zda je vlak již ve vratech (tj. konec scény)

         mov       dx,word ptr ds:[MapVlak+1]
         cmp       dx,ds:[PozVrat]
         je        Start7                   ; konec hry
Start6:  jmp       Start5

; ------ úspìšné ukonèení scény

Start7:  mov       word ptr ds:[CitSound],0 ; vypnutí všech zvukù

         mov       bx,2200
         mov       ax,800
         mov       dx,250
         mov       cx,2
Start711:call      SetSound
         xchg      ax,bx
         call      Cekej
         call      SetSound
         xchg      ax,bx
         call      Cekej
         sub       bx,8
         dec       dx
         jnz       Start711
         call      SoundOff

         call      ClosScen                 ; uzavøení scény

         cmp       word ptr ds:[Autom],0    ; byl to automat ?
         jne       Start713                 ; byl to automat

         inc       byte ptr ds:[AktScen]    ; zvýšení èísla scény

Start713:call      ClearInf                 ; vymazání informaèního øádku

         mov       ax,ds:[NumScen]          ; poèet scén
         cmp       ds:[AktScen],al          ; je to poslední scéna ?
         jbe       Start72                  ; není poslední scéna
         mov       byte ptr ds:[AktScen],1  ; posun na 1. scénu
         jmp       Absol                    ; absolutní vítìz hry

Start72: call      DispAScn                 ; zobrazení informací aktuální scény

         call      FlushKey                 ; vyprázdìní bufferu klávesnice

         mov       ah,0
         int       16h                      ; èekání na stisk libovolné klávesy

         mov       al,ds:[AktScen]          ; aktuální scéna
         call      InitScen                 ; inicializace scény AL

         call      OpenScen                 ; otevøení scény

         call      DispInf                  ; zobrazení informaèního øádku

         jmp       Start41                  ; nový start hry

; ------ havárie

Start8:  mov       byte ptr ds:[MapVlak],0  ; pøíznak srážky

         call      DispKec                  ; zobrazení hlášení pøi srážce

         mov       word ptr ds:[CitVyb],120  ; èítaè výbuchu

         mov       al,SR1                   ; srážka
Start80: mov       dx,word ptr ds:[MapVlak+1]
         call      DispObr

Start81:
         cmp       word ptr ds:[CitVyb],0
         je        Start86
         dec       word ptr ds:[CitVyb]
         jnz       Start85
         call      SoundOff
         jmp       short Start86

Start85: push      ax
         mov       bx,ds:[CitVyb]
         mov       ax,420
         sub       ax,ds:[CitVyb]
         shl       ax,1
         shl       ax,1
         shl       ax,1
         shl       ax,1
         mov       bx,word ptr cs:[bx+cs:Start]
         and       bx,0fffh
         add       ax,bx
         call      SetSound
         pop       ax

Start86:
         mov       cx,9
         call      Cekej

         call      TestTime
         jc        Start81

         call      IncFaze

         inc       ax
         cmp       al,SRA+1
         jb        Start80

         mov       al,SR8

         push      ax
         mov       ah,1
         int       16h
         pop       ax
         jz        Start80

         call      SoundOff

Start82: call      FlushKey
Start83: jmp       Start4

; -----------------------------------------------------------------------------
;        demonstrace (ukonèení stiskem kterékoliv klávesy)
; -----------------------------------------------------------------------------
; 
Demo     PROC      NEAR

; ------ úschova aktivní scény

         mov       al,ds:[AktScen]          ; aktivní scéna
         push      ax                       ; úschova aktivní scény

; ------ èíslo další scény

Demo1:   cmp       byte ptr ds:[AktScen],0  ; byla DEMO scéna ?
         mov       al,0                     ; bude DEMO scéna
         jne       Demo16                   ; nebyla DEMO scéna
Demo12:  mov       si,ds:[RndUkaz]          ; ukazatel náhody
         mov       al,cs:[si]               ; náhodný bajt
         push      ds
         xor       bx,bx
         mov       ds,bx
         xor       al,ds:[46ch]
         pop       ds
         inc       si
         cmp       si,1000h
         jb        Demo14
         xor       si,si
Demo14:  mov       ds:[RndUkaz],si
         or        al,al
         jz        Demo12
         cmp       al,byte ptr ds:[NumScen]
         ja        Demo12
Demo16:  mov       ds:[AktScen],al

; ------ inicializace a zobrazení scény AL

         call      InitScn0                 ; inicializace scény AL (0=DEMO)
         call      ClearInf                 ; vymazání informaèního øádku
         cmp       byte ptr ds:[AktScen],0  ; je DEMO scéna ?
         je        Demo18                   ; je DEMO scéna
         call      DispInf                  ; zobrazení informaèního øádku
Demo18:  call      DispScen                 ; zobrazení scény
         mov       byte ptr ds:[CitTit],0   ; èítaè titulku
         mov       word ptr ds:[AutomCek],0 ; èítaè èekání po DEMO
         mov       word ptr ds:[Autom],0    ; není automat
         call      InitAuto                 ; inicializace automatického režimu

; ------ test stisku klávesy

Demo2:   mov       ah,1
         int       16h                      ; je stisk klávesy ?
         jnz       Demo8                    ; je stisk klávesy

; ------ test, zda bude krok

         call      TestTime                 ; test èasu
         jc        Demo2                    ; èekání na èas pro jeden krok

; ------ zvýšení fáze objektù

         call      IncFaze                  ; zvýšení fáze
         call      OpenVrat                 ; otevøení vrat

; ------ posun bude pouze pøi fázi 0

         cmp       byte ptr ds:[Faze],0     ; bude posun ?
         jne       Demo2                    ; nebude posun

; ------ naètení posunu vlaku

         call      GetAuto                  ; další posun vlaku pro DEMO
         jnc       Demo3                    ; je další krok
         inc       word ptr ds:[AutomCek]   ; èítaè èekání
         cmp       word ptr ds:[AutomCek],1*(18/2/3) ; èekání po DEMO
         jb        Demo2                    ; další èekání
         jmp       Demo1                    ; další scéna

; ------ posun vlaku

Demo3:   mov       ds:[Smer],dx             ; nový smìr vlaku
         or        dx,dx                    ; bude posun vlaku ?
         jz        Demo2                    ; nebude posun vlaku
         call      TestSraz                 ; test srážky vlaku
         jnc       Demo4                    ; není srážka
Demo32:  xor       ax,ax
         mov       ds:[Smer],ax             ; zastavení vlaku
         mov       ds:[Autom],ax            ; zastavení automatu
         jmp       short Demo2
Demo4:   call      PosVlak                  ; posun vlaku

; ------ posun titulku

         cmp       byte ptr ds:[AktScen],0  ; je DEMO scéna ?
         jne       Demo5                    ; není DEMO scéna
         mov       al,ds:[MapVlak+1]        ; pozice vlaku
         shl       al,1                     ; pozice vlaku * 2
         sub       al,2                     ; bez poèátku
         jbe       Demo5                    ; nepovolená pozice
         cmp       al,34
         ja        Demo5                    ; nepovolená pozice
         cmp       byte ptr ds:[CitTit],34  ; je již titulek maximální ?
         jae       Demo5                    ; titulek je již maximální
         mov       ds:[CitTit],al           ; nová délka titulku
         call      DispTit                  ; zobrazení titulku

; ------ test, zda je vlak již ve vratech

Demo5:   mov       ax,word ptr ds:[MapVlak+1] ; pozice vlaku
         cmp       ax,ds:[PozVrat]          ; je již ve vratech ?
         jne       Demo2                    ; není ještì ve vratech
         jmp       short Demo32

; ------ F2 - zvuk

Demo8:   cmp       ax,3c00h                 ; F2
         jne       Demo9
         mov       ah,0
         int       16h
         xor       byte ptr ds:[Zvuk],1
         jmp       Demo2

; ------ návrat pùvodní aktivní scény

Demo9:   pop       ax
         mov       ds:[AktScen],al          ; návrat pùvodní aktivní scény
         ret

Demo     ENDP

; -----------------------------------------------------------------------------
;        inicializace automatického režimu (NZ=není)
; -----------------------------------------------------------------------------

InitAuto PROC      NEAR

         push      ds
         mov       ah,0
         mov       al,ds:[AktScen]          ; aktivní scéna
         shl       ax,1                     ; AX = offset adresy
         xchg      ax,si                    ; SI <- offset adresy
         mov       si,ds:[si+AdrScen]       ; adresa scény
         mov       ax,SEG ScenSegm          ; AX <- segment scén
         mov       ds,ax                    ; DS <- segment scén
         cld
InitAut2:lodsb                              ; naètení znaku
         cmp       al," "                   ; je platný znak ?
         jbe       InitAut2                 ; vypuštìní neplatných znakù
         cmp       al,"!"                   ; je DEMO ?
         pop       ds
         jne       InitAut4                 ; není DEMO
         mov       ds:[Autom],si            ; ukazatel pro DEMO
InitAut4:ret

InitAuto ENDP

; -----------------------------------------------------------------------------
;        poskytnutí smìru pro automatický pohyb -> DX (CY=není, DX=0 konec)
; -----------------------------------------------------------------------------

GetAuto  PROC      NEAR

; ------ test, zda je automat zapnut

         cmp       word ptr ds:[Autom],1    ; je automat ?
         jb        GetAuto9                 ; není automat

; ------ naètení dalšího znaku automatu

GetAuto2:mov       si,ds:[Autom]            ; ukazatel automatického režimu
GetAuto3:push      ds
         mov       ax,SEG ScenSegm
         mov       ds,ax                    ; segment definice scén
         cld
         lodsb                              ; naètení znaku
         pop       ds
         mov       ds:[Autom],si            ; nový ukazatel pro automatický režim

; ------ vypuštìní komentáøe

         cmp       al,";"
         jne       GetAuto5

         push      ds
         mov       ax,SEG ScenSegm
         mov       ds,ax                    ; segment definice scén
         cld
GetAuto4:lodsb
         cmp       al," "
         jae       GetAuto4
         pop       ds
         jmp       short GetAuto3

; ------ konverze na velké písmeno

GetAuto5:cmp       al,"a"
         jb        GetAuto6
         cmp       al,"z"
         ja        GetAuto6
         sub       al,32

; ------ nahoru

GetAuto6:mov       dx,0ff00h                ; nahoru
         cmp       al,"U"
         je        GetAuto8                 ; nahoru

; ------ vlevo

         mov       dx,00ffh                 ; vlevo
         cmp       al,"L"
         je        GetAuto8                 ; vlevo

; ------ vpravo

         mov       dx,0001h                 ; vpravo
         cmp       al,"R"
         je        GetAuto8                 ; vpravo

; ------ dolù

         mov       dx,0100h                 ; dolù
         cmp       al,"D"
         je        GetAuto8                 ; dolù

; ------ zastavení

         cmp       al,"S"
         je        GetAuto7
         cmp       al,"."
         je        GetAuto7
         cmp       al,"#"                   ; je již definice scény ?
         jne       GetAuto2
GetAuto7:xor       dx,dx                    ; DX <- 0 zastavení
         mov       ds:[Autom],dx            ; ukonèení automatického režimu

GetAuto8:clc
GetAuto9:ret

GetAuto  ENDP

; -----------------------------------------------------------------------------
;        test srážky vlaku pøi posunu ve smìru DX (CY=bude srážka)
; -----------------------------------------------------------------------------

TestSraz PROC      NEAR

; ------ prvek na nové pozici

         push      dx
         add       dl,ds:[MapVlak+1]
         add       dh,ds:[MapVlak+2]
         mov       al,20                    ; poèet pozic
         mul       dh                       ; pøepoèet øádku na offset
         add       al,dl
         adc       ah,0
         add       ax,offset Pole
         xchg      ax,si                    ; SI <- adresa v poli
         mov       al,ds:[si]               ; prvek na nové pozici
         pop       dx

; ------ test, zda bude srážka

         cmp       al,0                     ; mezera ?
         je        TestSra6                 ; je prázdné políèko
         cmp       al,VECI                  ; posbírá vìc ?
         jae       TestSra4                 ; posbírá vìc
         cmp       al,VRA+1                 ; budou otevøená vrata ?
         jb        TestSra2                 ; jsou zavøená vrata nebo vlak
         cmp       al,VRA+6                 ; otevøená vrata ?
         jb        TestSra6                 ; jsou otevøená vrata
TestSra2:stc                                ; havárie
         ret

; ------ bude posbírání vìci

TestSra4:mov       word ptr ds:[AdrSound],offset TabSVec
         mov       word ptr ds:[CitSound],offset(TabSVec0-TabSVec) + 1
         jmp       short TestSra8

; ------ bude jen posun lokomotivy

TestSra6:mov       word ptr ds:[AdrSound],offset TabSLok
         mov       word ptr ds:[CitSound],offset(TabSLok0-TabSLok) + 1
TestSra8:clc
         ret

TestSraz ENDP

; -----------------------------------------------------------------------------
;        zobrazení informací aktuální scény (pøed otevøením scény)
; -----------------------------------------------------------------------------

DispAScn PROC      NEAR

         mov       di,(24/2-1)*8*40 + (40-10)/2
         mov       si,offset ScenTxt
         mov       ah,10
         call      DispTxt

         mov       al,ds:[AktScen]
         mov       ah,0
         mov       ch,14
         call      DispNum

         mov       al," "
         call      DispChr

         mov       di,(24/2+1)*8*40 + (40-13)/2
         mov       ah,10
         mov       si,offset Hes2Txt
         call      DispTxt

         mov       al,5
         mul       byte ptr ds:[AktScen]
         add       ax,offset TabHesel
         xchg      ax,si
         mov       ah,14
         mov       cx,5
DispASc2:cld
         lodsb
         call      DispChr
         loop      DispASc2

         mov       al," "
         call      DispChr
         ret

DispAScn ENDP

; *****************************************************************************
;
;                          Obsluha souborù
;
; *****************************************************************************

; -----------------------------------------------------------------------------
;        sestavení jména k domovskému souboru (pøípona DS:BX) -> DS:DX
; -----------------------------------------------------------------------------

HomeFile PROC      NEAR

; ------ nalezení jména souboru

         push      ds
         push      ds
         pop       es                       ; ES <- datový segment
         mov       ds,ds:[SegmPSP]          ; DS <- segment PSP
         mov       ds,ds:[2ch]              ; segment prostøedí
;         mov       es:[BlokPlay],ds         ; adresa prostøedí
         xor       si,si
HomeFil1:inc       si
         cmp       word ptr ds:[si-1],0
         jne       HomeFil1
         inc       si                       ; pøeskoèení koncové 0
         inc       si
         inc       si                       ; pøeskoèení poètu øetìzcù

; ------ pøenesení jména souboru

         cld
         mov       di,offset FileName       ; buffer jména souboru
         mov       dx,di                    ; DX <- jméno souboru
         xor       cx,cx                    ; CX <- 0 není pøípona
HomeFil2:lodsb                              ; naètení znaku
         cmp       al,"."
         jne       HomeFil3
         mov       cx,di                    ; adresa pøípony
HomeFil3:cmp       di,offset FileName+120
         jae       HomeFil4
         stosb
         cmp       al,0
         jne       HomeFil2
         dec       di

; ------ pøidání pøípony

HomeFil4:jcxz      HomeFil5                 ; nenalezena pøípona
         mov       di,cx                    ; DI <- nalezená pøípona
HomeFil5:mov       al,"."
         stosb
         pop       ds
         mov       si,bx
         movsw
         movsw
         ret

HomeFile ENDP

; -----------------------------------------------------------------------------
;        naètení souboru obrázkù PCX (CY=chyba)
; -----------------------------------------------------------------------------

ReadPCX  PROC      NEAR

; ------ otevøení souboru PCX

         mov       bx,offset FilePCX        ; jméno souboru PCX
         call      HomeFile                 ; sestavení jména souboru
         mov       ax,3d00h
         int       21h                      ; otevøení souboru
         jc        ReadPCX9                 ; chyba otevøení souboru
         xchg      ax,bx                    ; BX <- identifikátor souboru

; ------ pøíprava k naètení souboru

         mov       ax,SEG ObrSegm           ; segment obrázkù
         mov       es,ax                    ; ES <- segment obrázkù
         mov       ax,100h                  ; AH <- 1 není další bajt
         cld
         xor       di,di                    ; ukládací adresa do bufferu

; ------ naètení bufferu

         call      ReadBuff                 ; naètení bufferu
         jc        ReadPCX8                 ; chyba
         add       si,128                   ; pøeskoèení záhlaví
         sub       cx,128                   ; odeètení záhlaví
         jb        ReadPCX8                 ; chyba

; ------ ovìøení záhlaví PCX

         cmp       byte ptr ds:[Buffer],10
         stc
         jne       ReadPCX8

; ------ naètení souboru

         mov       dx,40*200*4              ; poèet bajtù k naètení
ReadPCX2:call      ReadByte                 ; naètení dalšího bajtu
         jc        ReadPCX8                 ; chyba
         stosb                              ; uložení bajtu
         dec       dx                       ; èítaè bajtù
         jnz       ReadPCX2                 ; další bajt

; ------ uzavøení souboru

ReadPCX8:pushf
         mov       ah,3eh
         int       21h                      ; uzavøení souboru
         popf
ReadPCX9:ret

ReadPCX  ENDP

; -----------------------------------------------------------------------------
;        naètení jednoho bajtu ze vstupního bufferu (je CLD !)
; -----------------------------------------------------------------------------
; VSTUP: AL=stará hodnota bajtu
;        AH=èítaè opakování bajtu (1=bude další bajt)
;        DS:SI=adresa bufferu
;        CX=poèet zbylých bajtù
;        CLD=smìr nahoru
; VÝSTUP: CY=chyba
; -----------------------------------------------------------------------------

ReadByte PROC      NEAR

; ------ další opakování bajtu AL

         dec       ah                       ; èítaè opakování bajtu
         jnz       ReadByt6                 ; je další opakování bajtu

; ------ naètení dalšího bajtu z bufferu

ReadByt0:jcxz      ReadByt8                 ; je již konec bufferu
ReadByt1:lodsb                              ; naètení dalšího bajtu
         dec       cx                       ; snížení èítaèe bajtù

; ------ test, zda je opakování bajtu

         mov       ah,1                     ; bajt se nebude opakovat
         cmp       al,0c0h                  ; je platný datový bajt ?
         jb        ReadByt6                 ; je platný datový bajt

; ------ úschova poètu opakování bajtu

         and       al,3fh                   ; poèet opakování bajtu
         mov       ah,al                    ; poèet opakování bajtu

; ------ naètení bajtu k opakování

         jcxz      ReadByt9                 ; je již konec bufferu
ReadByt2:lodsb                              ; naètení bajtu k opakování
         dec       cx                       ; snížení èítaèe bajtù
         or        ah,ah                    ; je nìjaký bajt ?
         jz        ReadByt0                 ; není bajt
ReadByt6:clc                                ; pøíznak operace OK
ReadByt7:ret

; ------ naètení dalších dat ze souboru do bufferu - èást 1

ReadByt8:call      ReadBuff                 ; naètení další èásti souboru
         jc        ReadByt7                 ; chyba
         stc
         jcxz      ReadByt7                 ; chyba
         jmp       short ReadByt1

; ------ naètení dalších dat ze souboru do bufferu - èást 2

ReadByt9:call      ReadBuff                 ; naètení další èásti souboru
         jc        ReadByt7
         stc
         jcxz      ReadByt7                 ; chyba
         jmp       short ReadByt2

ReadByte ENDP

; -----------------------------------------------------------------------------
;        naètení obsahu bufferu ze souboru BX -> SI=adresa, CX=bajtù, CY chyba
; -----------------------------------------------------------------------------

ReadBuff PROC      NEAR

         push      ax
         push      dx

         mov       dx,offset Buffer         ; vstupní buffer souboru
         mov       si,dx                    ; ukazatel na zaèátek bufferu
         mov       ah,3fh
         mov       cx,BuffSize              ; velikost bufferu
         int       21h                      ; naètení bufferu
         xchg      ax,cx                    ; CX <- poèet bajtù
         cld

         pop       dx
         pop       ax
         ret

ReadBuff ENDP

; -----------------------------------------------------------------------------
;        naètení souboru scén SCN
; -----------------------------------------------------------------------------
; 
ReadSCN  PROC      NEAR

; ------ otevøení souboru SCN

         mov       bx,offset FileSCN        ; jméno souboru SCN
         call      HomeFile                 ; sestavení jména souboru
         mov       ax,3d00h
         int       21h                      ; otevøení souboru
         jnc       ReadScn1
         jmp       ReadSCN9                 ; chyba otevøení souboru

ReadScn1:xchg      ax,bx                    ; BX <- identifikátor souboru

; ------ naètení souboru definice scén

         push      ds
         mov       ax,SEG ScenSegm          ; segment definice scén
         mov       ds,ax                    ; DS <- segment definice scén
         mov       ah,3fh
         xor       dx,dx
         mov       cx,-1                    ; max. velikost souboru
         int       21h                      ; naètení souboru
         pop       ds
         jnc       ReadSc12
         jmp       ReadSCN8                 ; chyba
ReadSc12:xchg      ax,cx                    ; CX <- poèet naètených bajtù

; ------ nalezení úvodního textu

         cld
         xor       si,si
         call      ReadScnL                 ; nalezení prvního platného øádku
         jc        ReadScn7                 ; není další øádek
         mov       ds:[UvTxt],si            ; adresa úvodního textu
ReadSc14:call      ReadScnC                 ; naètení znaku
         jc        ReadScn7
         cmp       al,"$"
         jne       ReadSc14

; ------ inicializace adres scén

         mov       di,offset AdrScen        ; adresy scén
         mov       bx,offset TabHesel       ; tabulka hesel
ReadScn2:call      ReadScnL                 ; nalezení prvního øádku
         jc        ReadScn7                 ; není další øádek

         mov       dl,5                     ; délka hesla
ReadSc21:call      ReadScnC                 ; naètení znaku
         jc        ReadScn7                 ; není další znak
         cmp       al," "
         ja        ReadSc22
         dec       si
         mov       al," "
ReadSc22:cmp       al,"a"
         jb        ReadSc23
         cmp       al,"z"
         ja        ReadSc23
         sub       al,32
ReadSc23:mov       ds:[bx],al
         inc       bx
         dec       dl
         jnz       ReadSc21

ReadSc24:mov       ds:[di],si               ; adresa scény
         inc       di
         inc       di

         mov       dl,12                    ; poèet požadovaných øádkù

ReadScn3:call      ReadScnL                 ; nalezení zaèátku øádku
         jc        ReadScn7                 ; není další øádek

ReadSc32:call      ReadScnC
         cmp       al," "
         jbe       ReadSc32
         cmp       al,"!"
         jne       ReadSc36
ReadSc34:call      ReadScnC
         jc        ReadScn7
         cmp       al," "
         jae       ReadSc34
         jmp       short ReadScn3

ReadSc36:dec       si
         inc       cx
         mov       dh,20                    ; poèet požadovaných pozic
ReadScn4:call      ReadScnC                 ; naètení dalšího znaku
         jc        ReadScn7                 ; není další znak
         cmp       al," "
         jbe       ReadScn4
         dec       dh                       ; èítaè platných znakù
         jnz       ReadScn4                 ; další znak

         dec       dl                       ; èítaè øádkù
         jnz       ReadScn3                 ; další øádek

         inc       word ptr ds:[NumScen]    ; scéna je platná
         jmp       short ReadScn2           ; další scéna

; ------ uzavøení souboru

ReadScn7:cmp       byte ptr ds:[NumScen],3  ; minimálnì 1 DEMO + 1 scéna
         dec       word ptr ds:[NumScen]    ; bez DEMO scény
ReadSCN8:pushf
         mov       ah,3eh
         int       21h                      ; uzavøení souboru
         popf
ReadSCN9:ret

ReadSCN  ENDP

; -----------------------------------------------------------------------------
;        nalezení zaèátku platného øádku definice scény -> CY=není
; -----------------------------------------------------------------------------

ReadScnL:call      ReadScnC                 ; naètení znaku
         jc        ReadScL4                 ; není další znak
         cmp       al," "
         jbe       ReadScnL
         cmp       al,";"
         jne       ReadScL2

ReadScL1:call      ReadScnC                 ; naètení znaku
         jc        ReadScL4                 ; není další znak
         cmp       al,10
         jne       ReadScL1                 ; nalezení znaku LF
         jmp       short ReadScnL

ReadScL2:dec       si                       ; návrat znaku
         inc       cx                       ; návrat èítaèe znakù
         clc                                ; pøíznak platnosti znaku
ReadScL4:ret

; -----------------------------------------------------------------------------
;        naètení znaku z definice scén -> CY chyba
; -----------------------------------------------------------------------------

ReadScnC:stc
         jcxz      ReadScC2

         push      ds

         push      ax
         mov       ax,SEG ScenSegm          ; segment scén
         mov       ds,ax
         pop       ax

         lodsb
         dec       cx
         pop       ds
         clc

ReadScC2:ret

; -----------------------------------------------------------------------------
;        celkové ukonèení hry - absolutní vítìz
; -----------------------------------------------------------------------------
; 
Absol    PROC      NEAR

         mov       di,9*8*40+5
         mov       si,offset Bla1Txt
         mov       ah,14
         call      DispTxt
         mov       di,10*8*40+5
         call      DispTxt
         mov       di,11*8*40+5
         push      si
         mov       si,offset Bla1Txt
         call      DispTxt
         pop       si
         mov       ah,10
         mov       di,12*8*40+5
         call      DispTxt
         mov       di,13*8*40+5
         call      DispTxt
         mov       si,offset Bla1Txt
         mov       di,14*8*40+5
         call      DispTxt

         call      FlushKey
         mov       ah,0
         int       16h
         jmp       Start2                   ; návrat k demonstraci

Absol    ENDP

; -----------------------------------------------------------------------------
;        zadání hesla
; -----------------------------------------------------------------------------
; 
Heslo    PROC      NEAR

         push      ds
         pop       es

; ------ naètení aktivního hesla

         mov       al,5
         mul       byte ptr ds:[AktScen]
         add       ax,offset TabHesel
         xchg      ax,si
         mov       cx,5
         mov       di,offset BuffHes
         cld
         rep       movsb

; ------ zobrazení hesla

         mov       bx,offset BuffHes        ; ukazatel v bufferu hesla

Heslo2:
         mov       di,24*8*40 + 14
         mov       ah,12
         mov       si,offset Hes2Txt
         call      DispTxt

         mov       si,offset BuffHes
         mov       cx,5
Heslo23: mov       ah,14
         cmp       si,bx
         jne       Heslo232

;         mov       ah,9
;         mov       al," "
;         call      DispChr
;         dec       di

         mov       ah,14 + 80h
;         mov       ah,14 XOR 9 + 80h

Heslo232:cld
         lodsb
         call      DispChr
         loop      Heslo23

; ------ èekání na zadání klávesy

Heslo24: call      TestTime                 ; inicializace èítaèe èasu
         jc        Heslo25                  ; není krok
         call      IncFaze                  ; zvýšení fáze
         call      OpenVrat                 ; otevøení vrat

Heslo25: mov       ah,1
         int       16h
         jz        Heslo24
         mov       ah,0
         int       16h

         cmp       al,13
         je        Heslo5

; ------ pøerušení zadání ESC (nebo neplatné heslo)

         or        ax,ax
         jz        Heslo27
         cmp       al,27
         jne       Heslo3

Heslo27:
         call      DispInf
         jmp       Start60                  ; pøerušení bez další funkce

; ------ kurzor vpravo

Heslo3:  cmp       ax,4d00h
         je        Heslo42

; ------ kurzor vlevo

         cmp       al,8
         je        Heslo31
         cmp       al,7fh
         je        Heslo31
         cmp       ax,5300h
         je        Heslo31
         cmp       ax,4b00h
         jne       Heslo32
Heslo31: cmp       bx,offset BuffHes
         jbe       Heslo43
         dec       bx
         jmp       short Heslo43

; ------ vložení znaku

Heslo32: cmp       al,"a"
         jb        Heslo33
         cmp       al,"z"
         ja        Heslo33
         sub       al,32
Heslo33: cmp       al," "
         jb        Heslo24
;         je        Heslo34
;         cmp       al,"0"
;         jb        Heslo24
;         cmp       al,"9"
;         jbe       Heslo34
;         cmp       al,"A"
;         jb        Heslo24
;         cmp       al,"Z"
;         ja        Heslo24
Heslo34: mov       ds:[bx],al

Heslo42: cmp       bx,offset BuffHes+4
         jae       Heslo43
         inc       bx
Heslo43: jmp       Heslo2

; ------ ukonèení zadání hesla ENTER

Heslo5:  mov       si,offset TabHesel+5
         mov       dx,1                     ; ukazatel èísla scény
         cld
Heslo52: mov       di,offset BuffHes
         mov       cx,5
         push      si
         repe      cmpsb
         pop       si
         je        Heslo55
         add       si,5
         inc       dx
         cmp       dx,ds:[NumScen]
         jbe       Heslo52
         jmp       short Heslo27

Heslo55: mov       ds:[AktScen],dl
         jmp       Start4

Heslo    ENDP

; -----------------------------------------------------------------------------
;        uzavøení scény
; -----------------------------------------------------------------------------

ClosScen PROC      NEAR

         mov       dh,0
         mov       al,ZED
ClosScn1:mov       cx,20
         mov       dl,0
ClosScn2:call      DispObr
         inc       dx
         loop      ClosScn2
         mov       cx,60
         call      Cekej
         inc       dh
         cmp       dh,12
         jne       ClosScn1
         ret

ClosScen ENDP

; -----------------------------------------------------------------------------
;        otevøení scény
; -----------------------------------------------------------------------------

OpenScen PROC      NEAR

         mov       si,offset Pole+12*20-20
         mov       dh,11
OpenScn1:mov       cx,20
         mov       dl,0
OpenScn2:cld
         lodsb
         call      DispObr
         inc       dx
         loop      OpenScn2
         sub       si,2*20
         mov       cx,60
         call      Cekej
         dec       dh
         jns       OpenScn1
         ret

OpenScen ENDP

; -----------------------------------------------------------------------------
;        zobrazení scény
; -----------------------------------------------------------------------------

DispScen PROC      NEAR

         mov       si,offset Pole
         mov       dh,0
DispScn1:mov       cx,20
         mov       dl,0
DispScn2:cld
         lodsb
         cmp       al,LO1
         jne       DispScn3
         mov       al,LO3
DispScn3:call      DispObr
         inc       dx
         loop      DispScn2
         inc       dh
         cmp       dh,12
         jne       DispScn1
         ret

DispScen ENDP

; -----------------------------------------------------------------------------
;        vymazání informaèního øádku
; -----------------------------------------------------------------------------

ClearInf PROC      NEAR

         mov       di,24*8*40
         mov       ax,15*256+" "            ; znak a barva k vymazání
         mov       cx,40                    ;
ClearIn1:call      DispChr
         loop      ClearIn1
         ret

ClearInf ENDP

; -----------------------------------------------------------------------------
;        zobrazení informaèního øádku
; -----------------------------------------------------------------------------

DispInf  PROC      NEAR

         call      ClearInf                 ; vymazání informaèního øádku

; ------ úvodní text

DispInf1:mov       di,24*8*40
         mov       ah,10
         mov       si,offset SkorTxt
         call      DispTxt

         mov       di,24*8*40 + 40-6-3
         call      DispTxt

         mov       di,24*8*40 + 16
         mov       ah,12
         call      DispTxt

         mov       ch,14
         mov       al,ds:[AktScen]
         mov       ah,0
         mov       di,24*8*40 + 40-2
         call      DispNum

         call      DispSkor                 ; zobrazení skóre
         ret

DispInf  ENDP

; -----------------------------------------------------------------------------
;        zobrazení skóre
; -----------------------------------------------------------------------------

DispSkor PROC      NEAR

         push      ax
         push      cx
         push      dx
         push      di

         cmp       byte ptr ds:[AktScen],0  ; je DEMO scéna ?
         je        DispSko6                 ; je DEMO scéna

         mov       di,24*8*40 + 6
         mov       ch,14
         mov       ax,ds:[Skore]
         or        ax,ax
         jz        DispSko4
DispSko3:call      DispNum
DispSko4:mov       al,"0"
         mov       ah,14
         call      DispChr

DispSko6:pop       di
         pop       dx
         pop       cx
         pop       ax
         ret

DispSkor ENDP

; -----------------------------------------------------------------------------
;        otevøení vrat
; -----------------------------------------------------------------------------

OpenVrat PROC      NEAR

         push      ax
         push      cx
         push      dx
         push      si

         cmp       word ptr ds:[CitVeci],0
         jne       OpenVr8

         mov       dx,ds:[PozVrat]
         mov       al,20                    ; poèet pozic
         mul       dh                       ; pøepoèet øádku na offset
         add       al,dl
         adc       ah,0
         add       ax,offset Pole
         xchg      ax,si                    ; SI <- adresa v poli
         mov       al,ds:[si]
         cmp       al,VRA
         jb        OpenVr8
         cmp       al,VRA+5
         jae       OpenVr8

         inc       ax
         mov       ds:[si],al               ; nová fáze vrat
         call      DispObr

OpenVr8: pop       si
         pop       dx
         pop       cx
         pop       ax
         ret

OpenVrat ENDP

; -----------------------------------------------------------------------------
;        zvýšení fáze objektù
; -----------------------------------------------------------------------------

IncFaze  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      cx
         push      dx
         push      si

; ------ obsluha objektù

         mov       dh,0
         mov       si,offset Pole
         inc       byte ptr ds:[Faze]       ; èítaè fází
         cmp       byte ptr ds:[Faze],3
         jb        IncFaze1
         mov       byte ptr ds:[Faze],0
IncFaze1:mov       dl,0
IncFaze2:cld
         lodsb
         cmp       al,VECI
         jae       IncFaze3
         cmp       al,LO1
         jb        IncFaze5
         cmp       al,LOC
         ja        IncFaze5
         cmp       byte ptr ds:[MapVlak],0
         je        IncFaze5
         sub       al,LO1
         and       al,3
         mov       ah,ds:[Faze]
         shl       ah,1
         shl       ah,1
         add       al,ah
         add       al,LO1
         jmp       short IncFaze4
IncFaze3:inc       ax                       ; zvýšení fáze
         cmp       byte ptr ds:[Faze],0
         jne       IncFaze4
         sub       al,3
IncFaze4:mov       ds:[si-1],al
         call      DispObr
IncFaze5:inc       dx
         cmp       dl,20
         jne       IncFaze2
         inc       dh
         cmp       dh,12
         jne       IncFaze1

; ------ návrat registrù

         pop       si
         pop       dx
         pop       cx
         pop       ax
         ret

IncFaze  ENDP

; -----------------------------------------------------------------------------
;        èítání èasu pro jeden krok (CY=není krok)
; -----------------------------------------------------------------------------
; 
TestTime PROC      NEAR

         sti

         push      cx
         mov       cx,1
         call      Cekej
         pop       cx

         cmp       word ptr ds:[CitSound],0
         je        TestTim1

         dec       word ptr ds:[CitSound]
         jnz       TestTim0
TestT05: call      SoundOff
         jmp       short TestTim1

TestTim0:
         push      ax
         push      si
         mov       si,ds:[AdrSound]
         cld
         lodsw
         mov       ds:[AdrSound],si
         call      SetSound

         pop       si
         pop       ax

TestTim1:

         push      ax
         push      ds
         xor       ax,ax
         mov       ds,ax
         mov       ax,ds:[46ch]
         pop       ds
         sub       ax,ds:[LastTime]

IFDEF    DEBUG
         cmp       ax,3                     ; krok
ELSE
         cmp       ax,2                     ; krok
ENDIF

         jb        TestTim3                 ; není krok
         add       ds:[LastTime],ax         ; zvýšení èítaèe èasu
         clc                                ; pøíznak kroku
TestTim3:pop       ax
         ret

TestTime ENDP

; -----------------------------------------------------------------------------
;        posun vlaku ve smìru DX (DH=0,1,-1, DL=0,1,-1)
; -----------------------------------------------------------------------------
; 
PosVlak  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      bx
         push      cx
         push      dx
         push      si
         push      di

; ------ pøíprava registrù

         mov       si,offset MapVlak
         add       dl,ds:[si+1]             ; nová souøadnice lokomotivy
         add       dh,ds:[si+2]

; ------ posun souøadnic objektu

PosVlak2:mov       cx,ds:[si+1]             ; úschova starých souøadnic
         mov       ds:[si+1],dx             ; nová souøadnice objektu

; ------ stanovení nové fáze objektu

         mov       al,ds:[si]               ; báze objektu
         cmp       cl,-1                    ; je pozice známá ?
         jne       PosVlk22                 ; pozice je známá
         add       al,bh                    ; posun fáze
         jmp       short PosVlak4
PosVlk22:mov       ah,dl                    ; nová pozice
         mov       bh,0                     ; vlevo
         sub       ah,cl                    ; posun pozice
         je        PosVlak3                 ; pozice se nezmìnila
         js        PosVlak4                 ; posun vlevo
         mov       bh,2                     ; vpravo
         add       al,2
         jmp       short PosVlak4           ; posun vpravo
PosVlak3:inc       ax                       ; posun nahoru
         mov       bh,1                     ; nahoru
         mov       ah,dh                    ; nový øádek
         sub       ah,ch                    ; posun øádku
         js        PosVlak4                 ; je posun nahoru
         add       al,2                     ; jinak posun dolù
         mov       bh,3                     ; dolù

; ------ zobrazení objektu na nové pozici

PosVlak4:call      DispObr                  ; zobrazení obrázku

; ------ uložení objektu do mapy

         push      ax
         mov       al,20                    ; poèet pozic
         mul       dh                       ; pøepoèet øádku na offset
         add       al,dl
         adc       ah,0
         add       ax,offset Pole
         xchg      ax,di                    ; DI <- adresa v poli
         pop       ax
         xchg      al,ds:[di]               ; uložení objektu do mapy

; ------ pøi zrušení vìci vytvoøení nového vagonu

         sub       al,VECI                  ; byla to vìc ?
         jb        PosVlak6                 ; nebyla to vìc

         dec       word ptr ds:[CitVeci]    ; èítání vìcí
         cmp       byte ptr ds:[AktScen],0  ; je DEMO scéna ?
         je        PosVla42                 ; je DEMO scéna
         cmp       word ptr ds:[Skore],-1
         je        PosVla41
         cmp       word ptr ds:[Autom],0    ; je automat ?
         jne       PosVla41                 ; je automat
         inc       word ptr ds:[Skore]
PosVla41:call      DispSkor                 ; zobrazení skóre
PosVla42:mov       ah,0
         mov       bl,3
         div       bl                       ; èíslo vìci
         shl       al,1
         shl       al,1                     ; vagon * 4
         add       al,VAGONY                ; èíslo vagonu
         push      si
PosVlak5:add       si,3
         cmp       byte ptr ds:[si],0
         jne       PosVlak5
         mov       ds:[si],al
         mov       word ptr ds:[si+1],-1
         mov       byte ptr ds:[si+3],0
         pop       si

; ------ pøíprava pro další objekt

PosVlak6:add       si,3                     ; adresa dalšího objektu
         mov       dx,cx                    ; stará pozice pøedešlého objektu
         mov       al,0
         cmp       ds:[si],al               ; je již konec vlaku ?
         je        PosVlak7
         jmp       PosVlak2                 ; není konec - další vagon

; ------ vymazání posledního vagonu

PosVlak7:cmp       dl,-1
         je        PosVlak8
         call      DispObr                  ; vymazání posledního vagonu
         mov       al,20                    ; poèet pozic
         mul       dh                       ; pøepoèet øádku na offset
         add       al,dl
         adc       ah,0
         add       ax,offset Pole
         xchg      ax,di                    ; DI <- adresa v poli
         mov       byte ptr ds:[di],0

; ------ návrat registrù

PosVlak8:pop       di
         pop       si
         pop       dx
         pop       cx
         pop       bx
         pop       ax
         ret

PosVlak  ENDP

; -----------------------------------------------------------------------------
;        inicializace scény AL pro hru
; -----------------------------------------------------------------------------

InitScen PROC      NEAR

; ------ nová inicializace hodin (kdyby nìkdo pøepnul TURBO)

         call      CekInit                  ; inicializace hodin

; ------ úschova registrù

InitScn0:push      ax
         push      cx
         push      dx
         push      si
         push      di
         push      es

; ------ pøenesení definice scény

         cld
         push      ds
         pop       es                       ; ES <- datový segment

         push      ds
         mov       ah,0
         shl       ax,1                     ; AX = offset adresy
         xchg      ax,si
         mov       si,ds:[si+AdrScen]       ; adresa scény
         mov       ax,SEG ScenSegm          ; AX <- segment scén
         mov       ds,ax                    ; DS <- segment scén
         mov       di,offset Pole           ; zaèátek pole
         mov       cx,12*20                 ; velikost pole
InitScn1:lodsb
         cmp       al," "
         jbe       InitScn1
         cmp       al,"!"
         je        InitScn2
         cmp       al,";"
         jne       InitScn3
InitScn2:lodsb
         cmp       al,10
         jne       InitScn2
         jmp       short InitScn1

InitScn3:mov       ah,LO1
         cmp       al,"$"
         je        InitSc38
         mov       ah,VRA
         cmp       al,"@"
         je        InitSc38
         mov       ah,ZED
         cmp       al,"#"
         je        InitSc38

         cmp       al,"a"
         jb        InitSc32
         cmp       al,"z"
         ja        InitSc32
         sub       al,32
InitSc32:sub       al,"A"
         jb        InitSc37
         cmp       al,POCVECI
         jae       InitSc37
         mov       ah,3
         mul       ah
         add       al,VECI
         jmp       short InitSc39

InitSc37:mov       ah,0                     ; jinak neplatný

InitSc38:mov       al,ah
InitSc39:stosb
         loop      InitScn1
         pop       ds

; ------ inicializace scény

         mov       word ptr ds:[CitVeci],0  ; èítaè vìcí - není žádná vìc
         mov       dh,0                     ; ukazatel èísla øádku
         mov       si,offset Pole           ; definice hracího pole
InitScn4:mov       dl,0                     ; ukazatel èísla pozice
InitScn5:lodsb                              ; naètení bajtu definice
         cmp       al,VRA                   ; jsou to zavøená vrata ?
         jne       InitSc52                 ; nejsou to vrata
         mov       ds:[PozVrat],dx          ; pozice vrat
InitSc52:cmp       al,VECI                  ; je to vìc ?
         jb        InitScn6                 ; není to vìc
         inc       word ptr ds:[CitVeci]    ; èítaè vìcí
InitScn6:cmp       al,LO1                   ; je to lokomotiva ?
         jne       InitScn7
         mov       ds:[MapVlak],al
         mov       byte ptr ds:[si-1],LO3
         mov       word ptr ds:[MapVlak+1],dx ; souøadnice lokomotivy
InitScn7:inc       dx                       ; zvýšení pozice na øádku
         cmp       dl,20                    ; je již konec øádku ?
         jne       InitScn5                 ; není ještì konec øádku
         inc       dh                       ; zvýšení ukazatele øádku
         cmp       dh,12                    ; je již poslední øádek ?
         jne       InitScn4                 ; není ještì poslední øádek

         mov       byte ptr ds:[MapVlak+3],0  ; oznaèení konce vlaku
         mov       byte ptr ds:[Faze],0     ; ukazatel fáze
         mov       word ptr ds:[Smer],0     ; smìr pohybu (= stojí)

; ------ návrat registrù

         pop       es
         pop       di
         pop       si
         pop       dx
         pop       cx
         pop       ax
         ret

InitScen ENDP

; -----------------------------------------------------------------------------
;        inicializace adres obrázkù
; -----------------------------------------------------------------------------
; 
InitObr  PROC      NEAR

DELLO    EQU       16*40*4                  ; délka jednoho øádku obrázkù

; ------ ukládací adresa do bufferu

         cld
         mov       di,offset AdrObr         ; buffer adres obrázkù
         push      ds
         pop       es

; ------ adresa tmy

         mov       ax,7*DELLO + 12*2 + 6*2 + 2 ; tma je za nápisem
         stosw

; ------ lokomotiva - fáze 1 až 3

         mov       ax,7*DELLO
         mov       cx,3*4                   ; 2 fáze po 4 obrázcích
         call      InitObrA                 ; uložení adres

; ------ srážka - 10 fází

         mov       ax,8*DELLO
         mov       cl,10
         call      InitObrA                 ; uložení adres

; ------ zeï

         mov       ax,7*DELLO + 12*2 + 6*2
         stosw

; ------ vrata - 6 fází

         mov       ax,7*DELLO + 12*2
         mov       cl,6
         call      InitObrA                 ; uložení adres

; ------ vagony

         mov       ax,3*16*4*40
         mov       cx,POCVECI               ; poèet vìcí
InitObr4:push      ax
         stosw
         add       ax,16*4*40
         stosw
         add       ax,16*4*40
         stosw
         add       ax,16*4*40
         stosw
         pop       ax
         inc       ax
         inc       ax
         loop      InitObr4

; ------ vìci

         xor       ax,ax
         mov       cx,POCVECI               ; poèet vìcí
InitObr6:push      ax
         stosw
         add       ax,16*4*40
         stosw
         add       ax,16*4*40
         stosw
         pop       ax
         inc       ax
         inc       ax
         loop      InitObr6
         ret

InitObr  ENDP

; ------ uložení CX adres vedle sebe

InitObrA:stosw
         inc       ax
         inc       ax
         loop      InitObrA
         ret

; -----------------------------------------------------------------------------
;        zobrazení obrázku AL na pozici DL, øádek DH
; -----------------------------------------------------------------------------
; 
DispObr  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      bx
         push      cx
         push      dx
         push      si
         push      di
         push      ds
         push      es

; ------ adresa obrázku -> DS:SI

         mov       es,ds:[SegmVRAM]         ; ES <- adresa ve videopamìti
         mov       ah,0
         shl       ax,1                     ; obrázek * 2
         xchg      ax,bx                    ; BX <- offset v tabulce
         mov       si,ds:[bx+AdrObr]        ; adresa obrázku

; ------ adresa k uložení obrázku

         mov       cx,dx                    ; úschova DX
         mov       dl,dh
         mov       dh,0
         mov       ax,16*40                 ; offset øádku
         mul       dx                       ; pøepoèet øádku na offset
         mov       ch,0
         shl       cx,1                     ; pøepoèet pozice na offset
         add       ax,cx                    ; adresa ve videopamìti
         xchg      ax,di                    ; DI <- adresa ve videopamìti
         cld

; ------ rozlišení, zda je karta Hercules

         cmp       byte ptr ds:[Hercules],0 ; je to karta Hercules ?
         mov       ax,SEG ObrSegm
         mov       ds,ax                    ; DS <- segment obrázkù
         je        DispObr7                 ; není karta Hercules

; ------ pøíprava k zobrazení znaku Hercules

         call      KorVRAM                  ; korekce adresy pro Hercules

; ------ zobrazení první roviny obrázku

         mov       cx,16                    ; poèet linek
         push      si
         push      di
DispObr2:movsw                              ; pøenos jedné linky
         add       di,2000h-2
         jns       DispObr3
         and       di,7fffh                 ; korekce zpìt na zaèátek
         add       di,80                    ; adresa další linky znaku
DispObr3:add       si,4*40-2
         loop      DispObr2
         pop       di
         pop       si

; ------ zobrazení dalších rovin obrázku

         mov       ah,3                     ; poèet rovin k zobrazení
DispObr4:push      ax

         add       si,40
         mov       cx,16                    ; poèet linek
         push      si
         push      di
DispObr5:lodsw                              ; pøenos jedné linky
         or        es:[di],ax
         add       di,2000h
         jns       DispObr6
         and       di,7fffh                 ; korekce zpìt na zaèátek
         add       di,80                    ; adresa další linky znaku
DispObr6:add       si,4*40-2
         loop      DispObr5
         pop       di
         pop       si

         pop       ax
         dec       ah
         jnz       DispObr4
         jmp       short DispObrA

; ------ pøíprava k zobrazení obrázku

DispObr7:mov       dx,3c4h
         mov       al,2
         out       dx,al                    ; volba registru zápisových rovin
         mov       ah,1                     ; ukazatel zápisové roviny
         inc       dx

; ------ zobrazení jedné roviny obrázku

DispObr8:mov       al,ah
         out       dx,al                    ; volba zápisové roviny
         mov       cx,16                    ; poèet linek
         push      si
         push      di
DispObr9:movsw                              ; pøenos jedné linky
         add       di,40-2
         add       si,4*40-2
         loop      DispObr9
         pop       di
         pop       si

; ------ pøíprava pro další rovinu

         add       si,40
         shl       ah,1
         cmp       ah,10h
         jne       DispObr8                 ; další rovina

; ------ návrat registrù

DispObrA:pop       es
         pop       ds
         pop       di
         pop       si
         pop       dx
         pop       cx
         pop       bx
         pop       ax
         ret

DispObr  ENDP

; -----------------------------------------------------------------------------
;        zobrazení titulku
; -----------------------------------------------------------------------------

DispTit  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      bx
         push      cx
         push      dx
         push      si
         push      di
         push      ds
         push      es

; ------ pøíprava k zobrazení titulku

         mov       bl,ds:[CitTit]           ; èítaè titulku
         mov       si,(200-16)*40*4
         mov       di,9*16*40 + 2
         mov       es,ds:[SegmVRAM]         ; segment videopamìti
         cld

; ------ rozlišení, zda je karta Hercules

         cmp       byte ptr ds:[Hercules],0 ; je to karta Hercules ?
         mov       ax,SEG ObrSegm
         mov       ds,ax
         je        DispTit6                 ; není karta Hercules

; ------ pøíprava k zobrazení znaku Hercules

         call      KorVRAM                  ; korekce adresy pro Hercules

; ------ zobrazení první roviny

         mov       cx,16                    ; poèet linek

         push      di
         push      si

DispTit2:push      cx
         push      si
         push      di

         mov       cl,bl                    ; èítaè titulku
         rep       movsb                    ; pøenos jedné linky

         pop       di
         pop       si
         pop       cx
         add       si,40*4

         add       di,2000h                 ; zvýšení adresy videopamìti
         jns       DispTit3                 ; není pøeteèení 4 linek
         and       di,7fffh                 ; korekce zpìt na zaèátek
         add       di,80                    ; adresa další linky znaku
DispTit3:loop      DispTit2

         pop       si
         pop       di

; ------ zobrazení dalších rovin

         mov       ah,3
DispTit4:add       si,40                    ; další rovina
         mov       cx,16                    ; poèet linek

         push      di
         push      si

DispTit5:push      cx
         push      si
         push      di

         mov       cl,bl                    ; èítaè titulku
         jcxz      DispTi56
DispTi52:lodsb
         or        es:[di],al
         inc       di
         loop      DispTi52

DispTi56:pop       di
         pop       si
         pop       cx
         add       si,40*4

         add       di,2000h                 ; zvýšení adresy videopamìti
         jns       DispTi58                 ; není pøeteèení 4 linek
         and       di,7fffh                 ; korekce zpìt na zaèátek
         add       di,80                    ; adresa další linky znaku
DispTi58:loop      DispTit5

         pop       si
         pop       di

         dec       ah
         jnz       DispTit4
         jmp       short DispTit9

; ------ pøíprava k zobrazení titulku

DispTit6:mov       dx,3c4h
         mov       al,2
         out       dx,al                    ; volba registru zápisových rovin
         mov       ah,1                     ; ukazatel zápisové roviny
         inc       dx

; ------ zobrazení jedné roviny titulku

DispTit7:mov       al,ah
         out       dx,al                    ; volba zápisové roviny
         mov       cx,16                    ; poèet linek

         push      di
         push      si

DispTit8:push      cx
         push      si
         push      di

         mov       cl,bl                    ; èítaè titulku
         rep       movsb                    ; pøenos jedné linky

         pop       di
         pop       si
         pop       cx
         add       si,40*4
         add       di,40

         loop      DispTit8

         pop       si
         pop       di

; ------ pøíprava pro další rovinu

         add       si,40
         shl       ah,1
         cmp       ah,10h
         jne       DispTit7                 ; další rovina

; ------ návrat registrù

DispTit9:pop       es
         pop       ds
         pop       di
         pop       si
         pop       dx
         pop       cx
         pop       bx
         pop       ax
         ret

DispTit  ENDP

; -----------------------------------------------------------------------------
;        zobrazení èísla AX (adresa DI, barva CH)
; -----------------------------------------------------------------------------

DispNum  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      bx
         push      cx
         push      dx
         push      si

; ------ dekódování èísla do zásobníku

         xor       bx,bx                    ; èítaè znakù
         mov       si,10
DispNum1:xor       dx,dx
         div       si
         push      dx
         inc       bx
         or        ax,ax
         jnz       DispNum1

; ------ zobrazení èísla

DispNum3:pop       ax
         add       al,"0"
         mov       ah,ch
         call      DispChr
         dec       bx
         jnz       DispNum3

; ------ návrat registrù

         pop       si
         pop       dx
         pop       cx
         pop       bx
         pop       ax
         ret

DispNum  ENDP

; -----------------------------------------------------------------------------
;        zobrazení hlášení pøi srážce
; -----------------------------------------------------------------------------
; 
DispKec  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      bx
         push      cx
         push      dx
         push      si
         push      di

; ------ náhodné èíslo

         sti
DispKec1:push      ds
         xor       dx,dx
         mov       ds,dx
         mov       dx,ds:[46ch]             ; èasovaè
         pop       ds
         xor       dx,ds:[CitKec]
         rol       dx,1
         mov       ds:[CitKec],dx
         and       dx,3fh                   ; asi tak omezení
         inc       dx

; ------ nalezení textu -> DS:SI, délka CX

         cld
         mov       di,offset TabKec         ; tabulka textù
DispKec2:mov       si,di                    ; SI <- adresa dalšího textu
         xor       cx,cx                    ; CX <- 0 èítaè délky textu
         cmp       byte ptr ds:[si],0       ; je další text ?
         je        DispKec1                 ; není další text
DispKec3:mov       al,ds:[di]
         inc       di
         inc       cx
         cmp       al,0
         jne       DispKec3
         dec       dx                       ; èítaè textù
         jnz       DispKec2                 ; další text

; ------ zobrazení textu (CX=délka textu + 1)

         mov       ax,40-1
         sub       al,cl                    ; zbytek na okraje
         shr       al,1                     ; polovièní pozice
         add       ax,4*40
         xchg      ax,di
         mov       ax,10*256 + " "
         call      DispChr                  ; úvodní mezera
         call      DispTxt                  ; zobrazení textu hlášení
         mov       al," "
         call      DispChr                  ; závìreèná mezera

; ------ návrat registrù

         pop       di
         pop       si
         pop       dx
         pop       cx
         pop       bx
         pop       ax
         ret

DispKec  ENDP

; -----------------------------------------------------------------------------
;        zobrazení textu SI (barva AH, uložení DI)
; -----------------------------------------------------------------------------

DispTxt  PROC      NEAR

DispTxt1:cld
         lodsb
         cmp       al,0
         je        DispTxt2
         call      DispChr
         jmp       short DispTxt1

DispTxt2:ret

DispTxt  ENDP

; -----------------------------------------------------------------------------
;        zobrazení znaku AX (AH: bit7=inverze) na adrese DI
; -----------------------------------------------------------------------------
; 
DispChr  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      cx
         push      dx
         push      si
         push      di
         push      es

         mov       ch,ah                    ; barva

; ------ adresa znaku v tabulce fontù -> DS:SI

         mov       ah,8                     ; poèet bajtù na znak
         mul       ah                       ; offset znaku ve fontech
         add       ax,offset Font08         ; adresa znaku ve fontech
         xchg      ax,si                    ; SI <- adresa znaku
         cld

; ------ rozlišení, zda je karta Hercules

         mov       es,ds:[SegmVRAM]         ; segment videopamìti
         cmp       byte ptr ds:[Hercules],0 ; je to karta Hercules ?
         je        DispChr5                 ; není karta Hercules

; ------ pøíprava k zobrazení znaku Hercules

         call      KorVRAM                  ; korekce adresy pro Hercules
         or        ch,ch                    ; je inverze ?
         mov       cx,8                     ; poèet linek znaku
         js        DispChr3                 ; je inverzní barva

; ------ zobrazení bílé barvy

DispChr1:movsb                              ; bajt znaku
         add       di,2000h-1               ; zvýšení adresy videopamìti
         jns       DispChr2                 ; není pøeteèení 4 linek
         and       di,7fffh                 ; korekce zpìt na zaèátek
         add       di,80                    ; adresa další linky znaku
DispChr2:loop      DispChr1                 ; zobrazení další linky znaku
         jmp       short DispChr9

; ------ zobrazení èerné barvy

DispChr3:lodsb                              ; bajt znaku
         not       al
         stosb
         add       di,2000h-1               ; zvýšení adresy videopamìti
         jns       DispChr4                 ; není pøeteèení 4 linek
         and       di,7fffh                 ; korekce zpìt na zaèátek
         add       di,80                    ; adresa další linky znaku
DispChr4:loop      DispChr3                 ; zobrazení další linky znaku
         jmp       short DispChr9

; ------ nastavení zápisu do všech rovin

DispChr5:mov       dx,3c4h
         mov       al,2
         out       dx,al                    ; volba registru 2
         inc       dx
         mov       al,0fh                   ; zápis do všech rovin
         out       dx,al                    ; nastavení všech rovin

; ------ nastavení barvy znaku

         mov       dx,3ceh
         mov       al,0                     ; registr 0
         out       dx,al                    ; volba registru 0
         inc       dx
         mov       al,0                     ; èerná barva
         out       dx,al                    ; nastavení barvy znaku
         dec       dx

; ------ nastavení volby rovin

         mov       al,1                     ; registr 1
         out       dx,al                    ; volba registru 1
         mov       al,ch                    ; požadovaná barva znaku
         not       al                       ; bity 0 budou podle registru 0 èerné
         inc       dx
         out       dx,al                    ; volba rovin
         dec       dx

; ------ registr bitové masky

         mov       al,8                     ; registr 8
         out       dx,al                    ; volba registru 8
         inc       dx
         mov       al,0ffh
         out       dx,al                    ; všechny bity

; ------ zobrazení znaku

         mov       ah,ch
         mov       cx,8                     ; poèet linek znaku
DispChr6:lodsb                              ; bajt znaku
         or        ah,ah
         jns       DispCh62
         not       al
DispCh62:xchg      al,es:[di]               ; zápis znaku
DispCh64:add       di,40                    ; adresa další linky znaku
         loop      DispChr6                 ; zobrazení další linky znaku

; ------ návrat videoregistrù

         dec       dx
         mov       al,1                     ; registr 1
         out       dx,al                    ; volba registru 1
         mov       al,0                     ; všechny roviny podle dat
         inc       dx
         out       dx,al                    ; volba rovin

; ------ návrat registrù

DispChr9:pop       es
         pop       di
         pop       si
         pop       dx
         pop       cx
         pop       ax
         inc       di                       ; zvýšení ukládací adresy
         ret

DispChr  ENDP

; -----------------------------------------------------------------------------
;        nastavení zvukového generátoru na AX
; -----------------------------------------------------------------------------

SetSound PROC      NEAR

         push      ax
         cmp       byte ptr ds:[Zvuk],0
         je        SetSnd9
         cli
         mov       al,0b6h
         out       [43h],al
         pop       ax
         push      ax
         out       [42h],al                 ; LOW
         xchg      ah,al
         out       [42h],al                 ; HIGH
         in        al,[61h]
         or        al,3
         out       [61h],al
         sti
SetSnd9: pop       ax
         ret

SetSound ENDP

; -----------------------------------------------------------------------------
;        vypnutí zvukového generátoru
; -----------------------------------------------------------------------------

SoundOff PROC      NEAR

         push      ax
         in        al,[61h]
         and       al,not 3
         out       [61h],al
         pop       ax
         ret

SoundOff ENDP

; -----------------------------------------------------------------------------
;        cejchování hodin
; -----------------------------------------------------------------------------
; VSTUP: DS=datový segment
; -----------------------------------------------------------------------------

CekInit  PROC      NEAR

; ------ úschova registrù

         push      ax
         push      bx
         push      dx
         push      di

         push      ds

; ------ pøíprava registrù

         sti
         xor       ax,ax                    ; AX <- 0
         mov       ds,ax                    ; DS <- 0
         xor       dx,dx                    ; DX <- 0
         mov       di,46ch                  ; adresa èasovaèe BIOS

; ------ èekání na zaèátek impulsu hodin

         mov       bx,ds:[di]               ; aktuální stav hodin
CekInit1:cmp       bx,ds:[di]               ; zmìnily se hodiny ?
         je        CekInit1                 ; èekání na zaèátek hodin

; ------ mìøení èasu

         mov       bx,ds:[di]               ; nový aktuální stav hodin
         EVEN                               ; zarovnání na sudou adresu
CekInit2:add       ax,1                     ; èítaè nižšího slova èasu
         adc       dx,0                     ; pøenos do vyššího slova
         cmp       bx,ds:[di]               ; byla zmìna ?
         je        CekInit2                 ; èekání na zmìnu hodin

; ------ výpoèet konstanty

         mov       bx,55                    ; dìlitel
         cmp       dx,bx                    ; pøeteèení èísla ?
         jb        CekInit3                 ; není pøeteèení èísla
         mov       dx,54                    ; omezení èísla
CekInit3:div       bx                       ; výpoèet konstanty

; ------ uložení konstanty pro 1 ms

         or        ax,ax                    ; je = 0 ?
         jnz       CekInit4                 ; není = 0
         inc       ax                       ; korekce na 1
CekInit4:pop       ds
         mov       ds:[Cit1ms],ax           ; konstanta hodin pro 1 ms

; ------ návrat registrù

         pop       di
         pop       dx
         pop       bx
         pop       ax
         ret

CekInit  ENDP

; -----------------------------------------------------------------------------
;        èekání na uplynutí zadaného èasu
; -----------------------------------------------------------------------------
; VSTUP: CX=požadovaná doba v milisekundách
;        DS=datový segment
; -----------------------------------------------------------------------------

Cekej    PROC      NEAR

; ------ úschova registrù

         push      ax
         push      bx
         push      cx
         push      dx
         push      di

; ------ èekání po zadanou dobu

         jcxz      Cekej9                   ; není žádné èekání
         mov       di,offset Cit1ms         ; konstanta hodin
Cekej1:  xor       ax,ax                    ; AX <- 0 nižší slovo èítaèe hodin
         xor       dx,dx                    ; DX <- 0 vyšší slovo èítaèe hodin

; ------ èítání doby 1 ms

         EVEN                               ; zarovnání na sudou adresu
Cekej2:  add       ax,1                     ; èítaè nižšího slova èasu
         adc       dx,0                     ; pøenos do vyššího slova
         cmp       ax,ds:[di]               ; dosaženo doby 1 ms ?
         jne       Cekej2                   ; èítání doby 1 ms

         loop      Cekej1                   ; èekání na další 1 ms

; ------ návrat registrù

Cekej9:  pop       di
         pop       dx
         pop       cx
         pop       bx
         pop       ax
         ret

Cekej    ENDP

; -----------------------------------------------------------------------------
;        vyprázdnìní bufferu klávesnice
; -----------------------------------------------------------------------------

FlushKey PROC      NEAR

         push      ax
FlushKe2:mov       ah,1
         int       16h
         jz        FlushKe3
         mov       ah,0
         int       16h
         jmp       short FlushKe2
FlushKe3:pop       ax
         ret

FlushKey ENDP

; -----------------------------------------------------------------------------
;        korekce adresy ve videopamìti DI pro HERCULES
; -----------------------------------------------------------------------------

KorVRAM  PROC      NEAR

         push      bx
         push      dx
         push      ax

         xor       dx,dx                    ; DX <- 0
         xchg      ax,di                    ; AX <- adresa ve videopamìti
         mov       bx,40                    ; poèet bajtù na videolinku
         div       bx                       ; AX <- èíslo videolinky
         mov       di,dx                    ; DI <- offset na videolince

         xor       dx,dx                    ; DX <- 0
         mov       bx,4
         div       bx                       ; AX <- èíslo linky / 4, DX <- zbytek

         mov       bx,dx                    ; BX <- èíslo linky 0 až 3
         mov       dx,80                    ; poèet bajtù na linku
         mul       dx                       ; pøepoèet na adresu
         add       di,ax                    ; DI <- adresa ve videopamìti

         mov       ax,bx                    ; AX <- èíslo sekce po 2000h
         mov       dx,2000h                 ; poèet bajtù na sekci
         mul       dx
         add       ax,(((350-200)/2)/4)*80+20
         add       di,ax                    ; DI <- adresa sekce

         pop       ax
         pop       dx
         pop       bx
         ret

KorVRAM  ENDP

; -----------------------------------------------------------------------------
;        inicializace videomódu (CY=chyba, nepodporovaná videokarta)
; -----------------------------------------------------------------------------

InitVMod PROC      NEAR

; ------ úschova aktivního videomódu

         mov       ah,0fh
         call      Int10                    ; poskytnutí aktivního videomódu
         mov       ds:[OldVMod],al          ; úschova videomódu

; ------ test, zda je grafická karta EGA/VGA

         mov       ah,12h                   ; funkce poskytnutí informací EGA
         mov       bx,5810h                 ; podslužba informací o EGA
         call      Int10                    ; poskytnutí informací o EGA
         cmp       bh,2
         ja        InitVMd2                 ; není karta EGA/VGA
         cmp       bl,5
         ja        InitVMd2                 ; není karta EGA/VGA

; ------ nastavení grafického módu pro EGA a VGA

         mov       ax,13                    ; požadovaný videomód 13
         call      Int10                    ; nastavení videomódu 13
         mov       ah,0fh
         call      Int10                    ; poskytnutí aktivního videomódu
         cmp       al,13                    ; je požadovaný videomód ?
         je        InitVMd7                 ; videomód nastaven OK

; ------ nastavení videomódu pro Hercules

InitVMd2:cmp       byte ptr ds:[OldVMod],7  ; je videomód 7 ?
         je        InitVMd4                 ; je videomód 7

         push      ds
         xor       ax,ax
         mov       ds,ax
         cmp       word ptr ds:[463h],3b4h  ; je emulátor CGA pro Hercules ?
         pop       ds
         jne       InitVMd8                 ; chyba - je asi karta CGA

InitVMd4:mov       ax,7
         call      Int10                    ; nastavení MONO videomódu
         mov       ah,0fh
         call      Int10                    ; poskytnutí videomódu
         cmp       al,7                     ; nastaven videomód 7 ?
         jne       InitVMd8                 ; chyba - videomód nenastaven

; ------ nastavení grafického videomódu Hercules

         inc       byte ptr ds:[Hercules]   ; pøíznak videokarty Hercules
         call      InitHerc                 ; inicializace videomódu Hercules
InitVMd7:clc
         ret

InitVMd8:stc
InitVMd9:ret

InitVMod ENDP

; -----------------------------------------------------------------------------
;        inicializace videokarty HERCULES (neuchovává registry, jen DS !)
; -----------------------------------------------------------------------------

InitHerc PROC      NEAR

         cli                                ; zákaz pøerušení

; ------ povolení pøepnutí adresy pamìti, adresa je 0b000h

         mov       al,3
         mov       dx,3bfh
         out       dx,al                    ; nastavení registru kompatibility

; ------ nastavení grafického módu, videosignál blokován

         mov       al,2
         mov       dl,0b8h
         out       dx,al                    ; nastavení øídicího registru módu

; ------ nastavení øídicích registrù CRT

         mov       dl,0b4h
         mov       si,offset ITabHerc       ; inicializaèní tabulka pro Hercules
         xor       ah,ah                    ; ukazatel èísla registru
         cld
InitHrc2:mov       al,ah                    ; èíslo registru
         out       dx,al                    ; nastavení èísla registru
         lodsb
         inc       dx
         out       dx,al                    ; data pro nastavení registru
         dec       dx
         inc       ah
         cmp       ah,12
         jb        InitHrc2                 ; další registr

; ------ povolení videosignálu, nastavení grafického módu

         mov       al,0ah
         mov       dx,3b8h
         out       dx,al                    ; nastavení øídicího registru módu

; ------ vymazání videopamìti (je CLD !)

         sti
         mov       cx,4000h                 ; délka videopamìti (ve slovech)
         mov       ax,0b000h                ; segment videopamìti
         mov       ds:[SegmVRAM],ax         ; segment videopamìti
         mov       es,ax
         xor       ax,ax                    ; mazací slovo
         xor       di,di
         rep       stosw                    ; vymazání videopamìti
         ret

InitHerc ENDP

; -----------------------------------------------------------------------------
;        obsluha INT 10h s úschovou registrù
; -----------------------------------------------------------------------------

Int10    PROC      NEAR

         pushf
         push      si
         push      di
         push      bp
         push      ds
         push      es

         int       10h

         pop       es
         pop       ds
         pop       bp
         pop       di
         pop       si
         popf
         ret

Int10    ENDP

Code     ENDS

; *****************************************************************************
;
;                               Data
;
; *****************************************************************************
; 
Data     SEGMENT
Font08   label     byte
INCLUDE  FONT08.ASM

CardTxt  db        'Lituji, program vyzaduje grafikou kartu EGA, VGA nebo Hercules !',13,10,'$'
PCXTxt   db        'CHYBA - nenalezen (nebo poskozen) soubor .PCX !',13,10,'$'
SCNTxt   db        'CHYBA - nenalezen (nebo poskozen) soubor .SCN !',13,10,'$'

UvTxt    dw        0                        ; adresa úvodního textu

; ------ tabulka pro nastavení øídicích registrù CRT karty Hercules

ITabHerc LABEL     BYTE
         db        53                       ; 0:celkový poèet znakù na øádek-1
         db        40                       ; 1:poèet vidit. znakù na øádek
         db        44                       ; 2:poèátek horiz. zatemnìní
         db        7                        ; 3:poèet znakù na synchronizaci

         db        91                       ; 4:celk. poèet vert. øádkù-1 (363)
         db        1                        ; 5:poèet linek + k poètu øádkù
         db        88                       ; 6:poèet viditelných øádkù (300)
         db        88                       ; 7:øádka zpìtného bìhu (345)
         db        2                        ; 8:1=prokládání, 2=normal
         db        3                        ; 9:poèet linek na znak - 1 (3)

         db        0                        ; 0a:první linka kurzoru
         db        3                        ; 0b:koncová linka kurzoru

SegmVRAM dw        0a000h                   ; segment videopamìti
OldVMod  db        3                        ; uschovaný pùvodní videomód
Hercules db        0                        ; 0 <> pøíznak videokarty Hercules

BuffHes  db        '     '                  ; buffer hesla

                                            ; posun pøi demonstraci
DemoPos  db        19 dup(1,0)
         db        8 dup(0,-1)
         db        3 dup( 19 dup(-1,0), 0,1, 19 dup(1,0), 0,1)
         db        19 dup(-1,0)
         db        0,1, 0,1, 0,1
         db        9 dup(1,0), 0,1
         db        0,0                      ; ukonèení

SkorTxt  db        'SKORE',0
ScenTxt  db        ' SCENA ',0
HeslTxt  db        'F4 HESLO',0
Hes2Txt  db        ' heslo ',0

Bla1Txt  db        '                              ',0
Bla2Txt  db        '  B L A H O P Ø E J E M E  !  ',0
         db        '   Stal jste se absolutním    ',0
         db        '      vítìzem této hry !      ',0

; ------ hlášení pøi srážce

TabKec   label     byte                     ; max. 34 znakù !
         db        'Kdo jinému jámu kopá...',0
         db        'A zase vedle...',0
         db        'Tak už to koneènì vzdejte!',0
         db        'Už moc nechybìlo!',0
         db        'A už zase?',0
         db        'To snad dìláte schválnì?',0
         db        'Co takhle se trochu soustøedit?',0
         db        'Dejte si radìji pauzu.',0
         db        'Nezoufejte, to se stane.',0
         db        'Netluète poèítaè, nemùže za to!',0
         db        'Nevolal nìkdo o pomoc?',0
         db        'Pøiznejte si, že na to již nemáte!',0
         db        'I vyvalily se vlny zdola...',0
         db        'Život je život...',0
         db        'To víte, je to jako v životì.',0
         db        'Nebreète, mohlo to být i horší!',0
         db        'HA, HA, HA. DOSTAL JSEM TÌ!',0
         db        'A máš co sis zasloužil!',0
         db        'Na to jsem se již dlouho tìšil!',0
         db        'Nemá tady nìkdo náplast?',0
         db        'A l a r m  !   H O Ø Í  !',0
         db        'Takhle to asi nemìlo být, že?',0
         db        'Tak kudy to asi bude?',0
         db        'Tudy tedy cesta nevede.',0
         db        'Chtìlo to jen o kousek vedle.',0
         db        'Není to k zbláznìní?',0
         db        'Mnì nenadávejte, já za to nemohu.',0
         db        'Snad pøíštì.',0
         db        'Co takhle to zkusit trochu jinak?',0
         db        'Není škoda vše takhle nièit?',0
         db        'Zkuste si nechat zmìøit vaše IQ!',0
         db        'Pozor na krevní tlak!',0
         db        'A nedáte si pokoj a nedáte!',0
         db        'Necítíte kouø?',0
         db        'Zkuste použít tlaèítko RESET!',0
         db        'To byla ale rána!',0
         db        'Snad to nevzdáváte?',0
         db        'Pres eny kej tu kontinjù...',0
         db        'Chyba lávky, zase nic.',0
         db        'A co jinak doma, všichni zdrávi?',0
         db        'Pozvìte si odborného poradce.',0
         db        'Tak dost legrácek a teï již vážnì!',0
         db        'Tak kolik to bylo dnes rumíkù?',0
         db        'Chybami se èlovìk uèí.',0
         db        0

CitKec   dw        2356h                    ; èítaè náhody pro hlášení

; ------ èasovaè

         EVEN                               ; zaèíná na sudé adrese jako 0:46ch
Cit1ms   dw        0                        ; konstanta pro dobu 1 ms

Zvuk     db        1                        ; pøíznak zapnutí zvuku
AdrSound dw        0                        ; adresa zvuku
CitSound dw        0                        ; èítaè délky zvuku (0=není)

CitVyb   dw        0                        ; èítaè výbuchu

TabSLok  dw        166,254,365              ; zvuk lokomotivy
TabSLok0 label     byte

TabSVec  dw        400,600,800,1000,1200,1400,1600,1800,2000,1800,1600,1400,1200,1000,800,600,400,200 ; zvuk vìci
TabSVec0 label     byte

FileName db        128 dup(0)               ; buffer jména souboru
FilePCX  db        'PCX',0                  ; jméno souboru obrázkù PCX
FileSCN  db        'SCN',0                  ; jméno souboru definice scén SCN

;FilePlay db        '_PLAYSCR.COM',0         ; jméno programu GDEMO ke spuštìní
;
;BlokPlay dw        0                        ; adresa segmentu prostøedí
;         dd        BlokPlCm                 ; adresa pøíkazového øádku
;         dw        5ch                      ; adresa FCB1
;         dw        SEG Code - 1             ; adresa PSP
;         dw        6ch                      ; adresa FCB2
;         dw        SEG Code - 1             ; adresa PSP

BlokPlCm db        0                        ; pøíkazový øádek (prázdný)
         db        13

SegmPSP  dw        0                        ; segment PSP

Smer     dw        0                        ; smìr pohybu

;Demon    db        0                        ; 1=pøíznak demonstrace
Autom    dw        0                        ; ukazatel adresy automatu (0=není)
AutomCek dw        0                        ; èítaè èekání po DEMO

CitTit   db        0                        ; èítaè šíøky titulku
CitVeci  dw        0                        ; èítaè vìcí
PozVrat  dw        0                        ; pozice vrat
Skore    dw        0                        ; èítaè skóre

LastTime dw        0                        ; uschovaný poslední èas

Faze     db        0                        ; èítaè fáze

NumScen  dw        0                        ; poèet definovaných scén (s DEMO)
AktScen  db        1                        ; aktivní scéna

RndUkaz  dw        0                        ; ukazatel pro náhodné èíslo

TabHesel db        5*256 dup(?)             ; tabulka hesel

MapVlak  db        3 * 12*20 dup(?)         ; mapa celého vlaku
                                            ;  0: (1) báze objektu (0=konec)
                                            ;  1: (1) souøadnice X
                                            ;  2: (1) souøadnice Y

Pole     db        12*20 dup(?)             ; hrací pole

Buffer   db        BuffSize dup(?)          ; vstupní buffer souboru

AdrObr   dw        256 dup(?)               ; adresy obrázkù

AdrScen  dw        256 dup(?)               ; adresy scén

Data     ENDS

; *****************************************************************************
;
;                               Buffer scén
;
; *****************************************************************************

ScenSegm SEGMENT   PARA
         db        0ffffh dup(?)            ; buffer definice scén
ScenSegm ENDS

; *****************************************************************************
;
;                          Buffer obrázkù
;
; *****************************************************************************

ObrSegm  SEGMENT   PARA
         db        (320/8)*200*4 dup(?)     ; buffer obrázkù
ObrSegm  ENDS

; *****************************************************************************
;
;                              Zásobník
;
; *****************************************************************************

Zasob    SEGMENT   'STACK' stack
         dw        200h dup(?)
Zasob    ENDS
         END       Start
