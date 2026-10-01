# Handoff: Wolves With Your Friends

Read this first in a new session. It's the full state of the project and the plan.

## The game
A Roblox co-op party game, 1–10 players, 10-minute workdays, **first person**. It copies the mechanics of
*Scam With Your Friends* (ringing desk phones, AI callers you talk to by voice, collecting a code or number and
entering it in a deal app, Personal + Firm money, a daily quota that rises, a boss meeting with a vote for the
funniest line, a fired screen, a Final Statement ranking, a shop, weapons). The theme is a Wolf of Wall Street style
brokerage on **floor 100** of a skyscraper, with a city, traffic and a rooftop.

Rules:
- Cartoony but realistic materials.
- No movie names, real people or brands.
- No alcohol: bottles are soda or juice.
- All-ages, Roblox-safe.

The owner prefers **quality over speed** and wants **models built in Blender first**, then brought into Roblox.

## Repo layout
- `blender/`: bpy 5.0.1 (pip, Python 3.11) scripts. `lib.py` has the helpers (`cube`, `tube`, `sphere`,
  `cone`, `torus`, `skin`, `text`, `mat`, `studio`, `render`). The props live in `props.py`:
  - Materials are named `M(kind, look)`, which gives `"Kind_Look"`, and each kind is a Roblox material name.
  - A prop's front faces -Y and its floor is at Z=0. Builders are grouped in `BUILDERS`..`BUILDERS_6`.
  - Build: `python3 props.py --part i 4` for i = 0..3 (run in parallel, about 1 minute), then `python3 merge_props.py`.
    This writes `props.blend`. Building in one process is O(n²) and slow.
  - `python3 export_props.py` writes `export/props/PropPack1-4.fbx` and `roblox/src/shared/PropLooks.lua`
    (a Roblox material, color and transparency per material name, plus each prop's bounds).
  - `python3 render_props.py [Name ...]` renders `renders/prop_<Name>.png`.
- `blender/office_scene.py`: the whole-floor layout, 48 x 34 m.
  - It writes `roblox/src/shared/OfficeLayout.lua`, which holds parts, props, screens, tickers, signs, boards,
    lights, chaos areas, meeting seats and named points.
  - `--layout-only` writes the layout and skips rendering (about 1 minute). A full run also renders the overview,
    the plan and 5 interior shots to `renders/office_*.png`.
  - Placement uses `place(name, loc, rot)`. `rot` turns the prop's front: 0 faces -Y, pi faces +Y, R(90) faces +X.
  - Chairs face -Y, so a chair south of a desk gets rot pi.
- `roblox/`: a Rojo 7.6.1 project. Build it with `rojo build default.project.json -o WolvesWithYourFriends.rbxl`.
  - Type-check with `luau-lsp analyze --sourcemap=sourcemap.json --definitions=<globalTypes.d.luau> src`.
    Get the definitions from the luau-lsp repo (`scripts/globalTypes.d.luau`); rojo and luau-lsp come from their
    GitHub releases.
  - Studs per meter: `Config.STUDS_PER_METER = 3`. Blender (x, y, z) maps to Roblox (x·S, z·S, −y·S), and the turn
    around Z stays the same (see `ArtLibrary.pos/cf/offset/facing`).
  - `server/OfficeBuilder.lua` builds the floor from OfficeLayout:
    - working desks on every DeskSet, with a Mirror SurfaceGui, the INCOMING card, the ring countdown pill,
      and Answer / Use Computer / Take Over prompts
    - elevators with sliding doors and a car; players spawn inside the middle car
    - chart walls tagged `DeskScreen`, tickers tagged `Ticker`, and boards tagged `OfficeBoard`
    - props that aren't in the FIXED list get `Props.movable`
  - `server/ArtLibrary.lua` finds imported models in `ServerStorage.PropModels`, scales and turns them, and applies
    PropLooks. It falls back to grey boxes.
  - `server/CallService.lua`, `ClientAI.lua` (TextGenerator + canned fallback), `Economy.lua`, `GameLoop.lua`
    (day → meeting → fired), `Props.lua`, `NPCGuide.lua` (NPCs removed; it only fires Ring/Chairman remotes).
  - Client: `Desktop.lua` (Shark OS: basic windows/taskbar), `apps/PhoneApp.lua`, `DealApp.lua`, `ScriptApp.lua`,
    `Voice.lua` (mic → AudioSpeechToText, AudioTextToSpeech replies), `IdleScreens.lua` (live charts on idle
    monitors), `OfficeBoards.lua` (LED clocks, suspicion meter, day goal board), `Hud.lua`, `Menu.lua`, `Meeting.lua`,
    `City.lua`, `Decor.lua`.
  - The owner imports the 4 prop packs into `ServerStorage/PropModels`; the steps are in `roblox/README.md`.

## Done
- Characters, and 144+ props in Blender (office furniture, Wall Street decor, food, weapons, hand poses, flag,
  pool table, broken fish tank, rooftop not yet).
- The full office layout, rendered, and generated into Roblox.
- Calls with AI and voice.
- Live idle screens and wall boards.
- Usernames hidden.
- Rings show a yellow outline and a countdown with **no arrows**, and any computer can be used.
- **Step 1, the Windows-style Shark OS** (not yet tested in Studio):
  - `Window.lua`: min/max/close, drag, snap to the left/right half or top, double-click to maximize, resize grip.
    Apps open windows through `Desktop.window(appId, title, size, pos?, resizable?)`.
  - `Desktop.lua`: wallpaper, desktop icons (double-click; files in `FileSystem.desktop` also show), right-click
    menu, start menu with search and Leave Desk, and a taskbar with Start, pinned apps, running apps, the objective,
    PERSONAL / TEAM / QUOTA / REVIEW timer, the clock and day, notifications and a show-desktop sliver.
  - Shared client state is in `State.lua`, files in `FileSystem.lua`, wallpapers in `Wallpapers.lua` (3 premium),
    caller portraits in `Avatar.lua` and photos in `Photo.lua`.
  - Apps in `client/apps`: Phone (avatar, personality line, trust number and label, bubbles, 3 suggested replies
    from `PitchScripts.suggest`, Request Access / Hang Up / speaker / mic, and a "No call at this desk" screen),
    Script, the deal apps (Account Opener, TradeLink, Penny Stock, **Card Verify**), Files, Notes, Browser (6 fake
    sites), Shark Mart (Upgrades / Store / Employees / Bank), Camera (live webcam copy of your character, 4 filters,
    SNAP to Photos), Remote Access (session shell), Backgrounds, Shark Shield antivirus, PumpAds (+ pop-up adware)
    and **Wolf Casino**, which replaced the minigame at the owner's request.
    - Wolf Casino: deposit Personal money into a wallet, then play Up or Down (1.9×) or Stock Slots, and cash out.
      The server rolls every result. It uses in-game money only, never Robux, and winnings don't count toward the
      firm's target. The owner should answer the "gambling" questions in the experience's maturity questionnaire.
  - `DeskMirror.lua`: the server copies each player's compact desktop state to their monitor's `DeskState`
    attribute, and every client draws it on that monitor (`IdleScreens` steps aside).
  - Server:
    - `Shop.lua`: buying, the bank deposit to the firm, employees paid every 20 s of the workday, and PumpAds.
    - `Casino.lua`: the casino wallet and games.
    - `Economy.spend/deposit`, and a `note` on Money events for the bank history.
    - `CallService`:
      - desk tracking, `DeskState` / `LeaveDesk`, and Request Access (70 trust, or 50 with Account Access; 60 s
        sessions, or 90 s with the VPN)
      - upgrade effects: Lucky Tie, Smooth Talker, Stall Script, Advanced Extractor, and the VPN's no trust loss
        on a refused request

## Still to do (in this order)
1. ~~**Windows-style computer (big).**~~ Done (see above); the list below is kept for reference. Shark OS should look like a real Windows-like desktop with no Microsoft
   branding:
   - Desktop: start menu, taskbar with pinned apps and a tray clock, windows with min/max/close, drag and snap,
     wallpapers plus a Backgrounds app, and a file explorer (the Files app with folders and openable documents).
   - Apps: Script, Browser, Phone, Notes, a Shark Mart store (Upgrades / Store / Employees / Bank), Camera,
     Remote Access, Backgrounds, an antivirus, Card Verify, PumpAds, a minigame and Files.
   - Taskbar info: objective text, PERSONAL, TEAM/QUOTA, review timer, clock + day.
   - Phone app:
     - Show the caller's avatar, a personality line ("sounds believes anything"), and a trust bar with a number
       and label.
     - Show chat bubbles and **3 suggested replies**.
     - Buttons: Request Access, Hang Up, speaker, mic.
     - At a desk with no call it says "No call at this desk. Find a RINGING desk."
   - Camera app: a live self-view from the desk webcam, Normal/Warm/Cool/Noir filters, and SNAP to Files/Photos.
   - Upgrades (the reference game's, renamed): Account Access, Advanced Extractor, Stall Script, Smooth Talker,
     Better Script, VPN.
   - Your own monitor shows your desktop to passers-by.
2. **Remote control of the caller's computer: dropped.** The planned mechanic was reading the caller's bank PIN,
   security codes and crypto password and moving their money out. That is too close to a real remote-access scam
   playbook, so it won't be built. The existing Request Access button and the Remote Access session shell from
   step 1 stay as they are. A harmless replacement can be designed with the owner.
3. ~~**Physics.**~~ Done (not yet tested in Studio).
   - Grab + throw: `client/Throwing.lua` (look at a prop, E to pick up, hold Q to charge and throw, E to drop;
     GRAB/THROW buttons on touch) and `server/Physics.lua` (grants network ownership, caps throw speed, records the
     thrower). Grabbing is off while the computer is open. `Props.movable` tags every movable prop "Grabbable".
   - `server/Interactions.lua`: ProximityPrompts to Eat food, Pour Coffee (spawns a cup) and Print (a page drops
     out). Cups leave a puddle when tipped or thrown while full. `client/Effects.lua` draws the Fx (puddle, pour,
     eat, print, fish-tank splash).
   - Trash bins (TrashBin / RecyclingBins) swallow items dropped in and spill them when the bin is thrown.
   - The fish tank breaks when hit hard and swaps in FishTankBroken (needs the imported model; falls back to a box).
   - Remaining: knock-OFF of the roof is step 4; thrown-item damage to players is minimal for now.
4. ~~**Luxury rooftop (Blender first).**~~ Done (not yet tested; needs the new props re-exported from Blender).
   - Blender: `props.py` has a new `BUILDERS_7` group (DJBooth, SpeakerStack, PoolLounger, Parasol, RooftopBar,
     SodaBottle, JuiceBottle, PlanterBox, HotTub). Re-run the prop build + `merge_props.py` + `export_props.py` to
     get them into the packs and into `PropLooks.lua`; until then the rooftop shows grey-box fallbacks for them.
     (bpy isn't installed in this session, so the packs were NOT regenerated here.)
   - `server/RooftopBuilder.lua`: an open-air deck 90 studs above the office with a glass parapet, pool + hot tub,
     two bars, a DJ stage, loungers under parasols, planters, string lights, scattered money/papers, and breakable
     bottles. `server/RoofService.lua`: ROOFTOP button in each elevator car and an OFFICE kiosk on the roof, DJ
     music (set `Config.DJ_MUSIC_ID`), bottles shatter when thrown, thrown items can knock players off, and a fall
     respawns you at your last safe spot.
   - Config: `DJ_MUSIC_ID` and `ELEVATOR_DING_ID` (both default "").
5. ~~**Character menu (only before spawning).**~~ Done (not yet tested).
   - `shared/Appearance.lua`: all looks built from parts (no catalog assets, so it works in an unpublished place):
     skin tones, hair styles + colors, hats, glasses, outfits + colors, body types, build (neutral/masc/femme) and
     animation packs. `Appearance.apply(character, look)` dresses an R15 rig; `sanitize` guards the server.
   - `client/Customizer.lua`: a draggable, zoomable 3D preview (an R15 rig from CreateHumanoidModelFromDescription)
     with option tabs, a RANDOM button, and a background of candlesticks, floating cash and a ticker. Reached from
     the menu's CUSTOMIZE CHARACTER; ENTER FLOOR 100 spawns with the chosen look.
   - `server/CharacterService.lua`: applies the look and the animation pack on spawn (the look rides in on Spawn).
   - Note: body-type scaling shows on the spawned character; the preview may not rescale (ViewportFrame Humanoids
     don't drive scale). Animation-pack asset ids are best-effort and fall back silently.
6. ~~**Call upgrades and 100+ callers.**~~ Done (not yet tested).
   - `shared/Clients.lua`: 25 featured callers plus a generator for 90 more (115 total), each with a distinct voice
     (11 TTS voices x pitch x speed), a kind, a behavior `type` and a cartoon look.
   - Caller types drive behavior (`ClientAI` prompt + canned + suspicion): trusting (warms fast), paranoid (spooks
     easily), bait (silly reverse-scam that never does real phishing), normal.
   - Per-call suspicion meter (`CallService`): rises on rude/repeated lines, faster for paranoid callers, calmed by
     Smooth Talker; at 100 the caller hancs up. Shown as a red bar in the Phone.
   - Auto-notes: when a caller reads out a secret, it's jotted in the Phone as a 📝 note (and sent in CallUpdate).
   - Memory/contradictions ride on the AI ContextToken (already there).
   - Filler speech while the caller thinks + interruption (talking cuts the caller off): `Voice.filler` / `Voice.stop`.
   - Bystanders hear calls at the desk: `CallSpeak` broadcast + `client/SpatialVoice.lua` (AudioEmitter per desk).
   - No real people: all callers are fictional (kept the existing rule).
7. ~~**Office suspicion and raid.**~~ Done (not yet tested).
   - `server/Suspicion.lua`: a floor-wide 0-100 meter. Rises when a caller gets spooked and hangs up (+14) and from
     chaos (thrown items), decays when calm, and a clean deal shaves a little off. Broadcast in Status, so the
     existing OFFICE SUSPICION wall board now actually moves.
   - At 100 `GameLoop` ends the day early and runs the raid, then the fired screen.
   - `server/RaidService.lua`: helicopters circle outside with officers rappelling on ropes, and cartoon officers
     (navy, caps, water-blaster "guns") march out of the elevators. `client/Raid.lua` plays the siren flash, the
     "FLOOR 100 RAIDED" banner and a pulled-back shaking camera.
8. ~~**Hands.**~~ Done (not yet tested).
   - `client/Gestures.lua`: number keys 1-7 play hand poses (wave, point, thumbs up, peace, fist, call-me, clap),
     a touch wheel lists them, and holding a thrown item puts both arms into a grab/aim pose. Poses overlay
     `Motor6D.Transform` on the shoulders/elbows so they ride on the walk animation, and they're replicated via the
     Gesture remote so everyone sees them. Hooked into Throwing (grab pose) and relayed by the server.
9. ~~**Spatial sound effects.**~~ Done (not yet tested; add asset ids to hear them).
   - `shared/Config.lua`: `SOUNDS` (ring, impactSoft/Hard, glassBreak, elevatorDing/Doors, splash, pour, printPage,
     coin, gong) and `PIANO_NOTES` (one octave), all default "" - fill with Creator Store audio ids and they play.
   - `server/Audio.lua`: plays one-shot spatial sounds (server-made, so everyone nearby hears). Empty id = silent.
   - Wired: hard landings of grabbed/thrown props (`Physics`), fish tank + bottle breaking, elevator ding + doors
     (`OfficeBuilder`), phone ring (existing `RING_SOUND_ID`), DJ music (`RoofService`).
   - Playable piano: `server/PianoService.lua` adds a "Play Piano" prompt to the grand piano; `client/Piano.lua` is
     the keyboard (click or A S D F G H J), and notes play at the piano for everyone.
10. ~~**Talking mouths and headset mics.**~~ Done (not yet tested).
    - `Appearance.addGear(char)`: a headset (band + earcups + boom mic) and a Mouth part on every character, added
      after dressing (in `CharacterService`).
    - `client/TalkingMouths.lua`: wires an AudioAnalyzer to each player's voice input and opens their Mouth by how
      loud they're talking, so you can see who's speaking. Closed where the Audio API / a mic isn't available.

## Notes
- The owner can't send video. They test in Studio and send screenshots.
- The AI (TextGenerator) may not run in unpublished Studio; the canned lines are the fallback.
- Always rebuild the .rbxl, type-check, commit and push after each piece of work.
