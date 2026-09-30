# Wolves With Your Friends: Roblox game (Phase 1)

`WolvesWithYourFriends.rbxl` is a ready-to-open place file built from `src/` with [Rojo](https://rojo.space).

## Open and test it

1. In Roblox Studio: **File > Open from File** and pick `WolvesWithYourFriends.rbxl`.
2. **File > Publish to Roblox**. The AI and voice features only work in a published game.
3. **Game Settings > Communication**: turn on **Enable Microphone** (and voice chat).
4. VoiceChatService.UseAudioApi is already set to Enabled in the place file.
5. **Game Settings > Places**: set the server size to **10**.
6. Press **Play**, or use **Test > Clients and Servers** with 2+ players to try Take Over Call.

If the AI text service isn't available to the game yet, clients fall back to canned lines automatically. Without a mic, players type in the Phone app.

## Put the real furniture in (4 imports)

The office is built from the Blender layout (`src/shared/OfficeLayout.lua`). Until the models are imported,
every prop shows up as a grey box of the right size, so the game still works.

1. In **ServerStorage**, create a folder named **PropModels**.
2. **File > Import 3D**, pick `../blender/export/props/PropPack1.fbx`. In the importer, keep it as one model and import.
3. Drag the imported model into **ServerStorage > PropModels**. You can leave it as one model: the game looks
   inside it for each prop by name (`DeskSet`, `OfficeChair`, `GoldBull`, ...).
4. Do the same for `PropPack2.fbx`, `PropPack3.fbx` and `PropPack4.fbx`.
5. Press **Play**. Props are scaled, turned and given real materials (leather, chrome, marble, glass...) automatically.
   If every prop faces backwards, set `Config.PROP_TURN_DEGREES = 180` in `src/shared/Config.lua`.

## What works in Phase 1

- Floor 100 blockout: trading floor with 14 desk computers, conference room, CEO office, break room, elevator lobby with LED logo, floor-to-ceiling windows, skyline and moving traffic 700 studs below.
- Calls: a random desk rings (red lamp, "RING RING!" tag, NPCs shout the desk number). Run over and press **E** to answer. Unanswered calls jump to another desk after 8 seconds.
- **Take Over Call**: walk up to a coworker's desk and hold **F**. The AI client is told a new broker grabbed the phone.
- AI clients: 9 fictional personalities with their own voices. They remember the whole call (TextGenerator ContextToken), react to what you say, and only share their details once their interest reaches 60%.
- Voice: speak into your mic (MIC ON), and the client answers out loud in your headset. Typing always works too.
- Shark OS: boot screen, draggable windows, taskbar, status bar (Personal / Firm / Target / meeting countdown / clock).
- Apps: Phone, Account Opener ($250), TradeLink ($400), Penny Stock Order ($600), Script (optional pitch lines).
- Money: every deal pays Personal **and** Firm money. The daily target rises: $600, $1,400, $1,750, $2,600, ...
- 10-minute day, then the boss meeting: players are pulled to the conference room, Deal Replay shows 3 funny lines, everyone votes, and the winner gets $500.
- Target met: bonus, next day. Missed: YOU'RE FIRED, the room catches fire, then the Final Statement ranking.

## Not built yet (next phases)

Pick up / throw / ragdolls, throwable NPCs, weapons and Shark Mart, office events (raid, outage, celebrity...), rooftop club, bathrooms, playable custom characters (rigging), the main menu with private offices, and a ring sound (add a Creator Store sound id to `Config.RING_SOUND_ID`).

## Developing

`rojo serve` + the Rojo Studio plugin syncs `src/` live into Studio. `rojo build -o WolvesWithYourFriends.rbxl` rebuilds the place file.

| Folder | Runs on | What |
| --- | --- | --- |
| `src/shared` | both | Config, AI client personalities, deal apps, pitch scripts, remote events |
| `src/server` | server | Office builder, calls, AI, money, NPCs, day/meeting loop |
| `src/client` | each player | HUD, Shark OS desktop and apps, voice, meeting screens, traffic |
