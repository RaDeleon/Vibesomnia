# Vibesomnia app icon

A sleep-deprived developer mascot for the late-night AI coding workflow.

- `AppIcon-source.png`: original generated artwork, 1254 × 1254 RGBA.
- `AppIcon.png`: 1024 × 1024 PNG export for previews and branding.
- `AppIcon.icns`: macOS icon family, 16–1024 physical pixels including Retina sizes.
- `../script/generate_icon.sh`: reproducible export using macOS `sips` and `iconutil`.

The app bundle uses `CFBundleIconFile`; the dashboard uses the app's bundled icon.
The menu bar uses the same full-color ICNS artwork at 20 points, with a small
green dot while a session is active. It retains the mascot in both states;
accessible labels also identify idle/awake status. No separate generated artwork
or system sleep symbol is used for the menu bar.

## Generation

Created on 2026-11-07 with the built-in image-generation tool, following the
owner's request for a developer with bloodshot eyes vibe coding all night.
Only resizing and macOS icon-format conversion were applied afterward.

### Final prompt

Create one polished macOS app icon for Vibesomnia, an open-source utility that keeps a Mac and AI coding agents awake for late-night remote development. User's specific concept: a developer with bloodshot eyes vibe coding all night. Asset: a single square 1024x1024 application icon, not a presentation or contact sheet. A memorable stylized cartoon developer mascot, gender-neutral young adult, messy dark hair, charcoal hoodie, huge tired slightly bloodshot eyes with simple reddish veins, purple under-eye bags, small wry determined smile. Head and shoulders filling most of a deep midnight-indigo rounded-square macOS icon tile, behind a small laptop at the bottom foreground. The laptop casts soft cool lavender screen light upward onto the face; a small simple luminous code chevron on laptop lid ties it to AI-assisted coding. Sleep-deprived but endearing and clever, not horror, not sick or injured. Premium contemporary character illustration with clean bold silhouette, gently dimensional matte shading, restrained lilac/violet palette with warm peach skin and red eye accents, crisp contours, strong contrast and legible at 32px. Face is the unmistakable focal point, eyes large but not grotesque. No caffeine cup or extra clutter. Straight-on, icon fills canvas with standard macOS outer margin; transparent outside the rounded-square tile, no surrounding scene. No words, no letters, no watermark, no multiple options, no photorealism, no tiny code text.
