# Crediti e licenze

Nitro Underground è stato fatto a costo zero, usando solo asset gratuiti. Qui c'è il riepilogo;
l'elenco completo, file per file, con autore, link, licenza e modifiche, è in
[`assets/LICENSES.md`](assets/LICENSES.md).

## Chi l'ha fatto

- **Idea, direzione, scelte di gioco e prove:** Stefano Paglierani
- **Codice, shader, strumenti e build:** scritti da Claude (Anthropic) su richiesta di Stefano
- **Suoni del motore:** sintetizzati da zero con `tools/audio/make_engine_sounds.py` (CC0)
- **Illustrazione del menu Route 66:** originale, disegnata in SVG (`tools/art/route66.svg`)

## Fonti degli asset

| Fonte | Cosa | Licenza |
|---|---|---|
| [Poly Haven](https://polyhaven.com) | Cieli HDRI, texture di asfalto, roccia, erba, sabbia; lampioni e rocce | CC0 |
| [OpenGameArt](https://opengameart.org) | Kenney (piste, natura, strade), Quaternius (alberi, versione 2020), Yughues (erba, barriere) e altri | CC0 |
| [Freesound](https://freesound.org), OpenGameArt | Registrazioni di urti, cambiate, gomme, freno a mano | CC0 |
| [Sketchfab](https://sketchfab.com) | Alberi, chalet, cartelli, barriere, palazzi, palme, faro, motel, cactus, rocce | **CC BY 4.0** (attribuzione obbligatoria) |
| Sketchfab | Tutte le auto: garage e avversari, polizia, traffico | CC BY 4.0, **CC BY-NC 4.0**, **CC BY-NC-SA 4.0** (vedi sotto) |

Tutti gli autori Sketchfab sono citati per nome in `assets/LICENSES.md`.

## ⚠️ Cosa non si potrebbe usare in un gioco in vendita

Il gioco oggi è un **prototipo e un portfolio, senza scopo commerciale**. Alcuni asset sono stati
scelti consapevolmente solo per questa fase e andranno **sostituiti prima di qualsiasi
pubblicazione sugli store**. Stefano ha deciso così il 29 ottobre 2026.

1. **Licenze non commerciali (NC).** Questi modelli si possono condividere solo senza scopo di
   lucro e citando l'autore; quelli "SA" vanno ridistribuiti con la stessa licenza:
   - Garage: 1970 Dodge Charger R/T — OUTPISTON, CC BY-NC-SA 4.0; 2013 Chevrolet Corvette Z06 —
     Outlaw Games™, CC BY-NC 4.0; BMW M3 GTR E46 — Alex.Ka., CC BY-NC 4.0; Toyota Supra A80 —
     Lexyc16, CC BY-NC 4.0
   - Traffico: 1969 Chevrolet Corvette Stingray — Ddiaz Design, CC BY-NC-SA 4.0; Chevrolet Camaro
     ZL1 — Outlaw Games™, CC BY-NC 4.0; GMC Sierra Work Truck — Renafox, CC BY-NC 4.0
   - Ford Mondeo Police (auto della polizia) — TSB3DMODELS, CC BY-NC 4.0
   - Non più nel gioco ma ancora nel repository: McLaren 600LT e Porsche 911 GT3 (Outlaw Games™,
     CC BY-NC 4.0), Ford F-150 Raptor R (VTX), Ram 1500 TRX e Mustang GT (Ddiaz Design), CC BY-NC-SA 4.0
2. **Marchi registrati.** Nomi, forme e loghi di Dodge, Chevrolet, BMW, Toyota, Mercedes-Benz, GMC,
   Land Rover, Jeep, Ford e degli altri costruttori appartengono ai rispettivi proprietari. Usarli in un gioco in vendita richiede licenze
   dei costruttori, anche quando il modello 3D è CC BY.
3. **Riferimenti ai film.** La Skyline R34 "Brian" e la Charger "Fast And Furious Edition" si
   ispirano ad auto di film famosi: in una versione commerciale non devono comparire.
4. **Provenienza incerta.** Dai nomi interni dei file, alcuni modelli di auto sembrano estratti da
   altri videogiochi da chi li ha caricati su Sketchfab. È un motivo in più per non usarli oltre il prototipo.
5. **Quaternius.** Gli alberi Quaternius nel repository sono la versione pubblicata su OpenGameArt
   nel 2020 con licenza CC0. Dal 28 agosto 2026 i nuovi pacchetti Quaternius non sono più CC0:
   non vanno aggiunti al repository senza ricontrollare la licenza.

Tutto il resto (CC0 e CC BY) si può usare anche in un gioco in vendita. Per i CC BY i crediti
dovranno comparire anche **nei titoli di coda del gioco**, che non ci sono ancora.

## Regole per i nuovi asset

- Ogni nuovo file in `assets/` va registrato in `assets/LICENSES.md` nello stesso commit:
  fonte, autore, link, licenza alla data del download, modifiche.
- Preferire CC0 e CC BY. Un asset NC o di un marchio reale si aggiunge solo se Stefano lo chiede,
  e va segnalato qui nella sezione "Cosa non si potrebbe usare".
- I file grandi della libreria di lavoro (modelli non ancora usati, APK, zip originali) restano
  nella cartella del progetto, fuori dal repository.

## Il codice

Il codice non ha ancora una licenza open source: tutti i diritti sono riservati all'autore.
Si può leggere e studiare qui su GitHub, ma non riusare senza permesso.
