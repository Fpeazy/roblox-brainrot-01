# Brainrot Collector — roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Fpeazy/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Fpeazy/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

A 3D Roblox arena game for make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01), built by an AI agent. Six Italian-brainrot meme characters —
Tung Tung Tung Sahur, Tralalero Tralala, Bombardiro Crocodilo, Brr Brr Patapim,
Lirili Larila and Chimpanzini Bananini — spawn as 3D Part figures with floating name
tags on coloured pads in a bright arena. Run into one to collect it for points;
it respawns on a random pad after a few seconds. Rounds last 120 seconds, the
leaderboard shows the top collectors live, and the winner is announced at the end
of each round.

## How to play

- **WASD or arrow keys** to move (Shift to sprint).
- Touch a brainrot to collect it. Rare ones are worth more: Bananini 25 pts,
  Crocodilo 20, Tralala and Lirili 15, Sahur and Patapim 10.
- The HUD shows your points, how many you collected, the round timer, the top 3
  collectors, and the name of the last brainrot you grabbed.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
  It warns when `PLAY.json` still names no published place, and prints the place
  and dossier sizes when it finishes.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
  The arena itself (green baseplate, six coloured spawn pads, centre totem, barrier
  obstacles, trees, boundary walls, SpawnLocation, bright afternoon Lighting) is
  defined in `default.project.json`; the characters are built at runtime by the
  server script, so they can move, bob and respawn.
- `src/server/init.server.luau` builds the brainrot figures, detects touches,
  awards points (leaderstats `Points` / `Collected`), respawns collected
  characters, and runs the 120-second rounds with a winner announcement.
  `src/client/Game.client.luau` draws the HUD (score, timer, top 3, last
  collected, announcements) and drives the character with WASD / arrows.
- `screenshots/` holds three captures of the game; `PLAY.json` names the
  published place. One of your screenshots must also be your game's first
  thumbnail on Roblox: the same picture, uploaded on the Creator Dashboard with
  your game's icon.
- `TOUR.json` is the optional tour: for each screenshot, the keys that bring the
  game to that screen.

## Run it

Build the place, then run the entry program as the grader does (writing `out/`
in place of `/output`):

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's
RULES.txt, which gives every command in order (Before you submit, then Enter).

## Honest status (what is still missing)

- `PLAY.json` still has `place_id` 0 / `universe_id` 0: the place has not been
  published yet. Publishing needs Roblox Studio (no Linux build) and the owner's
  Roblox account, so it cannot be done from this Linux machine. Publish the
  starter place from Studio, make it Public, and fill in the real ids.
- The three screenshots in `screenshots/` are the kit's placeholders, not
  captures of this game: real screenshots can only be taken in Studio, on
  Windows or macOS. Replace them from Studio before submitting, and upload one
  as the game's thumbnail plus an icon on the Creator Dashboard.

---

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
