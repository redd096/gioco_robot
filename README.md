# gioco_robot — Godot 4

Porting nativo della versione web. È ottimizzato prima di tutto per il landscape desktop/Steam e resta utilizzabile con mouse, tastiera e touch.

Questa revisione allinea la direzione artistica alla UI web: cornice cockpit azzurra, pulsantiera piatta ad alto contrasto, colori più luminosi, stato sistemi al neon, titoli inclinati, indicatori numerici incorniciati, telemetria con percentuali allineate, pannello COMANDO stabile e rapporto missione a schede.

## Avvio

1. Apri `project.godot` con Godot 4.7.2.
2. Premi **F6** o **F5** per giocare.
3. Per Android, installa i template di esportazione di Godot e seleziona **Progetto → Esporta → Android**.

## Comandi

- Desktop: frecce direzionali e tasti `1–6`, oppure mouse.
- Android: pulsanti touch della console.

La UI è composta da nodi `Control` nelle scene `main.tscn` ed `emergency_card.tscn`.

- Allarmi e comandi restano affiancati sia in landscape sia in portrait.
- `COMANDI DX/SX` inverte i lati per l'uso mancino e salva la preferenza.
- Gli allarmi hanno uno scorrimento indipendente, quindi la pulsantiera rimane visibile.
- I suoni degli allarmi e quelli dei pulsanti si possono disattivare separatamente.
- Un comando senza risorse fa lampeggiare e scuotere sia il pulsante sia la barra interessata.
- In landscape le card mantengono una griglia stabile e non cambiano larghezza quando il loro numero è dispari.
- La console usa pannelli azzurri, pulsanti colorati per sistema, costi e scorciatoie separati e animazioni di pressione.
- Il briefing iniziale e il rapporto finale usano la stessa struttura a schede della versione web.
- Il pannello `COMANDO` scorre dopo tutte le righe di emergenze e non può sovrapporsi alle card.

## Struttura

- `scenes/main.tscn`: interfaccia principale modificabile dall’editor.
- `scenes/emergency_card.tscn`: scheda riutilizzabile per un’emergenza.
- `scripts/main.gd`: regole, bilanciamento e stato della missione.
- Il layout di gioco è gestito direttamente da `HBoxContainer`, rapporti di espansione e ancoraggi della scena; il codice cambia soltanto l’ordine dei due pannelli per la modalità mancina.
- Colori e stati visivi dei pulsanti sono varianti modificabili in `theme/titan_theme.tres`, non vengono generati a runtime.
- `export_presets.cfg`: preset Windows, Linux, WebGL e Android.
