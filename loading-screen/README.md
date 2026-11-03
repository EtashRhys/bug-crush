# Animated loading screen

The web loading screen is an animated PNG (APNG), not the static image
Godot exports.

- `splash-animated.apng` — 5s loop: the BUG CRUSH title pulses neon
  purple (the bug-zapper look), a ladybug crawls across the name and gets
  zapped, then it repeats.
- `gen_loading.py` — regenerates the static splash (`splash.png`) and
  the APNG. Run it, then copy the new files into the project.

Deploy step (do not skip): the Godot web export always writes a static
`index.png` from `splash.png`. After every export, replace
`export/index.png` with this APNG before copying to live. The default
web shell then plays the animation with no loader changes.

Note: this folder is a deploy asset, not a game resource. Do not copy
the APNG into the Godot project itself, or it will bloat the game
package.
