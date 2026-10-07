### Policy condivisa di salute delle dipendenze

- **Security gate:** 0 vulnerabilità High/Critical; Low/Moderate entro SLA.
- **Health gate:** pacchetti deprecati rimossi oppure eccezione tracciata con owner e scadenza.
- **Freshness:** gli outdated sono inventario e piano di aggiornamento, non un blocker universale; patch/minor/major seguono rischio e compatibilità.
- **Platform migration:** cambiare TFM è un intervento separato, richiesto solo per EOL, incompatibilità con una versione sicura/supportata o richiesta esplicita.
- **Eccezioni:** `dependency-exceptions.json` registra package, reason, owner, expires e ticket. Tutti i record scaduti falliscono; i `deprecated` non corrispondenti falliscono il relativo gate; `vulnerable` registra accettazioni Low/Moderate verificate dal security gate.
