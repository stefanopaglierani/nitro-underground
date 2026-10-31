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

     **Cosa ha chiesto Stefano:** le sue richieste, con le sue parole quando sono efficaci.

     **Cosa è stato fatto:** i cambiamenti visibili, spiegati per chi non programma.
     Numeri misurati solo se davvero misurati.

     **Cosa ne ha pensato Stefano:** (solo se ha già provato la versione)
     ```
   - Se Stefano ha provato una versione precedente, aggiungi il suo giudizio a quella voce.
   - Aggiorna "Prossimi passi".
2. **[README.md](../README.md)**
   - Riga "Versione attuale" in alto (numero e data), anche nel riassunto inglese.
   - "Cosa c'è nel gioco", "Tecnologia" e "Struttura del codice" se sono cambiati.
   - Gli screenshot se il gioco ora ha un aspetto diverso.
3. **[CREDITI.md](../CREDITI.md) e `assets/LICENSES.md`**: ogni nuovo asset registrato; se è NC o
   di un marchio reale, aggiunto all'elenco "Cosa non si potrebbe usare".
4. **Screenshot**: in `docs/immagini/`, JPG di 1280×720 al massimo, qualità circa 80
   (meno di 400 KB l'uno). Nome con la versione, per esempio `v0.12-garage.jpg`.

## Regole di scrittura

- In italiano, frasi semplici, comprensibili da chi non programma. Il riassunto inglese del README
  resta breve.
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
