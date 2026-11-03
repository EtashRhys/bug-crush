# Bug Crush

An 8x8 match-3 game where the pieces are cartoon bugs, drawn entirely in code.
No timer, no lives, no fail state — just matching, combos, and escalating
celebrations.

Play it live: https://ucii.sportgen-ai.com/bug-crush/

## How it plays

- Drag a bug onto a neighbour, or tap two neighbours, to swap.
- Match 3 or more and they pop with a bounce, a fade, and a wet-squirt splat
  sound (bigger runs get bigger splats). Gravity refills the board, and
  cascades score as combos.
- Score + Best (Best is saved on the device). Shuffle rescues a dead board.
- Levels are colours only — the point gaps widen as you climb:
  1500 / 4000 / 7500 / 12000, then a bonus fly-splat and colour change every
  2500 points forever, cycling through 12 colour themes.
- On every level-up, a giant fly smashes into the board, the screen shakes,
  and the whole colour theme changes.
- Every 30 seconds a random bug crawls in across the top, the title flips to
  bright purple neon like a bug zapper and pulses, and the bug pops when it
  reaches the title.
- Portrait only on phones: landscape shows a "rotate your phone" screen and
  the same board comes back when you rotate, no progress lost.
- Share buttons below the board: Email Score, and Post to X (shares a
  screenshot of the board plus your score).

## Build

Godot 4.7.2, GL Compatibility renderer, portrait 720x1280. Web export preset
is in `export_presets.cfg` (thread support off).

```sh
# check the scripts first
godot --headless --check-only --script scripts/main.gd
# import new assets if any were added
godot --headless --import
# export
mkdir -p export
godot --headless --export-release "Web" export/index.html
```

## Tracking

Aggregate-only popularity counting, no personal data: the game sends one
fire-and-forget beacon per event to `/bug-crush-track/beacon` (same origin).
No IPs, cookies, fingerprints, scores, or player identities are collected,
and bot user-agents are filtered out. Counts live in `tracker/track.py`
(stdlib Python, systemd service on the production box, proxied through
nginx as `/bug-crush-track/`).

What it counts, per day and in total: game loads, plays (sessions with at
least one accepted swap), level-ups (per level number), and share taps
(split email vs X). Stats page: https://ucii.sportgen-ai.com/bug-crush-track/stats

## License

Bug Crush is MIT licensed — see `LICENSE`. Anyone can use, remix, or share
it, with credit.

## Credits

- Font: Luckiest Guy, SIL Open Font License.
- Sounds: synthesized, no external audio files.
- Bugs: ladybug, bee, ant, caterpillar, butterfly, spider — all drawn in
  code, no image files.
- Loading screen + tab icon: custom Bug Crush logo art (splash.png, icon.png).
- Loading screen animation: neon-purple pulsing title + ladybug crawl + zap,
  5s APNG loop — see loading-screen/ (export's index.png is replaced
  with it after every export).
