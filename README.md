# gioco_robot — Godot 4

Porting nativo della versione 8 del prototipo web. Funziona con mouse, tastiera e touch, sia in orizzontale sia in verticale.

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

## Struttura

- `scenes/main.tscn`: interfaccia principale modificabile dall’editor.
- `scenes/emergency_card.tscn`: scheda riutilizzabile per un’emergenza.
- `scripts/main.gd`: regole, bilanciamento e stato della missione.
- `scripts/responsive_play_area.gd`: layout responsivo e inversione mancini.
- `export_presets.cfg`: preset Windows, Linux, WebGL e Android.
