# Crediti e licenze

Nitro Underground è stato fatto a costo zero, usando solo asset gratuiti. Qui c'è il riepilogo;
l'elenco completo, file per file, con autore, link, licenza e modifiche, è in
[`assets/LICENSES.md`](assets/LICENSES.md).

## Chi l'ha fatto

- **Idea, direzione, scelte di gioco e prove:** Stefano Paglierani
- **Codice, shader, strumenti e build:** scritti da Claude (Anthropic) su richiesta di Stefano
- **Suoni del motore:** sintetizzati da zero con `tools/audio/make_engine_sounds.py` (CC0)
- **Illustrazione del menu Route 66:** originale, disegnata in SVG (`tools/art/route66.svg`), usata nel menu fino alla v0.16
- **Immagini della pagina START, del garage e del caricamento (v0.17-v0.18):** fornite da Stefano Paglierani (vedi sotto)

## Fonti degli asset

| Fonte | Cosa | Licenza |
|---|---|---|
| [Poly Haven](https://polyhaven.com) | Cieli HDRI, texture di asfalto, roccia, erba, sabbia; lampioni e rocce | CC0 |
| [OpenGameArt](https://opengameart.org) | Kenney (piste, natura, strade), Quaternius (alberi, versione 2020), Yughues (erba, barriere) e altri | CC0 |
| [Freesound](https://freesound.org), OpenGameArt | Registrazioni di urti, cambiate, gomme, freno a mano | CC0 |
| [Sketchfab](https://sketchfab.com) | Alberi, chalet, cartelli, barriere, palazzi, palme, faro, motel, cactus, rocce | **CC BY 4.0** (attribuzione obbligatoria) |
| Sketchfab | Tutte le auto: garage e avversari, polizia, traffico (DanielZhabotinsky, Lexyc16, TinoD2, ollitei e altri) | CC BY 4.0 in gioco; nessuna auto NC (vedi sotto) |

Tutti gli autori Sketchfab sono citati per nome in `assets/LICENSES.md`.

## ⚠️ Cosa non si potrebbe usare in un gioco in vendita

Il gioco oggi è un **prototipo e un portfolio, senza scopo commerciale**. Alcuni asset sono stati
scelti consapevolmente solo per questa fase e andranno **sostituiti prima di qualsiasi
pubblicazione sugli store**. Stefano ha deciso così il 29 ottobre 2026.

1. **Licenze non commerciali (NC).** Dalla v0.15 (06/11/2026) **nessuna auto NC è nel gioco**:
   tutte le auto in gara sono CC BY 4.0, e il 06/11/2026 i file delle auto NC delle versioni precedenti
   (Charger 1970, Corvette Z06 e 1969, BMW M3 GTR, Supra A80, Camaro ZL1, GMC Sierra, Ford Mondeo
   Police, McLaren 600LT, Porsche 911 GT3, Raptor, RAM, Mustang) sono stati cancellati dal repository.
2. **Marchi registrati.** Dalla v0.15 le auto di marchi reali hanno nomi inventati e, dove si
   poteva, i loghi nascosti; restano però forme riconoscibili e alcuni loghi dipinti nelle texture
   (per esempio la Zenith Proto). Nomi, forme e loghi di Nissan, Honda, Mazda, Porsche, BMW, Datsun,
   Lancia, Ford, Oldsmobile, Chevrolet, Land Rover, Jeep e degli altri costruttori appartengono ai rispettivi proprietari. Usarli in un gioco in vendita richiede licenze
   dei costruttori, anche quando il modello 3D è CC BY.
3. **Riferimenti ai film.** La Skyline R34 "Brian" e la Charger "Fast And Furious Edition", ispirate
   ad auto di film famosi, sono state tolte dal gioco e dal repository il 06/11/2026.
4. **Provenienza incerta.** Dai nomi interni dei file, alcuni modelli di auto sembrano estratti da
   altri videogiochi da chi li ha caricati su Sketchfab. È un motivo in più per non usarli oltre il prototipo.
5. **Quaternius.** Gli alberi Quaternius nel repository sono la versione pubblicata su OpenGameArt
   nel 2020 con licenza CC0. Dal 28 agosto 2026 i nuovi pacchetti Quaternius non sono più CC0:
   non vanno aggiunti al repository senza ricontrollare la licenza.

6. **Immagini fornite da Stefano (v0.17-v0.18).** La pagina d'attesa (`assets/ui/title.jpg`) e il
   garage visto dal cofano (`loading_garage.jpg`, da cui sono ricavati `loading_door.png` e
   `garage_bg.jpg`) sono immagini date da Stefano per il gioco: **origine e diritti vanno
   confermati prima della pubblicazione**.

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
