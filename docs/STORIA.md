# Storia dello sviluppo

Il diario di bordo di Nitro Underground, dalla prima idea alla v0.12, in 7 giorni e 13 versioni.

Ogni versione segue lo stesso ciclo: **Stefano prova la build** sul telefono Android o sul PC,
scrive cosa non va e cosa vuole, **Claude la costruisce** e la verifica con le prove automatiche,
poi la consegna come APK e come pull request. Per ogni voce trovi:

- **Richiesta**: cosa ha chiesto Stefano, spesso con le sue parole.
- **Come è stato costruito**: le soluzioni tecniche, con i file dove stanno.
- **Verifica ed esito**: come è stato controllato e cosa ne ha pensato Stefano alla prova.

Per l'architettura completa vedi [TECNICO.md](TECNICO.md). Le voci più recenti sono in fondo.

> Per aggiungere una voce a fine sessione: [AGGIORNARE_LA_STORIA.md](AGGIORNARE_LA_STORIA.md).

![Evoluzione del gioco dalla v0.1 alla v0.11.1](immagini/evoluzione.jpg)

## In sintesi

| Versione | Data | In una riga | PR |
|---|---|---|---|
| Concept | 27/10/2026 | L'idea, il piano in 4 passi, la scelta di Godot | — |
| v0.1 | 27/10/2026 | Primo prototipo: città notturna low poly, visuale dall'alto | — |
| v0.2 | 28/10/2026 | Fisica nuova: corpo rigido su quattro ruote, Vulkan, banco prova | [#1](https://github.com/stefanopaglierani/nitro-underground/pull/1), [#2](https://github.com/stefanopaglierani/nitro-underground/pull/2) |
| v0.3 | 29/10/2026 | Telecamera dietro l'auto, rampe, salti e atterraggi | [#3](https://github.com/stefanopaglierani/nitro-underground/pull/3), [#4](https://github.com/stefanopaglierani/nitro-underground/pull/4) |
| v0.4 | 29/10/2026 | Dalla città buia alla strada di montagna di giorno | [#5](https://github.com/stefanopaglierani/nitro-underground/pull/5), [#6](https://github.com/stefanopaglierani/nitro-underground/pull/6), [#7](https://github.com/stefanopaglierani/nitro-underground/pull/7) |
| v0.5 | 29/10/2026 | Garage nel menu, prime auto realistiche | [#8](https://github.com/stefanopaglierani/nitro-underground/pull/8) |
| v0.6 | 30/10/2026 | Guida dalle ruote, trazioni diverse, cruscotto, guardrail che si rompono | [#9](https://github.com/stefanopaglierani/nitro-underground/pull/9) |
| v0.7 | 30/10/2026 | Audio del motore, traffico urtabile, comandi a esagoni, stile fumetto | [#10](https://github.com/stefanopaglierani/nitro-underground/pull/10), [#11](https://github.com/stefanopaglierani/nitro-underground/pull/11), [#12](https://github.com/stefanopaglierani/nitro-underground/pull/12) |
| v0.8 | 30/10/2026 | Marce lunghe e 210+ km/h, garage da 20, tre circuiti | [#13](https://github.com/stefanopaglierani/nitro-underground/pull/13), [#14](https://github.com/stefanopaglierani/nitro-underground/pull/14) |
| v0.9 | 31/10/2026 | Il fumetto 2.5D diventa l'unico stile, paesaggio realistico | [#10](https://github.com/stefanopaglierani/nitro-underground/pull/10) |
| v0.10 | 31/10/2026 | Menu Route 66, caricamento leggero, tempo a scalare | [#16](https://github.com/stefanopaglierani/nitro-underground/pull/16) |
| v0.11 | 31/10/2026 | Circuiti scritti come mappe di testo, ambientazioni rifatte, Deserto | [#17](https://github.com/stefanopaglierani/nitro-underground/pull/17) |
| v0.11.1 | 31/10/2026 | Sterzo più dolce, niente ribaltamenti in aria, garage da 7 | [#17](https://github.com/stefanopaglierani/nitro-underground/pull/17) |
| v0.12 | 02/11/2026 | Stabilizzazione: pausa, polizia più giusta, rivali e traffico più furbi | [#19](https://github.com/stefanopaglierani/nitro-underground/pull/19) |

## Le svolte principali

Il gioco di oggi è molto diverso dall'idea del primo giorno. Le svolte sono nate tutte dalle prove
di Stefano sul telefono:

1. **Dalla visuale dall'alto alla telecamera di inseguimento** (v0.3): dall'alto "non rende" e
   non dà il senso della velocità.
2. **Dalla città di notte buia alla montagna di giorno** (v0.4), e poi ritorno a una città di
   notte, ma **luminosa** (v0.8) e ricostruita con palazzi veri (v0.11).
3. **Dal low poly al fumetto 2.5D** (v0.7-v0.9): provati tre stili affiancati nello stesso gioco,
   scelto quello a fumetto come unico.
4. **Da circuiti generati con formule a circuiti scritti come mappe** (v0.11): ora i circuiti li
   può disegnare chiunque, anche senza programmare.
5. **Da 54 auto a 7** (v0.5 → v0.11.1): meno auto, ma dettagliate e scelte una per una.

---

## Concept (27 ottobre 2026)

**Richiesta:** un gioco di corse per telefono da pubblicare un giorno su App Store e Google Play.
Arcade, 3D, nello spirito delle gare clandestine su strada: tuning, corse illegali, inseguimenti
della polizia. I grandi titoli del genere sono solo un riferimento: nome, auto e mondo del gioco
devono essere originali.

**Scelte fatte:**
- **Godot 4** invece di Unity: gratuito, leggero sul telefono, e scene e script sono file di
  testo, quindi tutto si può costruire e rivedere senza aprire l'editor.
- **Tutto il codice lo scrive Claude**, Stefano decide e prova. Budget zero: solo asset gratuiti.
- **Piano in 4 passi**, approvato: 1) documento di concept, 2) prototipo da provare sul
  telefono ("guidare è divertente?"), 3) vertical slice, 4) produzione e pubblicazione.

## v0.1 — Il primo prototipo (27 ottobre)

![v0.1](immagini/v0.1-gara.jpg)

**Richiesta:** una prima versione da installare sul telefono, per capire se guidare è divertente.

**Come è stato costruito:**
- Città di 6×6 isolati **generata dal codice** (`city.gd`): strade, palazzi con uno shader che
  accende finestre a caso sulle facciate (`building.gdshader`), neon, lampioni.
- Auto arcade su `CharacterBody3D` (movimento calcolato dal codice, senza fisica dei corpi rigidi), con accelerazione
  automatica, derapata col freno a mano e nitro che si ricarica derapando.
- Avversari e polizia che seguono percorsi lungo le strade; traffico civile.
- Due modalità: **gara sprint** (7 checkpoint, 3 avversari) e **fuga dalla polizia** (stare a più
  di 110 m da tutte le volanti per 10 secondi), con livello di allerta che sale con gli incidenti.
- Una prova automatica (`--autotest`) fa guidare l'auto da sola per tutta la gara: è stata la
  base di tutti i controlli successivi.
- Script di build Android (`tools/build_android.sh`), eseguito in un container cloud senza Android SDK
  ufficiale, con un firmatario APK fatto apposta.

**Esito:** Stefano installa l'APK sul telefono e funziona. Primo traguardo raggiunto.

## v0.2 — Fisica vera (28 ottobre)

**Richiesta:** un salto di qualità: asset più realistici e una fisica arcade credibile, con salti,
atterraggi, urti e acrobazie. Prima viene fatta una revisione completa del progetto; Stefano
approva le scelte e l'ordine dei lavori.

**Come è stato costruito:**
- L'auto diventa un **`RigidBody3D`** con fisica **Jolt**: quattro ruote simulate con
  sospensioni a molla-smorzatore e aderenza per ruota limitata dal carico (`car.gd`).
- Passaggio al **renderer Mobile (Vulkan)**.
- **Banco prova della fisica** (`tests/physics_bench.gd`): misura accelerazione, frenata, curve,
  derapata, urto contro un muro e stampa i risultati in JSON, a 30, 60 e 120 tick al secondo
  per controllare che la fisica non dipenda dal frame rate.
- Primi asset **CC0 da Poly Haven**: cieli HDRI, asfalto, cemento, mattoni, lampioni, con un
  registro delle licenze (`assets/LICENSES.md`) avviato da subito.

**Esito:** la fisica gli piace molto, gli scontri con le altre auto sono "spettacolari", la
derapata funziona. Ma la velocità non si sente, la frenata quasi non si nota e soprattutto
**la visuale dall'alto non rende**.

## v0.3 — Telecamera di inseguimento e salti (29 ottobre)

![v0.3](immagini/v0.3-telecamera.jpg)

**Richiesta:** visuale dall'alto abbandonata per sempre. Telecamera dietro l'auto, vicina e un po'
alta, per vedere l'auto e la strada lontano.

**Come è stato costruito:**
- **Telecamera di inseguimento** a distanza costante, che guarda un punto davanti all'auto;
  il campo visivo si allarga un poco col nitro.
- Auto 3D **KayKit (CC0)** con vernice riverniciabile da shader (`car_paint.gdshader`) e luci.
- **Rampe curve** (`ramp.gd`) con raccordo all'inizio, segnali di decollo e atterraggio,
  conteggio delle rotazioni in aria e atterraggi più morbidi.
- Il banco prova confronta la lunghezza dei salti con la **traiettoria balistica teorica**
  (`d = v² sin 2θ / g`): oggi lo scarto è di circa il 2%.

## v0.4 — Dalla città di notte alla montagna di giorno (29 ottobre)

![v0.4](immagini/v0.4-montagna.jpg)

**Richiesta:** la città notturna è troppo buia e le luci non convincono. Una **strada di montagna
di giorno**, con luce piena, colori vivi e un aspetto più realistico.

**Come è stato costruito:**
- Una classe base **`Track`** separa il circuito dal resto del gioco: regole di gara, IA e
  traffico usano solo la sua interfaccia, così i livelli diventano intercambiabili.
- **`Mountain`** (`mountain.gd`): anello chiuso di 2,7 km generato da semi fissi (uguale a ogni
  partita), pendenze fino al 12%, carreggiata a due corsie, **terreno a blocchi** raccordato alla
  strada con uno shader che miscela erba e roccia, pareti di roccia dove la strada taglia il pendio,
  guardrail su entrambi i lati, cielo e rocce di Poly Haven.
- **Velocità consigliata in curva** calcolata dal raggio della strada: gli avversari la usano
  per frenare prima delle curve.
- Una **libreria di modelli CC0** da OpenGameArt (Kenney, rgsdev, Quaternius, Yughues e altri),
  tenuta fuori dall'APK con un file `.gdignore`.
- Auto rgsdev, pini e betulle Quaternius, ciuffi d'erba Yughues. Gli avversari scansano il traffico.

## v0.5 — Il garage (29 ottobre)

![v0.5](immagini/v0.5-garage.jpg)

**Richiesta:** scegliere l'auto prima della gara, e auto **realistiche**, anche di marchi veri.
Stefano stesso trova e scarica da Sketchfab una McLaren 600LT, un Ford F-150 Raptor R e un RAM TRX.

**Come è stato costruito:**
- **`CarCatalog`**: un catalogo di 54 veicoli con nome, modello e proprietà, e un menu iniziale
  con garage a scorrimento.
- **`CarModel.build_generic`**: carica qualsiasi modello glTF, ne trova da solo davanti e dietro
  (dai nomi di mesh e materiali), lo scala alla lunghezza reale, lo appoggia a terra e collega le
  ruote anteriori allo sterzo quando sono oggetti separati.

**Decisione sulle licenze:** i modelli di marchi reali e con licenza non commerciale vanno bene
finché il gioco è un prototipo e un portfolio; prima di una pubblicazione verranno sostituiti.
Sono tutti dichiarati in [CREDITI.md](../CREDITI.md).

## v0.6 — La struttura della guida (30 ottobre)

![v0.6](immagini/v0.6-cruscotto.jpg)

**Richiesta**, in 11 punti dopo la prova della v0.4: barra di caricamento (per capire se il gioco
lavora o è bloccato), niente sterzo in aria, spinta e sterzo dalle ruote con trazione anteriore,
posteriore e integrale diverse, telecamera a distanza sempre costante, cruscotto digitale,
**acceleratore manuale**, mondo chiuso, oggetti distruttibili, sospensioni che salgono sui
gradini, linea di traiettoria a terra e avversari più intelligenti.

**Come è stato costruito:** tutti e 11 i punti.
- **Ruote come cilindri proiettati** (shape cast) invece di raggi: salgono su un cordolo da
  15 cm anche a 90 km/h invece di sbatterci.
- **Spinta solo dalle ruote motrici** e ruote anteriori che sterzano davvero; trazione per auto in
  `CarCatalog` (`front_drive` da 0 a 1). Angolo di sterzo che si stringe con la velocità.
- **Cambio automatico a 6 marce** con giri motore; **cruscotto digitale** (`dashboard.gd`) con
  contagiri, velocità, marcia e nitro.
- **Guardrail distruttibili** (`guardrails.gd`): tratti da 4 m disegnati con MultiMesh e raggruppati
  in pochi corpi fisici; un urto oltre una soglia stacca il tratto e il palo, che volano via come
  pezzi liberi. I cartelli delle curve sono corpi appoggiati che un'auto fa volare.
- **Traiettoria ideale** tracciata sull'asfalto a trattini verdi (accelera), gialli (molla) e rossi
  (frena), calcolata con il metodo descritto in [TECNICO.md](TECNICO.md#5-circuiti-scritti-come-mappe-di-testo).
- **Mondo chiuso**: chi resta oltre il guardrail per 3 secondi torna in strada.

## v0.7 — Suoni, scontri e un nuovo stile (30 ottobre)

![v0.7](immagini/v0.7-scontri.jpg)

**Richiesta:**
- Suoni che seguono l'auto: giri del motore, cambiate, freni, scontri.
- Il traffico restava fermo quando lo colpivi: **scontri veri** e più traffico.
- Nitro a sinistra, pulsanti più piccoli, a esagono, con icone.
- Gli piace lo stile anime/cartoon e vuole provare un look **2.5D a fumetto**.

**Come è stato costruito:**
- **Audio** (`car_audio.gd`): motore V8 **sintetizzato da zero** in Python
  (`tools/audio/make_engine_sounds.py`), 6 anelli a gas aperto e 6 a gas chiuso, miscelati e
  intonati ai giri a ogni fotogramma. Cambiate con soffio del turbo, scoppiettii, gomme, nitro,
  vento, urti di tre intensità, sirena; registrazioni CC0 da Freesound tagliate da script.
  Verificato registrando un video della partita.
- **Traffico come corpi rigidi** (`traffic.gd`): una spinta limitata li tiene in corsia, un urto più
  forte li sposta, uno molto forte li fa girare e sbandare. 24 auto. Livelli di collisione
  separati, perché in Jolt una collisione "a senso unico" trasforma l'auto colpita in un muro.
- **Comandi touch a esagoni** disegnati in SVG alla dimensione dello schermo.
- **Tre stili grafici affiancati** (realistico, anime, fumetto 2.5D) con un pulsante per cambiarli,
  così Stefano poteva confrontarli sul telefono.

## v0.8 — Velocità, garage e circuiti (30 ottobre)

![v0.8](immagini/v0.8-circuiti.jpg)

**Richiesta:** le marce sono troppo corte (le auto si fermano a 160 km/h): almeno 210 km/h,
marce più lunghe e distanziate, garage di **al massimo 20 auto**. Poi, dopo l'auto, scegliere il
circuito tra **Montagna, Costa e Città di notte**.

**Come è stato costruito:**
- **Velocità massima per auto** (210-255 km/h) in `CarCatalog`; rapporti allungati
  (`GEAR_TOPS`) con forza che cala nelle marce alte (`forza ~ rapporto^0,55`). Misurato in pianura:
  McLaren 249 km/h, da 0 a 200 in 9,1 secondi.
- **Garage da 20 auto** approvato da Stefano, comprese 4 che ha scaricato lui.
- **Costa** (`coast.gd`) e **Città di notte** (`night_city.gd`) come sottoclassi di `Mountain` che
  ridefiniscono solo forma, terreno, materiali e decorazioni. La città, stavolta, è **luminosa**:
  luce ambiente forte, finestre accese, pozze di luce sull'asfalto, neon e 8 luci vere che
  seguono la telecamera.

## v0.9 — Solo fumetto 2.5D (31 ottobre)

![v0.9](immagini/v0.9-fumetto.jpg)

**Richiesta:** dopo aver provato i tre stili, il **fumetto 2.5D è l'unico stile** del gioco. Per
l'ambiente, i modelli più realistici disponibili gratis, ma disegnati in 2.5D.

**Come è stato costruito:**
- **`ComicStyle`** (`comic_style.gd`): converte in luce toon ogni materiale che entra in scena,
  anche dopo (auto, detriti), aggiunge un contorno a inchiostro alle auto e una **passata a schermo
  intero** (`stylize.gdshader`) con bande di colore, linee d'inchiostro sui salti di profondità,
  retino, tratteggio e lastre di colore sfasate. Cielo pop-art e linee di velocità.
- **`Scenery`** (`scenery.gd`): alberi, chalet, cartelli, coni e barriere realistici da Sketchfab
  (CC BY), scalati all'altezza reale e piazzati lungo la strada; lavori in corso con coni.

## v0.10 — Menu Route 66 e caricamento leggero (31 ottobre)

![Menu Route 66](immagini/menu-circuiti.jpg)

**Richiesta:** sul telefono il gioco si bloccava al 69% del caricamento ("luci e ombre"). Non
caricare tutto all'avvio; un menu nuovo con lo sfondo **Route 66** in 2.5D, un pannello unico
(prima il circuito, poi l'auto, poi VIA!); tempo **a scalare** fino al prossimo checkpoint; niente
più fuga dalla polizia, resta la gara sprint.

**Come è stato costruito:**
- **Menu** come scena separata (`menu.gd`) con un'illustrazione **originale** della Route 66
  disegnata in SVG (`tools/art/route66.svg`) e trasformata in immagine con Chromium.
- **Caricamento a passi**: si costruisce solo il circuito scelto, i modelli delle auto vengono letti
  **in thread paralleli** mentre si costruisce il livello, il 3D è spento finché il livello non è
  pronto e la barra avanza a ogni passo.
- **Cause del blocco** trovate nel codice e corrette: un cielo che ricalcolava la mappa dei riflessi
  a ogni fotogramma e un panorama 2K inutilizzato che finiva nell'APK.
- **Tempo a scalare**: ogni checkpoint aggiunge il tempo per arrivare al successivo, il tempo avanzato
  si somma; "+N s" sotto il cronometro, che diventa giallo sotto 10 secondi e rosso lampeggiante sotto 5.

## v0.11 — Mappe dei circuiti e ambientazioni rifatte (31 ottobre)

![Le quattro ambientazioni](immagini/ambientazioni.jpg)

**Richiesta:** ambientazioni sensate e fatte bene (i palazzi della città di notte erano
"inguardabili"), una grande ricerca di modelli 3D, circuiti molto più vari (tornanti, gomiti,
chicane, rettilinei) **o un modo per disegnarli da sé**, e un'immagine su ogni pulsante dei circuiti.

**Come è stato costruito:**
- **Linguaggio delle mappe** (`track_layout.gd`): un pezzo di strada per riga, in italiano
  (`DRITTO 300`, `TORNANTE DESTRA`, `CHICANE SINISTRA`, `SALITA 4`...). L'anello si chiude da solo
  ritoccando curve e rettilinei. Guida per non programmatori in [tracks/COME_FARE.md](../tracks/COME_FARE.md).
- **Controllo delle mappe** (`tools/map_preview.gd`): disegna ogni circuito e misura la distanza
  minima tra due tratti di strada, per scoprire sovrapposizioni prima di giocare.
- **Città di notte ricostruita** con palazzi veri (Sketchfab, CC BY) e uno shader che accende le
  finestre; skyline di torri, semafori agli incroci, neon sulle vetrine.
- **Nuovo circuito Deserto** (`desert.gd`): Route 66 con lunghissimo rettilineo, canyon di roccia
  rossa, tornante e un paese con distributore, motel con insegna, banca e torre dell'acqua.
- **Ottimizzazione**: `Scenery` fonde i pezzi di ogni modello in una mesh con una superficie per
  materiale (un modello da 123 pezzi passava da oltre 1.000 chiamate di disegno a poche); texture
  compresse per la GPU a 512 px.
- **Libreria di 58 modelli** divisa per ambientazione, per i prossimi lavori; il tempo dei
  checkpoint ora viene dal tempo ideale sulla traiettoria (× 1,55 + 4 s).

![Mappe dei circuiti](immagini/mappe-circuiti.png)

## v0.11.1 — Guida più dolce (31 ottobre)

![Garage da 7 auto](immagini/menu-auto.jpg)

**Richiesta:** sterzo del giocatore più dolce del 30%, niente più muso che si impenna quando si
frena in aria, e un garage di 7 auto: McLaren 600LT, Porsche 911 GT3, Mustang 1969, Skyline R34,
Charger 1970, F-150 Raptor R e RAM TRX.

**Come è stato costruito:** un coefficiente di sterzo solo per il giocatore (`PLAYER_STEER = 0.7`,
gli avversari restano uguali); in aria i pedali non ruotano più l'auto, che si raddrizza da sola;
garage da 7. Le auto escluse restano nel repository ma i filtri di esportazione le lasciano fuori
dall'APK, che scende a circa 310 MB.

**Verifica:** banco prova della fisica a 60 tick: 0-100 km/h in 3,48 s, frenata da 144 km/h in
62,9 m, salti entro il 2-2,5% della traiettoria balistica, atterraggi con 2-3° di inclinazione.

## v0.12 — Stabilizzazione: pausa, polizia, rivali e traffico (2 novembre)

![Gara in pausa](immagini/v0.12-pausa.jpg)

**Richiesta:** il 2 novembre Stefano ha fissato una direttiva di sviluppo: prima di aggiungere
cose nuove, **rendere stabile il gioco che c'è**. Dopo un controllo completo della v0.11.1 (codice,
prove automatiche, gara su tutti i circuiti) ha scelto le correzioni: una pausa vera, una polizia
meno esagerata ("arriva a 20 secondi e prima si occupa delle auto in gara che incontra"), rivali
più veloci del 20% e più attenti agli incidenti, e un traffico che dopo un urto si ferma
3 secondi e poi si libera da solo.

**Come è stato costruito:**
- **Pausa** (`hud.gd`, `main.gd`): pannello "GARA IN PAUSA" con *Riprendi gara* e *Menù*. Si apre
  con il pulsante MENU, con il tasto Indietro di Android (che prima chiudeva il gioco di colpo) e
  da sola quando il telefono manda il gioco in secondo piano (una chiamata, il tasto Home). Tutto si
  ferma: cronometro, auto, fisica. Nel menu, Indietro torna dalle auto ai circuiti.
- **Posizione in gara**: la scritta POSIZIONE poteva bloccarsi per tutta la gara se il giocatore
  saltava un punto del percorso (per esempio passando da un guardrail rotto); ora guarda anche i
  punti successivi.
- **Polizia**: chiamata a 20 secondi invece di 14; ogni volante insegue la prima auto in gara che
  incontra e passa al giocatore solo quando lui le passa vicino (35 m); arresto solo se fermo sotto
  i 5 km/h accanto alla polizia per 5 secondi.
- **Rivali** (`car.gd`, `main.gd`): +20% di velocità massima e spinta, curve prese al 92% della
  velocità consigliata, traffico guardato più lontano; se restano incastrati 8 secondi vengono
  rimessi sul percorso.
- **Traffico** (`traffic.gd`): qualsiasi urto da un'auto in gara ferma l'auto civile per
  3 secondi (si può ancora spingere); poi riparte da sola: se ha un'auto attaccata davanti fa un
  po' di retromarcia, la aggira di lato piano e torna in corsia.
- **Telecamera** (`main.gd`): alzata e allontanata del 20% (con i pickup l'auto copriva la strada);
  solo muri e rocce la fanno avvicinare, non più le auto che seguono, e mai a meno di 4 m.

**Verifica:** banco prova della fisica a 30, 60 e 120 tick con gli stessi numeri della v0.11.1
(la guida non è cambiata). La gara automatica, che con la v0.11.1 finiva sempre con l'arresto,
ora arriva al traguardo su tutti e 4 i circuiti. Pausa, Indietro, secondo piano, urti col traffico
e posizione in gara sono stati provati con script di prova. Da provare sul telefono.

---

## Prossimi passi

- Prova sul telefono della v0.12: pausa (tasto Indietro, chiamata, Home), polizia, rivali, traffico.
- Passo 3 del piano: **vertical slice**, cioè un circuito e un'auto rifiniti al livello del gioco finale.
- Prima di qualsiasi pubblicazione: sostituire i modelli non commerciali e di marchi reali
  (vedi [CREDITI.md](../CREDITI.md)) e aggiungere i titoli di coda con i crediti CC BY.
