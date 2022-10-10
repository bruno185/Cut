******************************************
*                                        *
*   cut :  le desassembleur d'image      *
*                                        *
*        adapté pour merlin 32           *
******************************************
*
ch        equ $24
cv        equ $25
prompt    equ $33
text2     equ $c051
ptr6      equ $08
hgr       equ $2000
inbuf     equ $200
ks        equ $c010
kb        equ $c000
wait      equ $fca8
cout      equ $fded 
getln     equ $fd6a
strout    equ $db3a
home      equ $fc58
vtab      equ $fc22
clerol    equ $fc9c
messnb    equ $f9
settext   equ $fb39
setinv    equ $fe80
setnorm   equ $fe84 
mli       equ $bf00
bufg      equ $5c00

devnum   equ $bf30
*
          org $4000

          ldy #$27
          sty droite     ; init les fronti}res
          ldy #$00
          sty gauche
          sty haut
          ldx #$bf
          stx bas
          ldy #$00
          sty lig        ; initialise le nb lignes
cut       lda #$11
          jsr cout       ; 40 colonnes
          jsr home
          jsr settext


* modification 2022
* Objectif 1 : éviter une erreur E/S si on lance CUT depuis un drive différent de S6D1.
* Le principe : on obtient le prefix à partir de slot et drive par défaut ($be3c/$be3d)
* (et non pas en imposant S6D1).
* Objectif 2 : save / restore prompt char.

          XC                ; 65C02 opcodes
          lda prompt
          sta saveprompt    ; sauve le caractère du prompt
          jsr mli           ; getprefix, prefix ==> "path"
          hex c7
          da prefix
          bcc suitegp
          jsr error
          bra men
suitegp
          lda path          ; 1er car. = long.
          beq noprefix      ; pas de prefix (log. = 0) goto noprefix 
          jmp good1         ; sinon : affichage 

noprefix
          lda devnum        ; dernier slot/drive utilisé

* fin modification 2022

          sta unit       ; param du mli online
men       jsr mli
          hex c5         ; on_line : récupère le prefix dans path
          da online
          bcc suite
          jsr error
          bra men        ; loop sur l'erreur (remettre la disquette dans lecteur)
suite     lda path
          and #$0f       ;longueur dans nibble bas
          sta path
          tax
l1        lda path,x
          sta path+1,x   ; decalage d'un octet
          dex
          bne l1
          inc path
          inc path       ;long= long+2
          ldx path
          lda #$af
          sta path,x     ; / apres
          sta path+1     ; et / avant

setprefix
          jsr mli        ; set_prefix
          hex c6
          da prefix
          bcc good1
          jsr error
          rts
          ;bra men
good1     ldx path
          inx 
savepref  lda path,x
          sta spath,x
          dex
          bpl savepref 
cut2      jsr affpref
          lda #$01
          sta cv
          jsr vtab
          jsr ligne      ; trace une ligne
          lda #$03
          sta cv
          jsr vtab
          lda #$00
          sta ch
          lda #<titre
          ldy #>titre
          jsr strout     ;affiche le titre
          lda #$04
          sta cv
          jsr vtab
          jsr ligne      ; trace une ligne
          jsr menu       ; affiche le menu
          lda #$0f
          sta cv
          jsr vtab
          jsr ligne      ; trace une ligne
*---------------------------------------------
bigmain   bit ks
kbd       lda kb 
          bpl kbd
          bit ks
          cmp #$8b
          bne suit1
          jsr fhmain 
          bra bigmain
suit1     cmp #$8a
          bne suit2
          jsr fbmain 
          bra bigmain
suit2     cmp #$8d 
          bne ffin
          jsr exec
ffin      bra bigmain
*--------------------------------------------
*
*  affiche une option (n[ + 5 ds messnb)
*
affi      lda messnb
          sta cv
          jsr vtab
          lda #$00
          sta ch
          lda messnb
          sec
          sbc #$05
          asl
          tax
          lda tabmes,x  
          inx
          ldy tabmes,x
          jsr strout
finaffi   rts
*
*  routine d'affichage du prefix dans path
*
affpref   ldx #$00
          stx ch
          stx cv
          jsr vtab
          ldx #$00
          sta ch
          lda spath
          beq finpref 
affp2     lda spath+1,x
          ora #$80
          jsr cout
          inx
          cpx spath
          bne affp2
          jsr clerol
finpref   rts            ; si il n'y en a pas
*
*  trace une ligne
*
ligne     ldx #$00
          stx ch
          ldy #$28
          lda #$df
lign2     jsr cout 
          dey
          bne lign2
          rts
*
*   affiche les optipons
*
menu      lda #05
          cmp #$0f
          bcs finmenu
          sta messnb
menu2     jsr fbmain
          inc menu+1
          bra menu
finmenu   lda #$05
          sta menu+1
          rts
*
*    si fleche en bas
*
fbmain    jsr affi       ;affiche option en normal 
          jsr setinv
          lda messnb
          cmp #$0e
          beq suit
          inc messnb     ; option suivante 
          jsr affi       ; en inverse
          bra finfb
suit      lda #$05
          sta messnb
          jsr affi  
finfb     jsr setnorm
          rts
*
*    si fleche en haut
*
fhmain    jsr affi       ;affiche option en normal 
          jsr setinv
          lda messnb
          cmp #$05
          beq fhsuit
          dec messnb     ; option suivante 
          jsr affi       ; en inverse
          bra finfh
fhsuit    lda #$0e
          sta messnb
          jsr affi  
finfh     jsr setnorm
          rts
*
*  execution d'une option
*
exec      lda messnb
          sec
          sbc #$05
          bne autre
          jmp chargi     ; charge image
autre     cmp #$02       ; hgr
          bne autre1
          jmp init
autre1    cmp #$01
          bne autre2
          jmp sauvei
autre2    cmp #$07
          bne autre3
          jmp newpref 
autre3    cmp #$09
          bne autre4
          pla
          pla
          jsr home          ; fin du programm par le menu

* modification 2022 : restoration du prompt
          lda saveprompt
          sta prompt
* fin modification 2022 

          rts
autre4    cmp #$05 
          bne autre5
          jmp sauvcb
autre5    cmp #$03
          bne autre6
          jmp charcb
autre6    cmp #$04
          bne autre7
          jmp savect
autre7    cmp #$06 
          bne autre8
          lda lig        ; cut selectionne ?
          beq autre8
          jsr prtcut
          pla
          pla            ; depile adresse retour
          jmp cut2
autre8    cmp #$08
          bne finexec
          pla
          pla            ; depile adresse retour
          jmp help
finexec   rts
*
*  charge une image
*
chargi    jsr input
          bne chargi2
          jmp cleop
chargi2   jsr mli        ; dans inbuf
          hex c8         ; open
          da open
          bcc ok
          jmp error
ok        lda refnb
          sta read+1
          lda #<hgr
          sta read+2
          sta read+4
          lda #>hgr
          sta read+3
          sta read+5
          jsr mli
          hex ca         ; read
          da read
          bcc s4
          jmp error
s4        jsr cleop
          lda refnb
          sta close+1
          jsr mli
          hex cc         ; close
          da close
ok2       rts
*
*  sauve une image
*
sauvei    jsr input
          bne sauvei2
          jmp cleop
sauvei2   lda #$06 
          sta create+4   ; fichier bin
          lda #<hgr
          sta create+5
          lda #>hgr
          sta create+6   ; adresse de chargement
          jsr savcre
          bcs outsavi 
          lda refnb
          sta write+1
          lda #<hgr
          sta write+2
          sta write+4
          lda #>hgr
          sta write+3    ; adresse
          sta write+5    ; longeur
          jsr mli
          hex cb         ; write
          da write
          bcc ferme
          jmp error
ferme     lda refnb
          sta close+1
          jsr mli
          hex cc         ; close
          da close
outsavi   jsr cleop
          rts
*
*  nouveau prefix
*
newpref   jsr input
          bne loopnew
          jmp cleop
loopnew   ldx inbuf
loopnew2  lda inbuf,x    ;recupere le prefix
          sta path,x     ;dans path
          dex
          bpl loopnew2
          jsr mli        ; set_prefix
          hex c6
          da prefix      ; param. de destroy
          bcc finnewp
          jmp error
finnewp   jsr cleop
          jsr mli
          hex c7         ; get_prefix
          da prefix
savpre    ldx path
          inx 
savepre2  lda path,x
          sta spath,x    ; sauve le nouveau prefix
          dex
          bpl savepre2
          jsr affpref
          rts
*
* sauve un cut binaire
*
sauvcb    lda lig
          bne scb
          rts
scb       jsr input
          bne scb2
          jmp cleop
scb2      jsr mult       ;lig*col dans result
          lda result
          clc
          adc #$02       ;ajoute 2(octets lig et col) 
          sta write+4
          lda #$00
          adc result+1
          sta write+5    ; prepare nb d'octet @ ecrire
          lda #<lig
          sta write+2    ;sauvera a partir de $6000
          sta create+5   ;$6000=adresse de chargement 
          lda #>lig      ; le fichier binaire se charge
          sta write+3    ; l'adresse = $6000
          sta create+6   ; a l'adresse = $6000
          lda #$06 
          sta create+4   ; fichier bin
          jsr savcre
          bcs fincb
writ      lda refnb 
          sta write+1
          jsr mli
          hex cb         ; write
          da write
          bcc s33
          jmp error
s33       jsr cleop
          lda refnb
          sta close+1
          jsr mli
          hex cc         ; close
          da close
fincb     rts
*
*  charge un cut binaire
*
charcb    jsr input
          bne charcb2
          jmp cleop
charcb2   jsr mli        ; dans inbuf
          hex c8         ; open
          da open
          bcc okcb
          jmp error
okcb      lda refnb
          sta read+1
          lda #<lig
          sta read+2
          lda #>lig
          sta read+3
          lda #$02
          sta read+4
          lda #00
          sta read+5     ;on lit 2 octets(lig et col)
          jsr mli
          hex ca         ; read
          da read
          bcc s44
          jmp error
s44       jsr mult
          lda result 
          sta read+4
          lda result+1
          sta read+5
          inc read+2 
          inc read+2     ; buffer a partir de $6002
          jsr mli        ;lit les octets suivant
          hex ca         ; read
          da read
          bcc s442
          jmp error
s442      jsr cleop
          lda refnb
          sta close+1
          jsr mli
          hex cc         ; read
          da close
          rts
*
* sauve cut en fichier text
*
savect    lda lig
          bne savect2
          rts
savect2   jsr mult
          jsr input
          bne savect3
          jmp cleop
savect3   lda #$04       ;text
          sta create+4 
          jsr savcre 
          bcc okct
          jmp finctext
okct      lda refnb
          sta write+1
          ldy #$00       ;init y
          lda #$02
          sta ptr6
          lda #$60
          sta ptr6+1     ; ptr6--> $6002
          lda lig
          jsr dessas
          lda code
          sta lign
          lda code+1
          sta lign+1
          lda col
          jsr dessas
          lda code
          sta colo
          lda code+1
          sta colo+1
          lda #<entete 
          sta write+2
          lda #>entete 
          sta write+3
          lda #$1d       ; 29 octets
          sta write+4
          lda #$00
          sta write+5
          jsr mli        ; ecris l'entete
          hex cb         ; write
          da write
          bcc loopct
          jmp error
loopct    lda #<hex  
          sta write+2
          lda #>hex  
          sta write+3    ; pr{pare l'ecriture 
          lda #$05       ; de 5 octets
          sta write+4    ; : 'hex '
          lda #$00
          sta write+5
          jsr mli        ; ecris ' hex '
          hex cb         ; write
          da write
          bcc suitct
          jmp error 
suitct    lda result
          cmp #$08
          beq a8
          bcs sup8
a8        lda result+1
          bne sup8
          lda result
          jsr wrout      ;si <=8 octets @ {crire
          lda #<return
          sta write+2
          lda #>return
          sta write+3    ; pr{pare l'ecriture 
          lda #$01       ; d' 1 octet
          sta write+4    ; : caractere return
          lda #$00
          sta write+5
          jsr mli        ; ecris un return
          hex cb         ; write
          da write
closect   jsr mli
          hex cc         ;close
          da close
finctext  jmp cleop      ;sort en effacant
sup8      lda #$08
          jsr wrout      ;{crit 16 octets(8valeurs)
          lda result
          sec
          sbc #$08
          sta result
          lda result+1
          sbc #00
          sta result+1   ;soustrait 8 @ result
          lda #<return
          sta write+2
          lda #>return
          sta write+3    ; pr{pare l'ecriture 
          lda #$01       ; d' 1 octet
          sta write+4    ; : caractere return
          lda #$00
          sta write+5
          jsr mli        ; ecris un return
          hex cb         ; write
          da write
          bcs errct
          jmp loopct
errct     jmp error
* 
*  imprime un cut desassembl{
*
prtcut    jsr mult
          lda #$11
          sta cv
          jsr vtab
          ldx #$00
          stx ch
mm1       lda messprt,x
          beq mm
          jsr cout
          inx
          bra mm1
mm        bit ks 
wtk       lda kb
          bpl wtk
          bit ks
*
          lda #01
          jsr $fe95
          jsr cleop
          lda lig
          jsr dessas
          lda code
          sta lign
          lda code+1
          sta lign+1
          lda col
          jsr dessas
          lda code
          sta colo
          lda code+1
          sta colo+1
*
          lda #<entete 
          ldy #>entete 
          jsr strout
          ldy #00        ;init y
          sty savey
          lda #$02
          sta ptr6
          lda #$60
          sta ptr6+1     ; ptr6--> $6002
looppr    lda #<hex  
          ldy #>hex  
          jsr strout
          lda result
          cmp #$08
          beq aa8
          bcs ssup8
aa8       lda result+1
          bne ssup8
          lda result
          jsr pr
          lda #$03
          jsr $fe95
          lda #$11
          jsr cout       ; 40 colonnes
          rts
ssup8     lda #$08
          jsr pr         ;{crit 16 octets(8valeurs)+ret
          lda result
          sec
          sbc #$08
          sta result
          lda result+1
          sbc #00
          sta result+1   ;soustrait 8 @ result
          bra looppr 

*
* affiche le menu d'aide
*
help      jsr home
          lda #<aide1
          ldy #>aide1
          jsr strout
          lda #<aide2
          ldy #>aide2
          jsr strout
          lda #<aide3
          ldy #>aide3
          jsr strout
          lda #<aide4
          ldy #>aide4
          jsr strout
attente1  bit ks
attente   lda kb
          bpl attente
          cmp #$8d
          bne attente1
          jsr home
          jmp cut2
*
*  efface le bas de l'ecran
*
cleop     lda #$11
          sta cv
          jsr vtab
          ldy #$00
          sty ch
          jsr $fc42      ;efface la fin de la page
          rts
*
*  routine de cr{ation d'un fichier
*
savcre    jsr mli        ; dans inbuf
          hex c8         ; open
          da open
          bcc exist
          cmp #$46
          beq notexis 
          jmp error
exist     lda refnb
          sta close+1
          jsr mli 
          hex cc         ; close
          da close
          bcc s6
          jmp error
s6        jsr mli
          hex c1         ; destroy
          da dest
          bcc notexis 
          jmp error
notexis   jsr mli
          hex c0         ; create
          da create
          bcc s5
          jmp error
s5        jsr mli
          hex c8         ; open
          da open
          bcc finsave
          jmp error
finsave   rts
*
*   routine d'input
*


input     lda #$11
          sta cv
          jsr vtab
          ldy #$00
          sty ch
          ldy #$be       ; >
          sty prompt
          jsr getln
          txa
          tay
          beq finchar
goo       lda inbuf,x
          sta inbuf+1,x  ; decale la chaine 
          dex
          bpl goo
          sty inbuf      ; et place la longueur
finchar   rts

*
* routine de traitement des erreurs
*
error     jsr cleop
          ldx #$00
err2      lda messer,x
          beq finerr
          jsr cout
          inx
          bra err2
finerr    bit ks 
waitk     lda kb
          bpl waitk
          bit ks
          jsr cleop
          lda #$00
          sta close+1
          jsr mli
          hex cc         ;close all
          da close
          sec
          rts
*
* multiplication lig par col
*
result    ds 2
save      ds 2
mult      lda #00
          sta tempo
          sta result
          sta result+1
          lda lig
          sta save
          lda col
          sta save+1
          ldx #$08
mul       lsr lig 
          bcc noad
          clc
          lda result
          adc col
          sta result
          lda result+1
          adc tempo
          sta result+1
noad      asl col
          rol tempo
          dex 
          bne mul
          lda save
          sta lig
          lda save+1
          sta col
          rts
*
*  {criture du nb d'octet dans a 
* sous forme text
*
wrout     sta tempo      ; sauve le nb. d'octets
          asl            ; *2 (2 octets pour 1)
          sta write+4 
          lda #$00
          sta write+5    ; nb d'octets = 2*a
          lda #<inbuf
          sta write+2
          lda #>inbuf
          sta write+3    ;data buffer=$200
          ldx #$00
loopwr    lda (ptr6),y
          jsr dessas     ; decode
          lda code
          sta inbuf,x
          inx
          lda code+1
          sta inbuf,x
          inx
          iny 
          bne decct
          inc ptr6+1
decct     dec tempo
          bne loopwr
          jsr mli
          hex cb         ;{cris 2*n octets(n valeurs)
          da write       ; write
          bcc finwr
          jmp error
finwr     rts
*
*  imprime a octets
* sous forme text
*
savey     ds 1
pr        sta tempo      ; sauve le nb. d'octets
          ldx #$00
          ldy savey
loppr     lda (ptr6),y
          jsr dessas     ; decode
          lda code
          jsr cout
          lda code+1
          jsr cout
          iny 
          sty savey
          bne decpr
          inc ptr6+1
decpr     dec tempo
          bne loppr
          lda #$8d
          jsr cout
finpr     rts
* 
*  routine qui transforme un octet en 2 octets
*  asci representant cet octet
* a contient l'octet a l'entr{e
*
code      ds 2
savex     ds 1
dessas    pha
          stx savex
          lsr
          lsr
          lsr
          lsr            ; nibble haut dans nibble bas
          tax
          lda table,x
          sta code
          pla 
          and #$0f
          tax
          lda table,x
          sta code+1
          ldx savex
          rts
* 
*
*
spath     ds 64
tabmes    da mess1 
          da mess2
          da mess3
          da mess4
          da mess5
          da mess6
          da mess7
          da mess8
          da mess9
          da mess10 
*
table     asc "0123456789abcdef"
*
entete    asc "nblig hex "
lign      hex 00008d
          asc "nbcol hex "
colo      hex 00008d
          asc "cut "
          hex 00
*
hex       asc " hex "
          hex 00
*
aide1     asc "     manipulation des cuts en hgr"
          hex 8d8d
          asc "deplacement des barres de deleimitation"
          hex 8d00
aide2     asc "    a/z  --->  barre gauche"
          hex 8d
          asc "    o/p  --->  barre droite"
          hex 8d
          asc "    e/d  --->  barre haute"
          hex 8d
          asc "    i/k  --->  barre basse"
          hex 8d8d00
aide3     asc "autres commandes"
          hex 8d
          asc " return ---> enregistre le cut en $6000" 
          hex 8d
          asc " v      ---> vide la fenetre"  
          hex 8d
          asc " c      ---> change le couleur du cut" 
          hex 8d
          asc " esc    ---> retour au menu"
          hex 8d00
aide4     asc " esp    ---> affiche le cut selectionne"
          hex 8d
          asc " b      ---> forme blanche 1"
          hex 8d
          asc "^b      ---> forme blanche 2"
          hex 8d8d8d
          asc "  appuyer sur return pour revenir"
          hex 00
return    hex 8d
*
mess1     asc "CHARGER UNE IMAGE"
          hex 00
mess2     asc "SAUVER UNE IMAGE"
          hex 00
mess3     asc "EDITER EN HGR"
          hex 00
mess4     asc "CHARGER UN CUT BINAIRE" 
          hex 00
mess5     asc "SAUVER UN CUT EN FICHIER TEXT"
          hex 00
mess6     asc "SAUVER UN CUT EN FICHIER BINAIRE"
          hex 00
mess7     asc "IMPRIMER UN CUT"
          hex 00
mess8     asc "CHANGER PREFIX"
          hex 00
mess9     asc "AIDE !"
          hex 00
mess10    asc "SORTIR"
          hex 00
titre     asc "      cut :  utilitaire  grphique"          
          hex 00
messer    asc "erreur e/s. frappez une touche"  
          hex 00
messprt   asc "preparez l'imprimante et return" 
          hex 00

prefix    hex 01
          da path
*-----------------------
open      hex 03
          da inbuf
          da bufg
refnb     ds 1 
*-----------------------
read      hex 04
          ds 1
          da hgr
          da hgr
long      ds 2
*-----------------------
online    hex 02
unit      ds 1
          da path
path      ds 256
*-----------------------
close     hex 01
          ds 1
*-----------------------
dest      hex 01
          da inbuf
*-----------------------
create    hex 07
          da inbuf
          hex c3
type      hex 06
          da hgr
          hex 01
          hex 0000
          hex 0000
*-----------------------
write     hex 04
          ds 1
          da hgr
          da hgr
          ds 2
*
saveprompt hex 00
*
*******************************************
*                                         *
*         programme  de  "cuts"           *  
*                                         *
*******************************************
*
text      equ $fb39 
graphics  equ $c050
mixoff    equ $c052
hires     equ $c057
page1     equ $c054
spkr      equ $c030
gauche    ds 1
droite    ds 1
haut      ds 1
bas       ds 1
pos       ds 1
tempo     ds 1
hgrptr    equ $06
lig       equ $6000
col       equ $6001
*
init      lda graphics   ;mode graphique
          lda mixoff     ; non mixte
          lda hires      ; hgr
          lda page1      ; en $2000
          ldy droite
          jsr rout1
          ldy gauche
          jsr rout1      ; affiche la barre gauche
          ldx haut
          jsr rout2
          ldx bas
          jsr rout2
beep      lda #$08       ; boucle de son
          jsr wait
          lda spkr
          dey
          bne beep
main      bit ks
main2     lda kb
          bpl main2
          and #$7f
          cmp #$41       ; a ?
          bne suita
          jmp lettrea
suita     cmp #$5a       ; z ?
          bne suite0
          jmp lettrez
suite0    cmp #$4f       ; o ?
          bne suit22
          jmp o
suit22    cmp #$50       ; p ?
          bne encor
          jmp p
encor     cmp #$45       ; e ?
          bne encore
          jmp e
encore    cmp #$44       ; d ?
          bne encore2  
          jmp d
encore2   cmp #$49       ; i ?
          bne encore3
          jmp i
encore3   cmp #$4b       ; k ?
          bne encore4
          jmp k
encore4   cmp #$0d       ; return ?
          bne encore5
          jmp go
encore5   cmp #$15       ; -> ?
          bne encore6
          jmp fd
encore6   cmp #$08       ; <- ?
          bne encore7 
          jmp fg
encore7   cmp #$0a       ; fleche en bas
          bne encore8
          jmp fb
encore8   cmp #$0b       ; fleche en haut
          bne encore9
          jmp fh
encore9   cmp #$20       ; barre d'espace ?
          bne encore0
          jmp esp
encore0   cmp #$1b       ; escape ?
          beq bye
          cmp #$43       ; c ?
          bne encore01
          jmp c
encore01  cmp #$56       ; v ?
          bne encore02
          jmp v
          jmp main
encore02  cmp #$42       ; b ?
          bne encore03
          jmp b
encore03  cmp #$02       ; ^b ?
          bne fin
          jmp b2
fin       jmp beep
bye       ldy gauche
          jsr rout1
          ldy droite
          jsr rout1
          ldx haut
          jsr rout2
          ldx bas
          jsr rout2
          bit ks
          lda text2
          rts
*
* on arrive ici si lettre z au clavier
*
lettrez   ldy gauche 
          iny
          iny
          cpy droite
          bne ok22
          jmp beep
ok22      dey
          dey
          jsr rout1
          iny
          sty gauche
          jsr rout1
          jmp main
*
* on arrive ici si lettre a au clavier
*
lettrea   lda gauche
          bne suiteaa
          jmp beep
suiteaa   tay 
          jsr rout1
          dey 
          sty gauche
          jsr rout1
          jmp main
*
* on arrive ici si lettre o au clavier
*
o         ldy droite     ; 
          dey
          dey
          cpy gauche
          bne ok23
non       jmp beep
ok23      beq non
          iny
          iny
          jsr rout1
          dey
          sty droite
          jsr rout1
          jmp main
* 
*
* on arrive ici si lettre p au clavier
*
p         ldy droite
          cpy #$27
          bcc suite2
          jmp beep
suite2    nop 
          jsr rout1
          iny
          sty droite
          jsr rout1
          jmp main
*
* on arrive ici si lettre d au clavier
*
d         ldx haut
          inx
          inx
          cpx bas
          bcc ok4
          jmp beep 
ok4       dex 
          dex
          jsr rout2
          inx
          stx haut
          jsr rout2
          jmp main
*
* on arrive ici si lettre e au clavier
*
e         ldx haut 
          bne ok5
          jmp beep
ok5       jsr rout2
          dex 
          stx haut
          jsr rout2
          jmp main
*
*
* on arrive ici si lettre i au clavier
*
i         ldx haut
          inx
          inx
          cpx bas
          bcc ok6
          jmp beep
ok6       ldx bas
          jsr rout2
          dex
          stx bas
          jsr rout2
          jmp main
*
* on arrive ici si lettre k au clavier
*
k         ldx bas
          cpx #$bf
          bcc ok7
          jmp beep
ok7       jsr rout2 
          inx 
          stx bas
          jsr rout2
          jmp main
*
*     cette routine 'eor' une ligne verticale  
*     @ l'entr{e :y contient le n[ de la colonne
*     si ligne droite il faut placer #$01 en eor+1
*     siligne gauche : #$40 en eor+1 
rout1     lda #$01
          sta eor+1
          cpy droite
          beq dr
          lda #$40 
          sta eor+1
dr        ldx #$00
loop      lda hi,x
          sta hgrptr+1
          lda lo,x
          sta hgrptr
          lda (hgrptr),y
eor       eor #$01
          sta (hgrptr),y
          inx 
          cpx #$c0
          bne loop
          rts
*
*     cette routine 'eor' une ligne horizontale 
*     @ l'entr{e :x contient le n[ de la ligne
*
rout2     lda hi,x
          sta hgrptr+1
          lda lo,x
          sta hgrptr
          ldy #$27
loop2     lda (hgrptr),y 
          eor #$ff
          sta (hgrptr),y
          dey
          bpl loop2
          rts
*
*  eor les 4 barres
*
eor4      ldy gauche
          jsr rout1
          ldy droite
          jsr rout1
          ldx haut
          jsr rout2
          ldx bas
          jsr rout2
          rts 
*
* on arrive ici si return 
*
go        jsr eor4
          lda #$02
          sta ptr6
          lda #$60       ;ptr6 pointe sur $6002
          sta ptr6+1     ; = debut de buffer
          lda #$00
          sta pos        ; init offset ds buffer
          ldx haut       ; barre haute
          inx            ; ligne en dessous
bigloop   lda hi,x
          sta hgrptr+1 
          lda lo,x
          sta hgrptr     ; init hgrptr
          ldy gauche     ; limite gauche
          iny
boucle    lda (hgrptr),y
          sty tempo      ; sauve position ecran
          ldy pos        ; offset dans buffer
          sta (ptr6),y   ;depose ds buffer
          iny            ; position buffer suivante
          bne suite1
          inc ptr6+1     ; page suivante du buffer
suite1    sty pos        ; sauve l'offset incr{ment{
          ldy tempo      ; recupere la position
          iny
          cpy droite
          bne boucle     ;dernier octet de la ligne?
          inx
          cpx bas        ; derniere ligne ?
          bne bigloop    ; non
ouf       lda bas
          sec
          sbc haut
          sta lig
          dec lig
          lda droite
          sec
          sbc gauche
          sta col
          dec col
          jsr eor4
          jmp main
*
*
* on arrive ici si fleche-@-droite  au clavier 
* : decalage @ droite de la fenetre
*
fd        jsr eor4
          ldx haut
          inx 
big       lda hi,x 
          sta hgrptr+1
          lda lo,x
          sta hgrptr     ; init hgrptr
          clc
          php
          ldy gauche     ; limite gauche
          iny
boucl     lda (hgrptr),y
          pha
          and #$80
          sta tempo
          pla
          plp
          rol
          asl
          php
          lsr
          ora tempo
          sta (hgrptr),y
          iny
          cpy droite
          bne boucl
          plp
          inx
          cpx bas
          bne big
          jsr eor4
          jmp main
*
*
* on arrive ici si fleche-@-gauche au clavier 
* : decalage @ droite de la fenetre
*
fg        jsr eor4       ; efface les barres
          ldx haut
          inx 
big2      lda hi,x 
          sta hgrptr+1
          lda lo,x
          sta hgrptr     ; init hgrptr
          clc
          php
          ldy droite     ; limite gauche
          dey
boucl2    lda (hgrptr),y
          pha
          and #$80
          sta tempo
          pla
          asl
          plp
          ror
          lsr
          php
          ora tempo
          sta (hgrptr),y
          dey
          cpy gauche
          bne boucl2
          plp
          inx
          cpx bas
          bne big2
          jsr eor4
          jmp main
*
* on arrive ici si lettre c au clavier 
*
c         ldx haut
          inx 
big3      lda hi,x 
          sta hgrptr+1
          lda lo,x
          sta hgrptr     ; init hgrptr
          ldy droite     ; limite gauche
          dey
boucl3    lda (hgrptr),y
          eor #$80
          sta (hgrptr),y
          dey
          cpy gauche
          bne boucl3
          inx
          cpx bas
          bne big3
          jmp main
*
*
* on arrive ici si fleche en haut au clavier 
* : decalage a droite de la fenetre
*
fh        jsr eor4
          ldx haut
big4      inx
          inx
          cpx bas
          beq finfh1
          lda hi,x 
          sta hgrptr+1
          lda lo,x
          sta hgrptr     ; init hgrptr
          dex 
          lda hi,x 
          sta ptr6+1
          lda lo,x
          sta ptr6       ; init ptr
          ldy gauche
          iny
boucl4    lda (hgrptr),y
          sta (ptr6),y
          iny
          cpy droite
          bne boucl4
          jmp big4
finfh1    dex
          lda hi,x       ; vide la ligne basse
          sta hgrptr+1
          lda lo,x
          sta hgrptr     ; init hgrptr
          lda #$00  
          ldy gauche
          iny
enc       sta (hgrptr),y
          iny 
          cpy droite
          bne enc
          jsr eor4
          jmp main
*
*
* on arrive ici si fleche en bas au clavier 
* : decalage a droite de la fenetre
*
fb        jsr eor4
          ldx bas 
          dex
big5      lda hi,x 
          sta ptr6+1
          lda lo,x
          sta ptr6       ; init ptr
          dex
          cpx haut
          beq finfb2
          lda hi,x 
          sta hgrptr+1
          lda lo,x
          sta hgrptr     ; init hgrptr
          ldy gauche
          iny
boucl5    lda (hgrptr),y
          sta (ptr6),y
          iny
          cpy droite
          bne boucl5
          jmp big5
finfb2    lda #$00  
          ldy gauche
          iny
enc2      sta (hgrptr),y
          iny 
          cpy droite
          bne enc2
          jsr eor4
          jmp main
*
* on arrive ici si barre d'espace au clavier 
* : affiche le cut stocke en $6000
*
*
esp       lda lig        ; teste p{sence de cut
          bne esp2
          jmp beep
esp2      jsr eor4
          lda #$02
          sta ptr6
          lda #$60
          sta ptr6+1
          ldx haut
          inx
deb       lda hi,x
          sta hgrptr+1
          lda lo,x
          sta hgrptr
          lda gauche
          sec
          adc hgrptr
          bcc noinc
          inc hgrptr+1
noinc     sta hgrptr
          ldy #$00
lop       lda (ptr6),y 
          sta (hgrptr),y
          iny
          tya
          sta tempo
          clc
          adc gauche
          cmp #$27
          beq nextlign
          cpy col
          bne lop
nextlign  lda ptr6 
          clc
          adc col
          bcc noinc2
          inc ptr6+1
noinc2    sta ptr6 
          inx
          cpx #$c0
          beq finesp
          txa
          sec
          sbc haut
          cmp lig
          beq deb
          bcc deb
finesp    jsr eor4
          jmp main
*
* lettre v au clavier
*
v         jsr eor4
          ldx #00
clear     lda hi,x
          sta hgrptr+1
          lda lo,x
          sta hgrptr
          ldy #$00  
          lda #$00
litloop   sta (hgrptr),y
          iny 
          cpy #$28
          bne litloop
          inx
          cpx #$c0
          bne clear
          jsr eor4
          jmp main
*
*  cree la forme "blanche" pour l'animation
*  tous les bit @ 0 passent @ 1 si bit suivant = 1
*
savews    ds 1
octet     ds 1 
compt     ds 1
b2        jsr eor4       ;enleve les 4 barres
          ldx haut
newlign2  inx            ;
          cpx bas        ;toutes les lignes scann{es ?
          beq outws      ; oui
          lda hi,x
          sta hgrptr+1
          lda lo,x       ; adresse de base
          sta hgrptr
          ldy gauche     ; offset horizontal
newocte2  iny 
          cpy droite     ; dernier octet de la ligne?
          beq newlign2   ; oui : ligne suivante
          lda (hgrptr),y ; ramasse l'octet
newoct22  sta savews     ; non:  on le sauve
          lda #00        ;compteur de bits a 0
          sta compt
loopws2   ror octet      ; boucle. octet contiendra 
          inc compt      ; l'octet transform{
          lda compt
          cmp #08        ; 7 passes ?
          bne encorws2   ; non on continue
          lda (hgrptr),y ; oui: il faut poker le 8me bit 
          rol            ; : le bit de couleur
          lda octet
          ror            ; en position 7
          sta (hgrptr),y ; octet transform{ sur {cran
          bra newocte2   ;octet suivant
encorws2  lsr savews     ; bit suivant
          bcc suitws2    ; nul ?
          bra loopws2    ; non : tout va bien
suitws2   lda compt      ; non : dernier bit de l'octet?
          cmp #07
          beq suit1ws2   ; oui
          lda savews     ; non : on regarde le bit suivant
          lsr
          bra loopws2    ; on fait entr{ c dans octet 
suit1ws2  iny            ; il faut regarder l'octet suivant
          cpy droite     ; dernier de la ligne ?
          bne suit2ws2   ; non
          dey            ; oui: on suppose que le bit
          clc            ; suivant (hors du cut) est nul
          bra loopws2
suit2ws2  lda (hgrptr),y ; on examine l'octet suivant
          dey            ; remet y en place
          lsr            ; r{cupere le bit suivant
          bra loopws2
*
*
*  cree la forme "blanche" pour l'animation
*  tous les bit @ 0 passent @ 1 si bit suivant = 1
*  et si bit pr{cedent = 1
*
outws     jsr eor4
          jmp main
flag      ds 1
b         jsr eor4       ;enleve les 4 barres
          ldx haut
newligne  inx            ;
          cpx bas        ;toutes les lignes scann{es ?
          beq outws      ; oui
          lda #00        ; on suppose que les bits
          sta flag       ; @ gauche du cut sont vides 
          lda hi,x
          sta hgrptr+1
          lda lo,x       ; adresse de base
          sta hgrptr
          ldy gauche     ; offset horizontal
newoctet  iny 
          cpy droite     ; dernier octet de la ligne?
          beq newligne   ; oui : ligne suivante
          lda (hgrptr),y ; ramasse l'octet
          bne newoct2    ; =0 ?
          lda #00        ; oui:
          sta flag       ; on passe au suivant
          bra newoctet
newoct2   sta savews     ; non:  on le sauve
          lda #00        ;compteur de bits a 0
          sta compt
loopws    ror octet      ; boucle. octet contiendra 
          inc compt      ; l'octet transform{
          lda compt
          cmp #08        ; 7 passes ?
          bne encorws    ; non on continue
          lda (hgrptr),y ; oui: il faut poker le 8me bit 
          rol            ; : le bit de couleur
          lda octet
          ror            ; en position 7
          sta (hgrptr),y ; octet transform{ sur {cran
          bra newoctet   ;octet suivant
encorws   lsr savews     ; bit suivant
          bcc suitws     ; nul ?
          lda #01
          sta flag
          bra loopws     ; non : tout va bien
suitws    lda flag       ; oui : ca se complique !
          clc            ; bit pr{c{dent =0
          beq loopws     ;  oui : alors ok
          lda #00
          sta flag       ; on remet flag a 0
          lda compt      ; non : dernier bit de l'octet?
          cmp #07
          beq suit1ws    ; oui
          lda savews     ; non : on regarde le bit suivant
          lsr
          bcc loopws     ; =0 : ca va
          bra loopws     ; on fait entre 1 dans octet 
suit1ws   iny            ; il faut regarder l'octet suivant
          cpy droite     ; dernier de la ligne ?
          bne suit2ws    ; non
          dey            ; oui: on suppose que le bit
          clc            ; suivant (hors du cut) est nul
          bra loopws
suit2ws   lda (hgrptr),y ; on examine l'octet suivant
          dey            ; remet y en place
          lsr            ; r{cupere le bit suivant
          bcc loopws     ; il est vide
          bra loopws
*
*
*
*
hi        hex 2024282c3034383c
          hex 2024282c3034383c
          hex 2125292d3135393d
          hex 2125292d3135393d
          hex 22262a2e32363a3e
          hex 22262a2e32363a3e
          hex 23272b2f33373b3f
          hex 23272b2f33373b3f
          hex 2024282c3034383c
          hex 2024282c3034383c
          hex 2125292d3135393d
          hex 2125292d3135393d
          hex 22262a2e32363a3e
          hex 22262a2e32363a3e
          hex 23272b2f33373b3f
          hex 23272b2f33373b3f
          hex 2024282c3034383c
          hex 2024282c3034383c
          hex 2125292d3135393d
          hex 2125292d3135393d
          hex 22262a2e32363a3e
          hex 22262a2e32363a3e
          hex 23272b2f33373b3f
          hex 23272b2f33373b3f
lo        hex 0000000000000000
          hex 8080808080808080
          hex 0000000000000000
          hex 8080808080808080
          hex 0000000000000000
          hex 8080808080808080
          hex 0000000000000000
          hex 8080808080808080
          hex 2828282828282828
          hex a8a8a8a8a8a8a8a8
          hex 2828282828282828
          hex a8a8a8a8a8a8a8a8
          hex 2828282828282828
          hex a8a8a8a8a8a8a8a8
          hex 2828282828282828
          hex a8a8a8a8a8a8a8a8
          hex 5050505050505050
          hex d0d0d0d0d0d0d0d0
          hex 5050505050505050
          hex d0d0d0d0d0d0d0d0
          hex 5050505050505050
          hex d0d0d0d0d0d0d0d0
          hex 5050505050505050
          hex d0d0d0d0d0d0d0d0
*

