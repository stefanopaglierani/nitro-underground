# Come disegnare (o cambiare) un circuito

Ogni circuito è un piccolo file di testo in questa cartella:

| File | Circuito |
|---|---|
| `montagna.txt` | Passo alpino |
| `costa.txt` | Riviera |
| `citta_notte.txt` | Downtown (città di notte) |
| `deserto.txt` | Route 66 |

Si apre con un qualsiasi editor di testo (Blocco note va benissimo) e si legge come un
navigatore: **un pezzo di strada per riga**, dalla partenza fino a tornare al via. Il gioco
legge il file, costruisce la strada, i guardrail, il terreno e la traiettoria degli avversari.

## I comandi

| Scrivi | Cosa fa | Esempio |
|---|---|---|
| `DRITTO 300` | rettilineo di 300 metri | `DRITTO 450` |
| `DESTRA 90` | curva a destra di 90° (raggio 60 m) | `DESTRA 45 120` = curva larga e veloce |
| `SINISTRA 60 30` | curva a sinistra di 60° con raggio 30 m (stretta) | |
| `TORNANTE DESTRA` | tornante (giro di 180°), raggio 16 m | `TORNANTE SINISTRA 22` |
| `GOMITO SINISTRA` | curva a gomito (90° secchi), raggio 14 m | `GOMITO DESTRA 18` |
| `CHICANE DESTRA` | chicane: destra-sinistra-destra veloce | `CHICANE SINISTRA 45` = più cattiva |
| `ESSE DESTRA 40` | esse: 40° a destra e subito 40° a sinistra | `ESSE SINISTRA 30 90` |
| `SALITA 8` | da qui la strada sale dell'8% | |
| `DISCESA 6` | da qui la strada scende del 6% | |
| `PIANO` | da qui la strada torna in piano | |
| `PARTENZA` | qui c'è la linea del via | |

- Il **raggio** (il numero dopo i gradi) decide quanto è stretta la curva: piccolo = lenta
  (15-30 m), grande = veloce (80-150 m). Se non lo scrivi, vale 60.
- Tutto quello che viene dopo `#` è un commento: il gioco lo ignora.
- Maiuscole o minuscole non importa.

## Le due regole d'oro

1. **Le curve devono fare un giro completo.** Conta le curve a destra come + e a sinistra
   come -: alla fine devi arrivare a +360 (circuito in senso orario) o -360. Un tornante vale
   180, un gomito 90, chicane ed esse valgono 0. Se sbagli di poco, il gioco aggiusta da solo
   le curve e allunga o accorcia un po' i rettilinei per chiudere il giro.
2. **La strada non deve passare sopra sé stessa.** Tieni i tratti paralleli ad almeno 30-40 m
   di distanza, altrimenti i guardrail si toccano.

## Per controllare la mappa

Chiedimi semplicemente "controlla la mappa del deserto" (o mandami il file cambiato): lancio
`tools/map_preview.gd`, che disegna il circuito visto dall'alto e dice quanto è lungo, la
distanza minima fra due tratti e se c'è qualcosa che non va. Poi faccio un APK nuovo.

Se vuoi provarlo da solo sul PC con Godot:

    godot --headless --script tools/map_preview.gd -- cartella_dove_salvare_le_immagini

## Esempio: un circuito corto (1,7 km)

Copia queste righe in un file nuovo, ad esempio `tracks/prova.txt`:

    PARTENZA
    DRITTO 400          # rettilineo del via
    GOMITO DESTRA       # +90  staccata!
    DRITTO 250
    CHICANE SINISTRA    # 0
    DRITTO 100
    DESTRA 90 50        # +90
    SALITA 6
    DRITTO 120
    TORNANTE SINISTRA 22  # -180
    PIANO
    DRITTO 120
    TORNANTE DESTRA 22    # +180
    DRITTO 200
    DESTRA 90 40        # +90
    DRITTO 150
    DESTRA 90 60        # +90

Totale curve: +90 +90 -180 +180 +90 +90 = 360. I due tornanti hanno raggio 22 perché con
il raggio normale (16) le due corsie del tornante sarebbero a soli 32 m e i guardrail si
toccherebbero: è proprio il tipo di errore che il controllo della mappa segnala.
