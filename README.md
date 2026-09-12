# gioco_robot — Godot 4

Porting nativo della versione 3 del prototipo web. Funziona con mouse, tastiera e touch, sia in orizzontale sia in verticale.

## Avvio

1. Apri `project.godot` con Godot 4.7.2.
2. Premi **F6** o **F5** per giocare.
3. Per Android, installa i template di esportazione di Godot e seleziona **Progetto → Esporta → Android**.

## Comandi

- Desktop: frecce direzionali e tasti `1–6`, oppure mouse.
- Android: pulsanti touch della console.

La UI è composta da nodi `Control` nelle scene `main.tscn` ed `emergency_card.tscn`. Il contenitore `ResponsivePlayArea` dispone automaticamente allarmi a sinistra e comandi a destra in orizzontale; in verticale mette i comandi sopra gli allarmi.

## Struttura

- `scenes/main.tscn`: interfaccia principale modificabile dall’editor.
- `scenes/emergency_card.tscn`: scheda riutilizzabile per un’emergenza.
- `scripts/main.gd`: regole, bilanciamento e stato della missione.
- `scripts/responsive_play_area.gd`: layout responsivo.
- `export_presets.cfg`: preset Windows, Linux, WebGL e Android.
