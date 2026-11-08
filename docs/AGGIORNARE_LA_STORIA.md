# Aggiornare la storia a fine sessione

Il repository è pubblico ed è il portfolio di Stefano: chi entra deve vedere a che punto è il gioco
e come ci si è arrivati. Per questo **ogni sessione di lavoro che cambia il gioco si chiude
aggiornando la documentazione**, nella stessa pull request del lavoro (o in una piccola PR a parte).

## Checklist di fine sessione

1. **[docs/STORIA.md](STORIA.md)**
   - Aggiungi una riga alla tabella "In sintesi" (versione, data, una riga, link alla PR).
   - Aggiungi una sezione in fondo, prima di "Prossimi passi", con questo schema:

     ```markdown
     ## v0.X — Titolo breve (gg mese)

     ![descrizione](immagini/v0.X-qualcosa.jpg)

     **Richiesta:** cosa ha chiesto Stefano, con le sue parole quando sono efficaci.

     **Come è stato costruito:** le soluzioni tecniche, comprensibili anche a chi non
     programma, con i file dove stanno (`scripts/...`). Numeri solo se davvero misurati.

     **Verifica ed esito:** come è stato controllato (banco prova, autotest, screenshot) e,
     se ha già provato la versione, cosa ne ha pensato Stefano.
     ```
   - Se Stefano ha provato una versione precedente, aggiungi il suo giudizio a quella voce.
   - Aggiorna "Prossimi passi".
2. **[README.md](../README.md)**
   - Badge della versione in alto, e la versione nella sezione English.
   - "In 30 secondi" (numero di versioni e giorni), "Cosa c'è nel gioco", "Come è costruito,
     in breve", "Come è cambiato" e "Struttura del repository" se sono cambiati.
   - Gli screenshot se il gioco ora ha un aspetto diverso.
3. **[docs/TECNICO.md](TECNICO.md)**: se cambia come funziona qualcosa (fisica, circuiti,
   grafica, audio, prestazioni), aggiorna la sezione giusta. Se cambia la fisica, rilancia il banco
   prova a 30, 60 e 120 tick e aggiorna le due tabelle.
4. **[CREDITI.md](../CREDITI.md) e `assets/LICENSES.md`**: ogni nuovo asset registrato; se è NC o
   di un marchio reale, aggiunto all'elenco "Cosa non si potrebbe usare".
5. **Screenshot**: in `docs/immagini/`, JPG di 1280×720 al massimo, qualità circa 80
   (meno di 400 KB l'uno). Le immagini senza versione nel nome (`gara-*.jpg`, `menu-*.jpg`,
   `panorama-*.jpg`) mostrano **sempre la versione attuale**: rifalle quando il gioco cambia aspetto,
   e conserva quelle vecchie con la versione nel nome (es. `v0.11-gara-costa.jpg`) per la storia.

## Come rifare gli screenshot

Dalla cartella del progetto, dopo `godot --headless --import` (serve `xvfb-run`):

```bash
G="xvfb-run -a -s '-screen 0 1280x720x24' godot --rendering-driver opengl3 --resolution 1280x720"
# Garage iniziale (--reset-garage = come al primo avvio, prima di scegliere l'auto)
$G -- --reset-garage --menushot=out/garage.png
# Pagina START e dealer (--panel=color o --panel=tune apre un pannello, --dealercar=<id> sceglie l'auto)
$G -- --titleshot=out/start.png
$G res://scenes/dealer.tscn -- --dealershot=out/dealer.png --panel=tune
# Gara: con --shots salva anche una foto della pagina di caricamento a ogni fase
# Gara: 6 immagini durante una gara guidata dal pilota automatico
$G res://scenes/main.tscn -- --autotest --level=desert --car=charger_1970 --shots=out/
# Panorami di un circuito (frazioni del giro; "s" = vista panoramica, "h" = dall'alto)
$G --script tools/shot.gd -- desert out/ 0.15s 0.45s 0.3h
# Mappe dei circuiti
godot --headless --script tools/map_preview.gd -- out/
```

Il rendering in un container senza GPU è lento: circa 20 minuti per gara.

## Regole di scrittura

- In italiano, frasi semplici, comprensibili da chi non programma. La sezione English del README
  segue gli stessi contenuti in breve.
- Racconta la storia vera: cosa ha chiesto Stefano, cosa è stato fatto, cosa è andato storto.
  Non dichiarare provato sul telefono quello che non è stato provato.
- Le decisioni di gioco, stile e auto sono di Stefano: scrivilo così.
- Niente nomi di sessioni, thread o percorsi interni del progetto; solo link pubblici
  (PR, file del repository).
- Non aggiungere APK, zip o modelli non usati al repository.

## Dove trovare le informazioni

- Le pull request della sessione (titolo e descrizione).
- `git log` del ramo di lavoro.
- La memoria del progetto, dove ogni sessione annota cosa ha chiesto Stefano e cosa è stato fatto.
