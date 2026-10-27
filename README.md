# Nitro Underground

Gioco mobile di corse clandestine in 3D con telecamera dall'alto, fatto con **Godot 4.7**.
Questa è la prima versione di prova (passo 2 del piano): serve a capire se guidare è divertente.
La grafica low poly è provvisoria; dal passo 3 si passa a una grafica realistica.

## Cosa c'è nel prototipo

- Città notturna di 6x6 isolati con palazzi illuminati, neon, lampioni e traffico.
- Auto arcade con accelerazione automatica, derapata col freno a mano e nitro che si ricarica col tempo e derapando.
- **Gara sprint**: 7 checkpoint contro 3 avversari. Dopo circa 14 secondi arriva la polizia.
- **Fuga dalla polizia**: parti con 3 volanti alle calcagna; per vincere devi stare a più di 110 m da tutte per 10 secondi.
- Livello di allerta (5 riquadri in alto a destra): sale con gli incidenti, più è alto e più volanti arrivano.
  Se una volante ti blocca quasi fermo per 3 secondi vieni arrestato.

## Comandi

| Touch | Tastiera | Azione |
| --- | --- | --- |
| Frecce a sinistra | ← → oppure A D | Sterzo |
| FRENO | ↓ oppure S | Freno e retromarcia |
| DERAPA | Spazio | Freno a mano |
| NITRO | Shift oppure N | Nitro |

## Struttura

- `scenes/main.tscn`: scena principale; tutto il resto è costruito da codice.
- `scripts/main.gd`: regole di gara, checkpoint, polizia, telecamera.
- `scripts/car.gd`: fisica arcade dell'auto e guida del computer (avversari e polizia).
- `scripts/city.gd`: generazione della città e percorsi lungo le strade.
- `scripts/traffic.gd`: auto civili.
- `scripts/hud.gd`: comandi touch, menu, schermate di fine gara.
- `shaders/building.gdshader`: facciate con finestre illuminate.

## Prove automatiche

`godot --headless -- --autotest --mode=sprint` fa guidare l'auto da sola per tutta la gara e stampa cosa succede.
Con `--shots=<cartella>` (e un display) salva anche degli screenshot.

## Build Android

`GODOT=/percorso/godot tools/build_android.sh` crea `build/NitroUnderground.apk`.
