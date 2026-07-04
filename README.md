# VLAK Level Editor
Level Editor pro VLAK 2.00 od Miroslava Němečka z roku 1995.

<img width="1727" height="989" alt="BRB" src="https://github.com/user-attachments/assets/de198702-fc98-4b56-9989-27848b86d70c" />

<p align="center">Verze 0.81 pro Public Release</p>

-----

Tento repozitář obsahuje všechno, co se týče editace scén (levelů) ve hře VLAK od Miroslava Němečka (c) pro verzi 2.00 vydanou v roce 1995.

## Návod k použití:
Stáhněte celý repozitář z Releases (https://github.com/brb-pls/VLAK-Level-Editor/tags). Je silně doporučeno vždy stáhnout ten release, který je nejnovější, tj. ten nahoře.

Zip soubor obsahuje source soubory VLAKu verze 2.00 a .exe soubor `leved081.exe`. Po extrahování složky můžete bezpečně otevřít tento .exe soubor a vrhnout se do vytváření svých levelů!

(ano, vím, že dokumentaci bych měl psát jako pro debily, ale hodně věcí přeskočím, protože jsou 2:30 ráno a já chci spát)

Takže trochu jazzuo styl:
Prostě tam naklikáš co chceš v levelu mít. V každým levelu musí být **Lokomotiva** a **Vrata**, bez nich editor nedovolí export ani makro.

Makro slouží k tomu, aby se dalo rychle otestovat, jestli se tvůj vytvořený level dá dohrát. A taky k tomu, že pokud zapneš VLAK a nebudeš nic dělat, tak začne náhodně přehrávat různé levely. To makro slouží právě k tomu, aby Lokomotiva věděla, kam má jet. Takže prostě všechno sesbírej a dojeď na blok s Vratama, tam makro vypni. Makro se dá ovládat šipkama nebo myší. (příští update bych to mohl zautomatizovat, čili by se makro automaticky uložilo, ale teď jsem moc línej...)

Když jsi se vším spokojený, vlevo nahoře máš dvě důležitý kolonky na vyplnění. Heslo levelu a číslo levelu. Heslo musí mít přesně 5 znaků a číslo musí být celé číslo od 1 do 50. Pak dáš "Export do schránky".

Teď ta nejsložitější část:
Ve složkách hry najdeš v `.\SOURCE\` adresáři soubor `VLAK_WIN1250.SCN`. Ten otevřeš pomocí jakéhokoliv textového editoru. Pokud se rozbila diakritika, nic si z toho nedělej, tady tě to nemusí zajímat. Sjedeš malinko dolů a uvidíš tohle:

```
; 1:
GOLEM
! RRRRRRRRRRRRRRUUULLLLLLLLLLLDDDDDDRRRRRRRDRRRRRRRR
####################
#..................#
#...AAAAAAAAAAAA...#
#..................#
#..................#
#$....AAAAAAAA.....#
#..................#
#..................#
#.......AAAA.......#
#..................@
#..................#
####################
```

(Poznámka: Pokud chceš importovat level zpátky do editoru, tak už vybíráš POUZE hrací plochu. Zkopíruješ si ji pomocí <kbd>Ctrl</kbd> + <kbd>C</kbd> a v editoru klikneš na Import ze schránky.
Heslo, číslo a makro budeš muset udělat znova!)

Tohle je první level ve hře. To je ta 1: nahoře. Má heslo GOLEM a její makro je tam tady. Hned pod tím vším bordelem je level jako takový, definovaný znakama, který máš zkopírovaný po exportu ve schránce. Celý to vezmeš a prostě to vyměníš.

Když máš všechny levely v pořadí vyměněné tak, jak chceš, přesuneš soubor `VLAK_WIN1250.SCN` o jeden adresář nahoru, tj. mimo složku `.\SOURCE\` do `.\`, a uděláš dvě poslední věci:
Najdeš soubor `VLAK$.SCN` a přejmenuješ jej na např. `VLAK$_ZALOHA.SCN`, a přesunutý soubor `VLAK_WIN1250.SCN` přejmenuješ na `VLAK$.SCN`. A to je vše!

Pak už můžeš klasicky spustit VLAK přes DOSBox.
Menší tutoriál na to, jak to udělat, pro ty méně technicky zdatné:
Stačí stáhnout DOSBox (https://www.dosbox.com/download.php?main=1) pro operační systém, na kterém zrovna jste. Před jeho zapnutím uděláme pár změn, aby se nám ulehčila práce s adresáři; celou složku se vším všudy přesuneme do `C:\`, čili náš adresář bude `C:\Vlak\` ... DOSBox totiž nemá rád, když máte v adresářích mezeru, a to je celkem problém, pokud máte třeba Windows nastavený tak jako já (čili s mezerou pro uživatelské jméno). Tímto se tomu vyvarujeme. Následně zapneme DOSBox, a do něj napíšeme pár příkazů:
* `mount c C:\Vlak` - tento příkaz DOSBoxu řekne, že tohle bude náš výchozí adresář, ve kterém ho budeme chtít, aby pracoval.
* `c:` - tohle přepne přímo na ten adresář, o kterém jsme mu řekli.
* `vlak.bat` - spustí spouštěcí soubor pro VLAK, a v okně DOSBoxu se VLAK zapne.

A to je vše, užívejte!

brb.
