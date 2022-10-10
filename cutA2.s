******************************************
*                                        *
*   CUT :  LE DESASSEMBLEUR D'IMAGE      *
*                                        *
******************************************
*
CH EQU $24
CV EQU $25
PROMPT EQU $33
TEXT2 EQU $C051
PTR6 EQU $08
HGR EQU $2000
INBUF EQU $200
KS EQU $C010
KB EQU $C000
WAIT EQU $FCA8
COUT EQU $FDED 
GETLN EQU $FD6A
STROUT EQU $DB3A
HOME EQU $FC58
VTAB EQU $FC22
CLEROL EQU $FC9C
MESSNB EQU $F9
SETTEXT EQU $FB39
SETINV EQU $FE80
SETNORM EQU $FE84 
MLI EQU $BF00
BUFG EQU $5C00
*
 ORG $4000
 LDY #$27
 STY droite; init les fronti}res
 LDY #$00
 STY gauche
 STY haut
 LDX #$BF
 STX bas
 LDY #$00
 STY LIG; initialise le nb lignes
CUT LDA #$11
 JSR COUT; 40 colonnes
 JSR HOME
 JSR SETTEXT
 LDA #$60
 STA UNIT; slot 6, drive 1
MEN JSR MLI
 HEX C5;on_line
 DA ONLINE
 BCC SUITE
 JSR ERROR
 BRA MEN
SUITE LDA PATH
 AND #$0F;longueur dans nibble bas
 STA PATH
 TAX
L1 LDA PATH,X
 STA PATH+1,X; decalage d'un octet
 DEX
 BNE L1
 INC PATH
 INC PATH;long= long+2
 LDX PATH
 LDA #$AF
 STA PATH,X; / apres
 STA PATH+1; et / avant
 JSR MLI; set_prefix
 HEX C6
 DA PREFIX
 BCC GOOD1
 JSR ERROR
 BRA MEN
GOOD1 LDX PATH
 INX 
SAVEPREF LDA PATH,X
 STA SPATH,X
 DEX
 BPL SAVEPREF 
CUT2 JSR AFFPREF
 LDA #$01
 STA CV
 JSR VTAB
 JSR LIGNE; trace une ligne
 LDA #$03
 STA CV
 JSR VTAB
 LDA #$00
 STA CH
 LDA #<TITRE
 LDY #>TITRE
 JSR STROUT;affiche le titre
 LDA #$04
 STA CV
 JSR VTAB
 JSR LIGNE; trace une ligne
 JSR MENU; affiche le menu
 LDA #$0F
 STA CV
 JSR VTAB
 JSR LIGNE; trace une ligne
*---------------------------------------------
BIGMAIN BIT KS
KBD LDA KB 
 BPL KBD
 BIT KS
 CMP #$8B
 BNE SUIT1
 JSR FHMAIN 
 BRA BIGMAIN
SUIT1 CMP #$8A
 BNE SUIT2
 JSR FBMAIN 
 BRA BIGMAIN
SUIT2 CMP #$8D 
 BNE FFIN
 JSR EXEC
FFIN BRA BIGMAIN
*--------------------------------------------
*
*  affiche une option (n[ + 5 ds MESSNB)
*
AFFI LDA MESSNB
 STA CV
 JSR VTAB
 LDA #$00
 STA CH
 LDA MESSNB
 SEC
 SBC #$05
 ASL
 TAX
 LDA TABMES,X  
 INX
 LDY TABMES,X
 JSR STROUT
FINAFFI RTS
*
*  routine d'affichage du prefix dans PATH
*
AFFPREF LDX #$00
 STX CH
 STX CV
 JSR VTAB
 LDX #$00
 STA CH
 LDA SPATH
 BEQ FINPREF 
AFFP2 LDA SPATH+1,X
 ORA #$80
 JSR COUT
 INX
 CPX SPATH
 BNE AFFP2
 JSR CLEROL
FINPREF RTS ; si il n'y en a pas
*
*  trace une ligne
*
LIGNE LDX #$00
 STX CH
 LDY #$28
 LDA #$DF
LIGN2 JSR COUT 
 DEY
 BNE LIGN2
 RTS
*
*   affiche les optipons
*
menu LDA #05
 CMP #$0F
 BCS finmenu
 STA MESSNB
MENU2 JSR FBMAIN
 INC menu+1
 BRA menu
finmenu LDA #$05
 STA menu+1
 RTS
*
*    si fleche en bas
*
FBMAIN JSR AFFI;affiche option en normal 
 JSR SETINV
 LDA MESSNB
 CMP #$0E
 BEQ suit
 INC MESSNB; option suivante 
 JSR AFFI; en inverse
 BRA finfb
suit LDA #$05
 STA MESSNB
 JSR AFFI  
finfb JSR SETNORM
 RTS
*
*    si fleche en haut
*
FHMAIN JSR AFFI;affiche option en normal 
 JSR SETINV
 LDA MESSNB
 CMP #$05
 BEQ fhsuit
 DEC MESSNB; option suivante 
 JSR AFFI; en inverse
 BRA finfh
fhsuit LDA #$0E
 STA MESSNB
 JSR AFFI  
finfh JSR SETNORM
 RTS
*
*  execution d'une option
*
EXEC LDA MESSNB
 SEC
 SBC #$05
 BNE autre
 JMP CHARGI; charge image
autre CMP #$02; HGR
 BNE autre1
 JMP INIT
autre1 CMP #$01
 BNE autre2
 JMP SAUVEI
autre2 CMP #$07
 BNE autre3
 JMP newpref 
autre3 CMP #$09
 BNE autre4
 PLA
 PLA
 JSR HOME
 RTS
autre4 CMP #$05 
 BNE autre5
 JMP SAUVCB
autre5 CMP #$03
 BNE autre6
 JMP CHARCB
autre6 CMP #$04
 BNE autre7
 JMP SAVECT
autre7 CMP #$06 
 BNE autre8
 LDA LIG; cut selectionne ?
 BEQ autre8
 JSR PRTCUT
 PLA
 PLA ; depile adresse retour
 JMP CUT2
autre8 CMP #$08
 BNE FINEXEC
 PLA
 PLA ; depile adresse retour
 JMP HELP
FINEXEC RTS
*
*  charge une image
*
CHARGI JSR INPUT
 BNE CHARGI2
 JMP CLEOP
CHARGI2 JSR MLI; dans INBUF
 HEX C8 ; open
 DA OPEN
 BCC OK
 JMP ERROR
OK LDA REFNB
 STA READ+1
 LDA #<HGR
 STA READ+2
 STA READ+4
 LDA #>HGR
 STA READ+3
 STA READ+5
 JSR MLI
 HEX CA; read
 DA READ
 BCC S4
 JMP ERROR
s4 JSR CLEOP
 LDA REFNB
 STA CLOSE+1
 JSR MLI
 HEX CC ; close
 DA CLOSE
OK2 RTS
*
*  sauve une image
*
SAUVEI JSR INPUT
 BNE SAUVEI2
 JMP CLEOP
SAUVEI2 LDA #$06 
 STA CREATE+4; fichier BIN
 LDA #<HGR
 STA CREATE+5
 LDA #>HGR
 STA CREATE+6; adresse de chargement
 JSR SAVCRE
 BCS outsavi 
 LDA REFNB
 STA WRITE+1
 LDA #<HGR
 STA WRITE+2
 STA WRITE+4
 LDA #>HGR
 STA WRITE+3; adresse
 STA WRITE+5; longeur
 JSR MLI
 HEX CB; write
 DA WRITE
 BCC ferme
 JMP ERROR
ferme LDA REFNB
 STA CLOSE+1
 JSR MLI
 HEX CC ; close
 DA CLOSE
outsavi JSR CLEOP
 RTS
*
*  nouveau PREFIX
*
NEWPREF JSR INPUT
 BNE loopnew
 JMP CLEOP
loopnew LDX INBUF
loopnew2 LDA INBUF,X;recupere le prefix
 STA PATH,X;dans PATH
 DEX
 BPL loopnew2
 JSR MLI; set_prefix
 HEX C6
 DA PREFIX ; param. de destroy
 BCC finnewp
 JMP ERROR
finnewp JSR CLEOP
 JSR MLI
 HEX C7; get_prefix
 DA PREFIX
SAVPRE LDX PATH
 INX 
SAVEPRE2 LDA PATH,X
 STA SPATH,X; sauve le nouveau prefix
 DEX
 BPL SAVEPRE2
 JSR AFFPREF
 RTS
*
* sauve un cut binaire
*
SAUVCB LDA LIG
 BNE SCB
 RTS
SCB JSR INPUT
 BNE SCB2
 JMP CLEOP
SCB2 JSR MULT ;LIG*COL dans RESULT
 LDA RESULT
 CLC
 ADC #$02;ajoute 2(octets lig et col) 
 STA WRITE+4
 LDA #$00
 ADC RESULT+1
 STA WRITE+5; prepare nb d'octet @ ecrire
 LDA #<LIG
 STA WRITE+2;sauvera a partir de $6000
 STA CREATE+5;$6000=adresse de chargement 
 LDA #>LIG; le fichier binaire se charge
 STA WRITE+3 ; l'adresse = $6000
 STA CREATE+6 ; a l'adresse = $6000
 LDA #$06 
 STA CREATE+4; fichier BIN
 JSR SAVCRE
 BCS fincb
WRIT LDA REFNB 
 STA WRITE+1
 JSR MLI
 HEX CB; write
 DA WRITE
 BCC S33
 JMP ERROR
S33 JSR CLEOP
 LDA REFNB
 STA CLOSE+1
 JSR MLI
 HEX CC ; close
 DA CLOSE
fincb RTS
*
*  charge un cut binaire
*
CHARCB JSR INPUT
 BNE CHARCB2
 JMP CLEOP
CHARCB2 JSR MLI; dans INBUF
 HEX C8 ; open
 DA OPEN
 BCC OKCB
 JMP ERROR
OKCB LDA REFNB
 STA READ+1
 LDA #<LIG
 STA READ+2
 LDA #>LIG
 STA READ+3
 LDA #$02
 STA READ+4
 LDA #00
 STA READ+5;on lit 2 octets(LIG ET COL)
 JSR MLI
 HEX CA; read
 DA READ
 BCC S44
 JMP ERROR
S44 JSR MULT
 LDA RESULT 
 STA READ+4
 LDA RESULT+1
 STA READ+5
 INC READ+2 
 INC READ+2 ; buffer a partir de $6002
 JSR MLI;lit les octets suivant
 HEX CA; read
 DA READ
 BCC S442
 JMP ERROR
s442 JSR CLEOP
 LDA REFNB
 STA CLOSE+1
 JSR MLI
 HEX CC ; read
 DA CLOSE
 RTS
*
* sauve cut en fichier text
*
SAVECT LDA LIG
 BNE SAVECT2
 RTS
SAVECT2 JSR MULT
 JSR INPUT
 BNE SAVECT3
 JMP CLEOP
SAVECT3 LDA #$04;text
 STA CREATE+4 
 JSR SAVCRE 
 BCC okct
 JMP finctext
okct LDA REFNB
 STA WRITE+1
 LDY #$00 ;init Y
 LDA #$02
 STA PTR6
 LDA #$60
 STA PTR6+1; ptr6--> $6002
 LDA LIG
 JSR DESSAS
 LDA CODE
 STA LIGN
 LDA CODE+1
 STA LIGN+1
 LDA COL
 JSR DESSAS
 LDA CODE
 STA COLO
 LDA CODE+1
 STA COLO+1
 LDA #<ENTETE 
 STA WRITE+2
 LDA #>ENTETE 
 STA WRITE+3
 LDA #$1D ; 29 octets
 STA WRITE+4
 LDA #$00
 STA WRITE+5
 JSR MLI; ecris l'entete
 HEX CB; write
 DA WRITE
 BCC LOOPCT
 JMP ERROR
LOOPCT LDA #<HEX  
 STA WRITE+2
 LDA #>HEX  
 STA WRITE+3; pr{pare l'ecriture 
 LDA #$05 ; de 5 octets
 STA WRITE+4; : 'HEX '
 LDA #$00
 STA WRITE+5
 JSR MLI; ecris ' HEX '
 HEX CB; write
 DA WRITE
 BCC suitct
 JMP ERROR 
suitct LDA RESULT
 CMP #$08
 BEQ A8
 BCS SUP8
A8 LDA RESULT+1
 BNE SUP8
 LDA RESULT
 JSR WROUT;si <=8 octets @ {crire
 LDA #<RETURN
 STA WRITE+2
 LDA #>RETURN
 STA WRITE+3; pr{pare l'ecriture 
 LDA #$01 ; d' 1 octet
 STA WRITE+4; : caractere return
 LDA #$00
 STA WRITE+5
 JSR MLI; ecris un return
 HEX CB; write
 DA WRITE
CLOSECT JSR MLI
 HEX CC;close
 DA CLOSE
finctext JMP CLEOP;sort en effacant
SUP8 LDA #$08
 JSR WROUT   ;{crit 16 octets(8valeurs)
 LDA RESULT
 SEC
 SBC #$08
 STA RESULT
 LDA RESULT+1
 SBC #00
 STA RESULT+1;soustrait 8 @ RESULT
 LDA #<RETURN
 STA WRITE+2
 LDA #>RETURN
 STA WRITE+3; pr{pare l'ecriture 
 LDA #$01 ; d' 1 octet
 STA WRITE+4; : caractere return
 LDA #$00
 STA WRITE+5
 JSR MLI; ecris un return
 HEX CB; write
 DA WRITE
 BCS errct
 JMP LOOPCT
errct JMP ERROR
* 
*  imprime un cut desassembl{
*
PRTCUT JSR MULT
 LDA #$11
 STA CV
 JSR VTAB
 LDX #$00
 STX CH
MM1 LDA MESSPRT,X
 BEQ MM
 JSR COUT
 INX
 BRA MM1
MM BIT KS 
WTK LDA KB
 BPL WTK
 BIT KS
*
 LDA #01
 JSR $FE95
 JSR CLEOP
 LDA LIG
 JSR DESSAS
 LDA CODE
 STA LIGN
 LDA CODE+1
 STA LIGN+1
 LDA COL
 JSR DESSAS
 LDA CODE
 STA COLO
 LDA CODE+1
 STA COLO+1
*
 LDA #<ENTETE 
 LDY #>ENTETE 
 JSR STROUT
 LDY #00;init Y
 STY SAVEY
 LDA #$02
 STA PTR6
 LDA #$60
 STA PTR6+1; PTR6--> $6002
LOOPPR LDA #<HEX  
 LDY #>HEX  
 JSR STROUT
 LDA RESULT
 CMP #$08
 BEQ AA8
 BCS SSUP8
AA8 LDA RESULT+1
 BNE SSUP8
 LDA RESULT
 JSR PR
 LDA #$03
 JSR $FE95
 LDA #$11
 JSR COUT; 40 colonnes
 RTS
SSUP8 LDA #$08
 JSR PR   ;{crit 16 octets(8valeurs)+RET
 LDA RESULT
 SEC
 SBC #$08
 STA RESULT
 LDA RESULT+1
 SBC #00
 STA RESULT+1;soustrait 8 @ RESULT
 BRA LOOPPR 

*
* affiche le menu d'aide
*
HELP JSR HOME
 LDA #<AIDE1
 LDY #>AIDE1
 JSR STROUT
 LDA #<AIDE2
 LDY #>AIDE2
 JSR STROUT
 LDA #<AIDE3
 LDY #>AIDE3
 JSR STROUT
 LDA #<AIDE4
 LDY #>AIDE4
 JSR STROUT
attente1 BIT KS
attente LDA KB
 BPL attente
 CMP #$8D
 BNE attente1
 JSR HOME
 JMP CUT2
*
*  efface le bas de l'ecran
*
CLEOP LDA #$11
 STA CV
 JSR VTAB
 LDY #$00
 STY CH
 JSR $FC42 ;efface la fin de la page
 RTS
*
*  routine de cr{ation d'un fichier
*
SAVCRE JSR MLI; dans INBUF
 HEX C8 ; open
 DA OPEN
 BCC EXIST
 CMP #$46
 BEQ NOTEXIS 
 JMP ERROR
EXIST LDA REFNB
 STA CLOSE+1
 JSR MLI 
 HEX CC; close
 DA CLOSE
 BCC S6
 JMP ERROR
S6 JSR MLI
 HEX C1; destroy
 DA DEST
 BCC NOTEXIS 
 JMP ERROR
NOTEXIS JSR MLI
 HEX C0 ; create
 DA CREATE
 BCC S5
 JMP ERROR
S5 JSR MLI
 HEX C8; open
 DA OPEN
 BCC FINSAVE
 JMP ERROR
FINSAVE RTS
*
*   routine d'INPUT
*
INPUT LDA #$11
 STA CV
 JSR VTAB
 LDY #$00
 STY CH
 LDY #$BE; >
 STY PROMPT
 JSR GETLN
 TXA
 TAY
 BEQ finchar
goo LDA INBUF,X
 STA INBUF+1,X; decale la chaine 
 DEX
 BPL goo
 STY INBUF; et place la longueur
finchar RTS
*
* routine de traitement des erreurs
*
ERROR JSR CLEOP
 LDX #$00
ERR2 LDA MESSER,X
 BEQ FINERR
 JSR COUT
 INX
 BRA ERR2
FINERR BIT KS 
WAITK LDA KB
 BPL WAITK
 BIT KS
 JSR CLEOP
 LDA #$00
 STA CLOSE+1
 JSR MLI
 HEX CC;close all
 DA CLOSE
 SEC
 RTS
*
* multiplication LIG par COL
*
RESULT DS 2
SAVE DS 2
MULT LDA #00
 STA TEMPO
 STA RESULT
 STA RESULT+1
 LDA LIG
 STA SAVE
 LDA COL
 STA SAVE+1
 LDX #$08
MUL LSR LIG 
 BCC NOAD
 CLC
 LDA RESULT
 ADC COL
 STA RESULT
 LDA RESULT+1
 ADC TEMPO
 STA RESULT+1
NOAD ASL COL
 ROL TEMPO
 DEX 
 BNE MUL
 LDA SAVE
 STA LIG
 LDA SAVE+1
 STA COL
 RTS
*
*  {criture du nb d'octet dans A 
* sous forme text
*
WROUT STA TEMPO; sauve le nb. d'octets
 ASL ; *2 (2 octets pour 1)
 STA WRITE+4 
 LDA #$00
 STA WRITE+5; nb d'octets = 2*A
 LDA #<inbuf
 STA WRITE+2
 LDA #>inbuf
 STA WRITE+3;data buffer=$200
 LDX #$00
LOOPWR LDA (PTR6),Y
 JSR DESSAS; decode
 LDA CODE
 STA INBUF,X
 INX
 LDA CODE+1
 STA INBUF,X
 INX
 INY 
 BNE decct
 INC PTR6+1
decct DEC TEMPO
 BNE LOOPWR
 JSR MLI
 HEX CB;{cris 2*N octets(N valeurs)
 DA WRITE; write
 BCC FINWR
 JMP ERROR
FINWR RTS
*
*  imprime A octets
* sous forme text
*
SAVEY DS 1
pr STA TEMPO; sauve le nb. d'octets
 LDX #$00
 LDY SAVEY
LOPPR LDA (PTR6),Y
 JSR DESSAS; decode
 LDA CODE
 JSR COUT
 LDA CODE+1
 JSR COUT
 INY 
 STY SAVEY
 BNE decpr
 INC PTR6+1
decpr DEC TEMPO
 BNE LOPPR
 LDA #$8D
 JSR COUT
FINPR RTS
* 
*  routine qui transforme un octet en 2 octets
*  asci representant cet octet
* A contient l'octet a l'entr{e
*
CODE DS 2
SAVEX DS 1
DESSAS PHA
 STX SAVEX
 LSR
 LSR
 LSR
 LSR ; nibble haut dans nibble bas
 TAX
 LDA TABLE,X
 STA CODE
 PLA 
 AND #$0F
 TAX
 LDA TABLE,X
 STA CODE+1
 LDX SAVEX
 RTS
* 
*
*
SPATH DS 64
TABMES DA MESS1 
 DA MESS2
 DA MESS3
 DA MESS4
 DA MESS5
 DA MESS6
 DA MESS7
 DA MESS8
 DA MESS9
 DA MESS10 
*
TABLE ASC "0123456789ABCDEF"
*
ENTETE ASC "NBLIG HEX "
LIGN HEX 00008D
 ASC "NBCOL HEX "
COLO HEX 00008D
 ASC "CUT "
 HEX 00
*
HEX ASC " HEX "
 HEX 00
*
AIDE1 ASC "     MANIPULATION DES CUTS EN HGR"
 HEX 8D8D
 ASC "DEPLACEMENT DES BARRES DE DELEIMITATION"
 HEX 8D00
AIDE2 ASC "    A/Z  --->  barre gauche"
 HEX 8D
 ASC "    O/P  --->  barre droite"
 HEX 8D
 ASC "    E/D  --->  barre haute"
 HEX 8D
 ASC "    I/K  --->  barre basse"
 HEX 8D8D00
AIDE3 ASC "AUTRES COMMANDES"
 HEX 8D
 ASC " RETURN ---> enregistre le cut en $6000" 
 HEX 8D
 ASC " V      ---> vide la fenetre  
 HEX 8D
 ASC " C      ---> change le couleur du cut" 
 HEX 8D
 ASC " ESC    ---> retour au menu"
 HEX 8D00
AIDE4 ASC " ESP    ---> affiche le cut s{lectionn{"
 HEX 8D
 ASC " B      ---> forme blanche 1"
 HEX 8D
 ASC "^B      ---> forme blanche 2"
 HEX 8D8D8D
 ASC "  APPUYER SUR RETURN POUR REVENIR"
 HEX 00
RETURN HEX 8D
*
MESS1 ASC "CHARGER UNE IMAGE"
 HEX 00
MESS2 ASC "SAUVER UNE IMAGE"
 HEX 00
MESS3 ASC "EDITER EN HGR"
 HEX 00
MESS4 ASC "CHARGER UN CUT BINAIRE" 
 HEX 00
MESS5 ASC "SAUVER UN CUT EN FICHIER TEXT"
 HEX 00
MESS6 ASC "SAUVER UN CUT EN FICHIER BINAIRE"
 HEX 00
MESS7 ASC "IMPRIMER UN CUT"
 HEX 00
MESS8 ASC "CHANGER PREFIX"
 HEX 00
MESS9 ASC "AIDE !"
 HEX 00
MESS10 ASC "SORTIR"
 HEX 00
TITRE ASC "      CUT :  UTILITAIRE  GRPHIQUE"          
 HEX 00
MESSER ASC "ERREUR E/S. FRAPPEZ UNE TOUCHE"  
 HEX 00
MESSPRT ASC "PREPAREZ L'IMPRIMANTE ET RETURN" 
 HEX 00
PREFIX HEX 01
 DA PATH
*-----------------------
OPEN HEX 03
 DA INBUF
 DA BUFG
REFNB DS 1 
*-----------------------
READ HEX 04
 DS 1
 DA HGR
 DA HGR
LONG DS 2
*-----------------------
PATH DS 64
ONLINE HEX 02
UNIT DS 1
 DA PATH
*-----------------------
CLOSE HEX 01
 DS 1
*-----------------------
DEST HEX 01
 DA INBUF
*-----------------------
CREATE HEX 07
 DA INBUF
 HEX C3
TYPE HEX 06
 DA HGR
 HEX 01
 HEX 0000
 HEX 0000
*-----------------------
WRITE HEX 04
 DS 1
 DA HGR
 DA HGR
 DS 2
*
*
*******************************************
*                                         *
*         PROGRAMME  DE  "CUTS"           *  
*                                         *
*******************************************
*
TEXT EQU $FB39 
GRAPHICS EQU $C050
MIXOFF EQU $C052
HIRES EQU $C057
PAGE1 EQU $C054
SPKR EQU $C030
gauche DS 1
droite DS 1
haut DS 1
bas DS 1
POS DS 1
TEMPO DS 1
HGRPTR EQU $06
LIG EQU $6000
COL EQU $6001
*
INIT LDA GRAPHICS;MODE GRAPHIQUE
 LDA MIXOFF; non mixte
 LDA HIRES; HGR
 LDA PAGE1; en $2000
 LDY droite
 JSR ROUT1
 LDY gauche
 JSR ROUT1; affiche la barre gauche
 LDX haut
 JSR ROUT2
 LDX bas
 JSR ROUT2
BEEP LDA #$08; boucle de son
 JSR WAIT
 LDA SPKR
 DEY
 BNE BEEP
main BIT KS
main2 LDA KB
 BPL main2
 AND #$7F
 CMP #$41; A ?
 BNE suita
 JMP A
suita CMP #$5A; Z ?
 BNE suite0
 JMP Z
suite0 CMP #$4F ; O ?
 BNE suit22
 JMP O
suit22 CMP #$50; P ?
 BNE encor
 JMP P
encor CMP #$45; E ?
 BNE encore
 JMP E
encore CMP #$44; D ?
 BNE encore2  
 JMP D
encore2 CMP #$49; I ?
 BNE encore3
 JMP I
encore3 CMP #$4B; K ?
 BNE encore4
 JMP K
encore4 CMP #$0D  ; return ?
 BNE encore5
 JMP GO
encore5 CMP #$15; -> ?
 BNE encore6
 JMP FD
encore6 CMP #$08 ; <- ?
 BNE encore7 
 JMP FG
encore7 CMP #$0A; fleche en bas
 BNE encore8
 JMP FB
encore8 CMP #$0B; fleche en haut
 BNE encore9
 JMP FH
encore9 CMP #$20 ; Barre d'espace ?
 BNE encore0
 JMP ESP
encore0 CMP #$1B; escape ?
 BEQ bye
 CMP #$43; C ?
 BNE encore01
 JMP C
encore01 CMP #$56; V ?
 BNE encore02
 JMP V
 JMP main
encore02 CMP #$42; B ?
 BNE encore03
 JMP B
encore03 CMP #$02; ^B ?
 BNE fin
 JMP B2
fin JMP BEEP
bye LDY gauche
 JSR ROUT1
 LDY droite
 JSR ROUT1
 LDX haut
 JSR ROUT2
 LDX bas
 JSR ROUT2
 BIT KS
 LDA TEXT2
 RTS
*
* On arrive ici si lettre Z au clavier
*
Z LDY gauche 
 INY
 INY
 CPY droite
 BNE OK22
 JMP BEEP
OK22 DEY
 DEY
 JSR ROUT1
 INY
 STY gauche
 JSR ROUT1
 JMP MAIN
*
* On arrive ici si lettre A au clavier
*
A LDA gauche
 BNE SUITEAA
 JMP BEEP
SUITEAA TAY 
 JSR ROUT1
 DEY 
 STY gauche
 JSR ROUT1
 JMP main
*
* On arrive ici si lettre O au clavier
*
O LDY droite ; 
 DEY
 DEY
 CPY gauche
 BNE OK23
NON JMP BEEP
OK23 BEQ NON
 INY
 INY
 JSR ROUT1
 DEY
 STY droite
 JSR ROUT1
 JMP MAIN
* 
*
* On arrive ici si lettre P au clavier
*
P LDY droite
 CPY #$27
 BCC SUITE2
 JMP BEEP
SUITE2 NOP 
 JSR ROUT1
 INY
 STY droite
 JSR ROUT1
 JMP main
*
* On arrive ici si lettre D au clavier
*
D LDX haut
 INX
 INX
 CPX bas
 BCC ok4
 JMP BEEP 
ok4 DEX 
 DEX
 JSR ROUT2
 INX
 STX haut
 JSR ROUT2
 JMP main
*
* On arrive ici si lettre E au clavier
*
E LDX haut 
 BNE ok5
 JMP BEEP
ok5 JSR ROUT2
 DEX 
 STX haut
 JSR ROUT2
 JMP main
*
*
* On arrive ici si lettre I au clavier
*
I LDX haut
 INX
 INX
 CPX bas
 BCC ok6
 JMP BEEP
ok6 LDX bas
 JSR ROUT2
 DEX
 STX bas
 JSR ROUT2
 JMP main
*
* On arrive ici si lettre K au clavier
*
K LDX bas
 CPX #$BF
 BCC ok7
 JMP BEEP
ok7 JSR ROUT2 
 INX 
 STX bas
 JSR ROUT2
 JMP main
*
*     Cette routine 'eor' une ligne verticale  
*     @ l'entr{e :Y contient le n[ de la colonne
*     si ligne droite il faut placer #$01 en eor+1
*     siligne gauche : #$40 en eor+1 
ROUT1 LDA #$01
 STA eor+1
 CPY droite
 BEQ dr
 LDA #$40 
 STA eor+1
dr LDX #$00
LOOP LDA HI,X
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR
 LDA (HGRPTR),Y
eor EOR #$01
 STA (HGRPTR),Y
 INX 
 CPX #$C0
 BNE LOOP
 RTS
*
*     Cette routine 'eor' une ligne horizontale 
*     @ l'entr{e :X contient le n[ de la ligne
*
ROUT2 LDA HI,X
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR
 LDY #$27
LOOP2 LDA (HGRPTR),Y 
 EOR #$FF
 STA (HGRPTR),Y
 DEY
 BPL LOOP2
 RTS
*
*  EOR les 4 barres
*
eor4 LDY gauche
 JSR ROUT1
 LDY droite
 JSR ROUT1
 LDX haut
 JSR ROUT2
 LDX bas
 JSR ROUT2
 RTS 
*
* On arrive ici si RETURN 
*
GO JSR eor4
 LDA #$02
 STA PTR6
 LDA #$60;PTR6 pointe sur $6002
 STA PTR6+1; = debut de buffer
 LDA #$00
 STA POS; init offset ds buffer
 LDX HAUT; barre haute
 INX ; ligne en dessous
bigloop LDA HI,X
 STA HGRPTR+1 
 LDA LO,X
 STA HGRPTR; init HGRPTR
 LDY gauche; limite gauche
 INY
boucle LDA (HGRPTR),Y
 STY TEMPO; sauve position ecran
 LDY POS; offset dans buffer
 STA (PTR6),Y;depose ds buffer
 INY ; position buffer suivante
 BNE suite1
 INC PTR6+1    ; page suivante du buffer
suite1 STY POS; sauve l'offset incr{ment{
 LDY TEMPO; recupere la position
 INY
 CPY droite
 BNE boucle;dernier octet de la ligne?
 INX
 CPX bas; derniere ligne ?
 BNE bigloop ; non
ouf LDA bas
 SEC
 SBC haut
 STA LIG
 DEC LIG
 LDA droite
 SEC
 SBC gauche
 STA COL
 DEC COL
 JSR eor4
 JMP main
*
*
* On arrive ici si fleche-@-droite  au clavier 
* : decalage @ droite de la fenetre
*
FD JSR eor4
 LDX haut
 INX 
big LDA HI,X 
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR; init HGRPTR
 CLC
 PHP
 LDY gauche; limite gauche
 INY
boucl LDA (HGRPTR),Y
 PHA
 AND #$80
 STA TEMPO
 PLA
 PLP
 ROL
 ASL
 PHP
 LSR
 ORA TEMPO
 STA (hgrptr),Y
 INY
 CPY droite
 BNE boucl
 PLP
 INX
 CPX bas
 BNE big
 JSR eor4
 JMP main
*
*
* On arrive ici si fleche-@-gauche au clavier 
* : decalage @ droite de la fenetre
*
FG JSR eor4 ; efface les barres
 LDX haut
 INX 
big2 LDA HI,X 
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR; init HGRPTR
 CLC
 PHP
 LDY droite ; limite gauche
 DEY
boucl2 LDA (HGRPTR),Y
 PHA
 AND #$80
 STA TEMPO
 PLA
 ASL
 PLP
 ROR
 LSR
 PHP
 ORA TEMPO
 STA (hgrptr),Y
 DEY
 CPY gauche
 BNE boucl2
 PLP
 INX
 CPX bas
 BNE big2
 JSR eor4
 JMP main
*
* On arrive ici si lettre C au clavier 
*
C LDX haut
 INX 
big3 LDA HI,X 
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR; init HGRPTR
 LDY droite ; limite gauche
 DEY
boucl3 LDA (HGRPTR),Y
 EOR #$80
 STA (HGRPTR),Y
 DEY
 CPY gauche
 BNE boucl3
 INX
 CPX bas
 BNE big3
 JMP main
*
*
* On arrive ici si fleche en haut au clavier 
* : decalage a droite de la fenetre
*
FH JSR eor4
 LDX haut
big4 INX
 INX
 CPX bas
 BEQ finFH1
 LDA HI,X 
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR; init HGRPTR
 DEX 
 LDA HI,X 
 STA PTR6+1
 LDA LO,X
 STA PTR6; init PTR
 LDY gauche
 INY
boucl4 LDA (HGRPTR),Y
 STA (PTR6),Y
 INY
 CPY droite
 BNE boucl4
 JMP big4
finFH1 DEX
 LDA HI,X ; vide la ligne basse
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR; init HGRPTR
 LDA #$00  
 LDY gauche
 INY
enc STA (HGRPTR),Y
 INY 
 CPY droite
 BNE enc
 JSR eor4
 JMP main
*
*
* On arrive ici si fleche en bas au clavier 
* : decalage a droite de la fenetre
*
FB JSR eor4
 LDX bas 
 DEX
big5 LDA HI,X 
 STA PTR6+1
 LDA LO,X
 STA PTR6; init PTR
 DEX
 CPX haut
 BEQ finfb2
 LDA HI,X 
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR; init HGRPTR
 LDY gauche
 INY
boucl5 LDA (HGRPTR),Y
 STA (PTR6),Y
 INY
 CPY droite
 BNE boucl5
 JMP big5
finFB2 LDA #$00  
 LDY gauche
 INY
enc2 STA (HGRPTR),Y
 INY 
 CPY droite
 BNE enc2
 JSR eor4
 JMP main
*
* On arrive ici si barre d'espace au clavier 
* : affiche le cut stocke en $6000
*
*
ESP LDA LIG ; teste p{sence de cut
 BNE ESP2
 JMP BEEP
ESP2 JSR eor4
 LDA #$02
 STA PTR6
 LDA #$60
 STA PTR6+1
 LDX haut
 INX
deb LDA HI,X
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR
 LDA gauche
 SEC
 ADC HGRPTR
 BCC noinc
 INC HGRPTR+1
noinc STA HGRPTR
 LDY #$00
lop LDA (PTR6),Y 
 STA (HGRPTR),Y
 INY
 TYA
 STA TEMPO
 CLC
 ADC gauche
 CMP #$27
 BEQ nextlign
 CPY COL
 BNE lop
nextlign LDA PTR6 
 CLC
 ADC COL
 BCC noinc2
 INC PTR6+1
noinc2 STA PTR6 
 INX
 CPX #$C0
 BEQ finesp
 TXA
 SEC
 SBC haut
 CMP LIG
 BEQ deb
 BCC deb
FINESP JSR eor4
 JMP main
*
* lettre V au clavier
*
V JSR eor4
 LDX #00
CLEAR LDA HI,X
 STA HGRPTR+1
 LDA LO,X
 STA HGRPTR
 LDY #$00  
 LDA #$00
litloop STA (HGRPTR),Y
 INY 
 CPY #$28
 BNE litloop
 INX
 CPX #$C0
 BNE CLEAR
 JSR eor4
 JMP main
*
*  Cree la forme "blanche" pour l'animation
*  tous les bit @ 0 passent @ 1 si bit suivant = 1
*
SAVEWS DS 1
OCTET DS 1 
COMPT DS 1
B2 JSR EOR4;enleve les 4 barres
 LDX haut
newlign2 INX ;
 CPX bas ;toutes les lignes scann{es ?
 BEQ outws; oui
 LDA HI,X
 STA HGRPTR+1
 LDA LO,X; adresse de base
 STA HGRPTR
 LDY gauche; offset horizontal
newocte2 INY 
 CPY droite; dernier octet de la ligne?
 BEQ newlign2; oui : ligne suivante
 LDA (HGRPTR),Y; ramasse l'octet
newoct22 STA SAVEWS; non:  on le sauve
 LDA #00;compteur de bits a 0
 STA COMPT
LOOPWS2 ROR OCTET; boucle. octet contiendra 
 INC COMPT; l'octet transform{
 LDA COMPT
 CMP #08; 7 passes ?
 BNE ENCORWS2; non on continue
 LDA (HGRPTR),Y; oui: il faut poker le 8me bit 
 ROL ; : le bit de couleur
 LDA OCTET
 ROR ; en position 7
 STA (HGRPTR),Y; octet transform{ sur {cran
 BRA newocte2;octet suivant
encorws2 LSR SAVEWS; bit suivant
 BCC suitws2; nul ?
 BRA LOOPWS2 ; non : tout va bien
suitws2 LDA COMPT; non : dernier bit de l'octet?
 CMP #07
 BEQ suit1ws2; oui
 LDA SAVEWS; non : on regarde le bit suivant
 LSR
 BRA LOOPWS2; on fait entr{ C dans OCTET 
suit1ws2 INY  ; il faut regarder l'octet suivant
 CPY droite; dernier de la ligne ?
 BNE suit2ws2; non
 DEY ; oui: on suppose que le bit
 CLC ; suivant (hors du cut) est nul
 BRA LOOPWS2
suit2ws2 LDA (HGRPTR),Y; on examine l'octet suivant
 DEY ; remet Y en place
 LSR ; r{cupere le bit suivant
 BRA LOOPWS2
*
*
*  Cree la forme "blanche" pour l'animation
*  tous les bit @ 0 passent @ 1 si bit suivant = 1
*  et si bit pr{cedent = 1
*
OUTWS JSR eor4
 JMP main
FLAG DS 1
B JSR EOR4;enleve les 4 barres
 LDX haut
newligne INX ;
 CPX bas ;toutes les lignes scann{es ?
 BEQ outws; oui
 LDA #00; on suppose que les bits
 STA FLAG; @ gauche du cut sont vides 
 LDA HI,X
 STA HGRPTR+1
 LDA LO,X; adresse de base
 STA HGRPTR
 LDY gauche; offset horizontal
newoctet INY 
 CPY droite; dernier octet de la ligne?
 BEQ newligne; oui : ligne suivante
 LDA (HGRPTR),Y; ramasse l'octet
 BNE newoct2; =0 ?
 LDA #00; oui:
 STA FLAG; on passe au suivant
 BRA newoctet
newoct2 STA SAVEWS; non:  on le sauve
 LDA #00;compteur de bits a 0
 STA COMPT
LOOPWS ROR OCTET; boucle. octet contiendra 
 INC COMPT; l'octet transform{
 LDA COMPT
 CMP #08; 7 passes ?
 BNE ENCORWS; non on continue
 LDA (HGRPTR),Y; oui: il faut poker le 8me bit 
 ROL ; : le bit de couleur
 LDA OCTET
 ROR ; en position 7
 STA (HGRPTR),Y; octet transform{ sur {cran
 BRA newoctet;octet suivant
encorws LSR SAVEWS; bit suivant
 BCC suitws; nul ?
 LDA #01
 STA FLAG
 BRA LOOPWS ; non : tout va bien
suitws LDA FLAG ; oui : ca se complique !
 CLC ; bit pr{c{dent =0
 BEQ LOOPWS;  oui : alors ok
 LDA #00
 STA FLAG; on remet flag a 0
 LDA COMPT; non : dernier bit de l'octet?
 CMP #07
 BEQ suit1ws; oui
 LDA SAVEWS; non : on regarde le bit suivant
 LSR
 BCC LOOPWS; =0 : ca va
 BRA LOOPWS; on fait entre 1 dans OCTET 
suit1ws INY  ; il faut regarder l'octet suivant
 CPY droite; dernier de la ligne ?
 BNE suit2ws; non
 DEY ; oui: on suppose que le bit
 CLC ; suivant (hors du cut) est nul
 BRA LOOPWS
suit2ws LDA (HGRPTR),Y; on examine l'octet suivant
 DEY ; remet Y en place
 LSR ; r{cupere le bit suivant
 BCC LOOPWS; il est vide
 BRA LOOPWS
*
*
*
*
HI HEX 2024282C3034383C
 HEX 2024282C3034383C
 HEX 2125292D3135393D
 HEX 2125292D3135393D
 HEX 22262A2E32363A3E
 HEX 22262A2E32363A3E
 HEX 23272B2F33373B3F
 HEX 23272B2F33373B3F
 HEX 2024282C3034383C
 HEX 2024282C3034383C
 HEX 2125292D3135393D
 HEX 2125292D3135393D
 HEX 22262A2E32363A3E
 HEX 22262A2E32363A3E
 HEX 23272B2F33373B3F
 HEX 23272B2F33373B3F
 HEX 2024282C3034383C
 HEX 2024282C3034383C
 HEX 2125292D3135393D
 HEX 2125292D3135393D
 HEX 22262A2E32363A3E
 HEX 22262A2E32363A3E
 HEX 23272B2F33373B3F
 HEX 23272B2F33373B3F
LO HEX 0000000000000000
 HEX 8080808080808080
 HEX 0000000000000000
 HEX 8080808080808080
 HEX 0000000000000000
 HEX 8080808080808080
 HEX 0000000000000000
 HEX 8080808080808080
 HEX 2828282828282828
 HEX A8A8A8A8A8A8A8A8
 HEX 2828282828282828
 HEX A8A8A8A8A8A8A8A8
 HEX 2828282828282828
 HEX A8A8A8A8A8A8A8A8
 HEX 2828282828282828
 HEX A8A8A8A8A8A8A8A8
 HEX 5050505050505050
 HEX D0D0D0D0D0D0D0D0
 HEX 5050505050505050
 HEX D0D0D0D0D0D0D0D0
 HEX 5050505050505050
 HEX D0D0D0D0D0D0D0D0
 HEX 5050505050505050
 HEX D0D0D0D0D0D0D0D0
*

?