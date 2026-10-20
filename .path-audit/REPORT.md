# File reference audit

Checked with Godot 4.7.2 in headless mode on 2026-10-06. No game source files were edited.

Loaded 303 scenes, resources, and scripts: 4 failed the resource/script check. Other scenes returned resources while reporting missing dependencies, so a successful load result does not mean a working scene. Scenes were not instantiated or played through. Runtime path strings were checked separately against the filesystem. Existing local UID/import caches were used.

## Confirmed load failures

- `Scripts/enemy.gd:24`: missing preload `Assets/SoundEffects/PiercingEnemyDeath.wav`; the file now exists under `Assets/SoundEffects/BulletSounds/`.
- `Scripts/enemy_bullet.gd:7`: missing preload `Assets/SoundEffects/NormalRicochet.wav`; the file now exists under `Assets/SoundEffects/BulletSounds/`.
- `Scripts/Menus/OptionsMenu/key_bindings.gd:7,8`: both background/panel preloads still use `Assets/Tilesets/KeyboardAndMouse/`; the images now live in `Assets/Images/Tilemap/KeyboardAndMouse/`.
- `Scenes/UI/MainMenu/profile_menu.tscn:5`: missing panel image at the same old KeyboardAndMouse path. Loading the main menu also reports this dependency failure.

## Broken runtime paths

- `Scripts/MainMenu/menu.gd:5,59,61`: playground shortcut and both New Game branches still target `Scenes/` instead of `Scenes/Levels/`.
- `Scripts/cutscene.gd:33`, `Scripts/Menus/act_select.gd:142`, `Scripts/Menus/act_score_screen.gd:119`: transitions still target `Scenes/main_game.tscn`.
- `Tests/act_unlocks_test.gd:103`: test loads the old act-selection scene location.
- `Scripts/settings_manager.gd:34,35`: cursor image loads fail at startup. The matching images are in `Assets/TO BE REPLACED/StrangeCowboy/Player/`.
- `Scripts/settings_manager.gd:97`: the old cutscene path comparison no longer recognizes the cutscene as a menu context.
- `Scenes/UI/Chamber/bullet_chamber.gd:23-63`: all nine chamber images point to `Assets/Images/ChamberBullets/`; they now live under `Assets/Images/Chamber/`. These strings are passed to `load()` when the UI updates.

## Scenes with missing visual or tileset dependencies

- Act 1 levels 4, 6, 7: desert tileset.
- Act 2 levels 6 and 10: desert tileset and backgrounds; level 10 also has missing train decorations.
- Act 2 levels 9, 11, 12: bank or train decoration textures. Levels using `AnimatedWheel.tscn` inherit its missing texture.
- Act 3 levels 2, 5, 11 and all three tutorial scenes: `DecorationSheet.png`. No file with that name was found, so its replacement needs identification.
- Act 3 level 12: saloon texture.
- `Scenes/Objects/Enemies/EnemyBullet.tscn`: bullet texture, plus the broken enemy-bullet script.
- `Scenes/Objects/Decorations/AnimatedWheel.tscn` and `GoldBars.tscn`: moved decoration textures.
- `Scenes/Levels/main_game.tscn` inherits the tutorial dependency errors; enemy scenes inherit the script failures.

## Detailed unresolved references

Paths below are relative to the repository. Replacement candidates are matched by filename; where multiple candidates exist, the intended asset needs to be selected. Project addon configuration is stale but the plugin is disabled, so those entries are not confirmed gameplay failures.

| Referencing file | Missing path | Existing candidate(s) |
| --- | --- | --- |
| `bullet/project.godot:14` | `res://addons/retrograde_image/retrograde-image.json` | No same-name file found |
| `bullet/project.godot:24` | `res://addons/retrograde_image/retrograde-image.json` | No same-name file found |
| `bullet/Scenes/Levels/Act 1/act1_lvl4.tscn:6` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl6.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl7.tscn:7` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl10.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl10.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_4.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_4.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl10.tscn:7` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_2.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_2.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl10.tscn:8` | `res://Assets/Images/Wheel.png` | `bullet/Assets/Images/Decor/Wheel.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl10.tscn:10` | `res://Assets/Images/Rail End.png` | `bullet/Assets/Images/Decor/Rail End.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl10.tscn:11` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl10.tscn:13` | `res://Assets/Images/Rail.png` | `bullet/Assets/Images/Decor/Rail.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl11.tscn:10` | `res://Assets/Images/Rail.png` | `bullet/Assets/Images/Decor/Rail.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl11.tscn:13` | `res://Assets/Images/TrainChain.png` | `bullet/Assets/Images/Decor/TrainChain.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl12.tscn:9` | `res://Assets/Images/Rail.png` | `bullet/Assets/Images/Decor/Rail.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl12.tscn:13` | `res://Assets/Images/TrainChain.png` | `bullet/Assets/Images/Decor/TrainChain.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl6.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_3.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_3.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl6.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl6.tscn:6` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl9.tscn:8` | `res://Assets/Images/Bank.png` | `bullet/Assets/Images/Decor/Bank.png` |
| `bullet/Scenes/Levels/Act 2/act2_lvl9.tscn:9` | `res://Assets/Images/Bank(Formal).png` | `bullet/Assets/Images/Decor/Bank(Formal).png` |
| `bullet/Scenes/Levels/Act 3/act3_lvl11.tscn:8` | `res://Assets/Tilesets/StrangeCowboy/Decorations/DecorationSheet.png` | No same-name file found |
| `bullet/Scenes/Levels/Act 3/act3_lvl12.tscn:18` | `res://Assets/Images/salun.png` | `bullet/Assets/Images/Decor/salun.png` |
| `bullet/Scenes/Levels/Act 3/act3_lvl2.tscn:9` | `res://Assets/Tilesets/StrangeCowboy/Decorations/DecorationSheet.png` | No same-name file found |
| `bullet/Scenes/Levels/Act 3/act3_lvl5.tscn:10` | `res://Assets/Tilesets/StrangeCowboy/Decorations/DecorationSheet.png` | No same-name file found |
| `bullet/Scenes/Levels/Tutorial/tut_01.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Decorations/DecorationSheet.png` | No same-name file found |
| `bullet/Scenes/Levels/Tutorial/tut_02.tscn:9` | `res://Assets/Tilesets/StrangeCowboy/Decorations/DecorationSheet.png` | No same-name file found |
| `bullet/Scenes/Levels/Tutorial/tut_03.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Decorations/DecorationSheet.png` | No same-name file found |
| `bullet/Scenes/Objects/Decorations/AnimatedWheel.tscn:3` | `res://Assets/Images/WheelAnimation.png` | `bullet/Assets/Images/Decor/WheelAnimation.png` |
| `bullet/Scenes/Objects/Decorations/GoldBars.tscn:3` | `res://Assets/Images/Gold Bars.png` | `bullet/Assets/Images/Decor/Gold Bars.png` |
| `bullet/Scenes/Objects/Enemies/EnemyBullet.tscn:3` | `res://Assets/Tilesets/StrangeCowboy/Player/Bullet.png` | `bullet/Assets/Images/Bullets/Bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:23` | `res://Assets/Images/ChamberBullets/regular_bullet.png` | `bullet/Assets/Images/Chamber/regular_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:28` | `res://Assets/Images/ChamberBullets/rubber_bullet.png` | `bullet/Assets/Images/Chamber/rubber_bullet.png`<br>`bullet/Assets/Images/SceneBullets/rubber_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:33` | `res://Assets/Images/ChamberBullets/piercing_bullet.png` | `bullet/Assets/Images/Chamber/piercing_bullet.png`<br>`bullet/Assets/Images/SceneBullets/piercing_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:38` | `res://Assets/Images/ChamberBullets/fly_bullet.png` | `bullet/Assets/Images/Chamber/fly_bullet.png`<br>`bullet/Assets/Images/SceneBullets/fly_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:43` | `res://Assets/Images/ChamberBullets/swap_bullet.png` | `bullet/Assets/Images/Chamber/swap_bullet.png`<br>`bullet/Assets/Images/SceneBullets/swap_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:48` | `res://Assets/Images/ChamberBullets/fire_bullet.png` | `bullet/Assets/Images/Chamber/fire_bullet.png`<br>`bullet/Assets/Images/SceneBullets/fire_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:53` | `res://Assets/Images/ChamberBullets/key_bullet.png` | `bullet/Assets/Images/Chamber/key_bullet.png`<br>`bullet/Assets/Images/SceneBullets/key_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:58` | `res://Assets/Images/ChamberBullets/ice_bullet.png` | `bullet/Assets/Images/Chamber/ice_bullet.png`<br>`bullet/Assets/Images/SceneBullets/ice_bullet.png` |
| `bullet/Scenes/UI/Chamber/bullet_chamber.gd:63` | `res://Assets/Images/ChamberBullets/sad_bullet.png` | `bullet/Assets/Images/Chamber/sad_bullet.png` |
| `bullet/Scenes/UI/MainMenu/profile_menu.tscn:5` | `res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/PauseMenu.png` |
| `bullet/Scripts/cutscene.gd:33` | `res://Scenes/main_game.tscn` | `bullet/Scenes/Levels/main_game.tscn` |
| `bullet/Scripts/enemy.gd:24` | `res://Assets/SoundEffects/PiercingEnemyDeath.wav` | `bullet/Assets/SoundEffects/BulletSounds/PiercingEnemyDeath.wav` |
| `bullet/Scripts/enemy_bullet.gd:7` | `res://Assets/SoundEffects/NormalRicochet.wav` | `bullet/Assets/SoundEffects/BulletSounds/NormalRicochet.wav` |
| `bullet/Scripts/settings_manager.gd:34` | `res://Assets/Tilesets/StrangeCowboy/Player/reticle_norm.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Player/reticle_norm.png` |
| `bullet/Scripts/settings_manager.gd:35` | `res://Assets/Tilesets/StrangeCowboy/Player/reticle_clicked.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Player/reticle_clicked.png` |
| `bullet/Scripts/settings_manager.gd:97` | `res://Scenes/Cutscene.tscn` | `bullet/Scenes/Levels/Cutscene.tscn` |
| `bullet/Scripts/MainMenu/menu.gd:5` | `res://Scenes/playground.tscn` | `bullet/Scenes/Levels/playground.tscn` |
| `bullet/Scripts/MainMenu/menu.gd:59` | `res://Scenes/main_game.tscn` | `bullet/Scenes/Levels/main_game.tscn` |
| `bullet/Scripts/MainMenu/menu.gd:61` | `res://Scenes/Cutscene.tscn` | `bullet/Scenes/Levels/Cutscene.tscn` |
| `bullet/Scripts/Menus/act_score_screen.gd:119` | `res://Scenes/main_game.tscn` | `bullet/Scenes/Levels/main_game.tscn` |
| `bullet/Scripts/Menus/act_select.gd:142` | `res://Scenes/main_game.tscn` | `bullet/Scenes/Levels/main_game.tscn` |
| `bullet/Scripts/Menus/OptionsMenu/key_bindings.gd:7` | `res://Assets/Tilesets/KeyboardAndMouse/MainMenuBackground.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/MainMenuBackground.png` |
| `bullet/Scripts/Menus/OptionsMenu/key_bindings.gd:8` | `res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/PauseMenu.png` |
| `bullet/Tests/act_unlocks_test.gd:103` | `res://Scenes/act_select.tscn` | `bullet/Scenes/Levels/act_select.tscn` |

## Stale paths with matching resource IDs

There are 213 additional stale path references with resource IDs found in current files. Many still loaded through Godot's UID resolution. These are not counted as confirmed failures, but the stored paths should be updated. The current working-tree scene moves are only part of the problem: many stale asset paths also exist in the committed files.

| Referencing file | Old path | Current UID target |
| --- | --- | --- |
| `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres:3` | `res://Assets/Tilesets/StrangeCowboy/Tilemap/GroundTilemap.png` | `bullet/Assets/Images/Tilemap/Terrain/GroundTilemap.png.import` |
| `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres:4` | `res://Assets/Images/Abyss/abyss_spritesheet.png` | `bullet/Assets/Images/Tilemap/Abyss/abyss_spritesheet.png.import` |
| `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres:5` | `res://Assets/Tilesets/wood_tileset.png` | `bullet/Assets/Images/Tilemap/Terrain/wood_tileset.png.import` |
| `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres:6` | `res://Assets/Tilesets/stone_tileset.png` | `bullet/Assets/Images/Tilemap/Terrain/stone_tileset.png.import` |
| `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres:7` | `res://Assets/Tilesets/metal_tileset.png` | `bullet/Assets/Images/Tilemap/Terrain/metal_tileset.png.import` |
| `bullet/Scenes/Debug/debug_room.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Debug/debug_room.tscn:8` | `res://Scenes/Objects/Key.tscn` | `bullet/Scenes/Objects/PowerUps/Key.tscn` |
| `bullet/Scenes/Debug/debug_room_2.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Debug/debug_room_3.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Debug/debug_room_3.tscn:7` | `res://Scenes/Objects/Key.tscn` | `bullet/Scenes/Objects/PowerUps/Key.tscn` |
| `bullet/Scenes/Debug/debug_room_4.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/playground.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl1.tscn:5` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl10.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl11.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl12.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 1/act1_lvl12.tscn:5` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl12.tscn:8` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_5.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_5.png.import` |
| `bullet/Scenes/Levels/Act 1/act1_lvl2.tscn:5` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl3.tscn:5` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl5.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl8.tscn:5` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 1/act1_lvl9.tscn:7` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl1.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl1.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_3.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_3.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl1.tscn:7` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl11.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl11.tscn:7` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_3.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_3.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl11.tscn:8` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_2.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_2.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl11.tscn:9` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl12.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl12.tscn:7` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_3.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_3.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl12.tscn:8` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_2.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_2.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl12.tscn:10` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl2.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl2.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_3.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_3.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl2.tscn:6` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl3.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl3.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_4.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_4.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl3.tscn:7` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl4.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_3.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_3.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl4.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl4.tscn:6` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl5.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl5.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_5.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_5.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl5.tscn:7` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl8.tscn:8` | `res://Assets/Images/Tilemap/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 2/act2_lvl9.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl9.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_3.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_3.png.import` |
| `bullet/Scenes/Levels/Act 2/act2_lvl9.tscn:7` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 3/act3_lvl1.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl1.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_2.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_2.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl1.tscn:6` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 3/act3_lvl11.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl11.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_5.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_5.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl11.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_2.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_2.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl11.tscn:7` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 3/act3_lvl12.tscn:6` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 3/act3_lvl12.tscn:15` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl12.tscn:16` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_4.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_4.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl12.tscn:17` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_1.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_1.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl2.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl2.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_4.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_4.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl2.tscn:7` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_1.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_1.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl2.tscn:8` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Act 3/act3_lvl5.tscn:5` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_0.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_0.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl5.tscn:6` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_2.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_2.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl5.tscn:7` | `res://Assets/Tilesets/StrangeCowboy/Backgrounds/Background_ParallaxLayer_1.png` | `bullet/Assets/Images/Backgrounds/Background_ParallaxLayer_1.png.import` |
| `bullet/Scenes/Levels/Act 3/act3_lvl5.tscn:9` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Tutorial/tut_01.tscn:5` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Tutorial/tut_02.tscn:4` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Levels/Tutorial/tut_03.tscn:5` | `res://Assets/Tilesets/desert_tileset.tres` | `bullet/Assets/Images/Tilemap/Terrain/desert_tileset.tres` |
| `bullet/Scenes/Objects/Fuse.tscn:4` | `res://Assets/Tilesets/fuse_tileset.tres` | `bullet/Assets/Images/Tilemap/Object/fuse_tileset.tres` |
| `bullet/Scenes/Objects/MouseReticle.tscn:3` | `res://Assets/Tilesets/StrangeCowboy/Player/ReticleSheet.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Player/ReticleSheet.png.import` |
| `bullet/Scenes/Objects/Rope.tscn:4` | `res://Assets/Tilesets/rope_tileset.tres` | `bullet/Assets/Images/Tilemap/Object/rope_tileset.tres` |
| `bullet/Scenes/Objects/Spikes.tscn:3` | `res://Assets/Tilesets/StrangeCowboy/Items/Spike.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Items/Spike.png.import` |
| `bullet/Scenes/Objects/Breakables/target.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Items/Target.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Items/Target.png.import` |
| `bullet/Scenes/Objects/Enemies/outlaw.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Character/Outlaw/OutlawFullSheet.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Character/Outlaw/OutlawFullSheet.png.import` |
| `bullet/Scenes/Objects/Player/player.tscn:4` | `res://Assets/Tilesets/StrangeCowboy/Player/PlayerSheet.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Player/PlayerSheet.png.import` |
| `bullet/Scenes/Objects/Player/revolver.tscn:3` | `res://Assets/Tilesets/StrangeCowboy/Player/RevolverSheetAnimated.png` | `bullet/Assets/TO BE REPLACED/StrangeCowboy/Player/RevolverSheetAnimated.png.import` |
| `bullet/Scenes/UI/act_score_screen.tscn:3` | `res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/PauseMenu.png.import` |
| `bullet/Scenes/UI/act_score_screen.tscn:5` | `res://Assets/Tilesets/KeyboardAndMouse/MainMenuBackground.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/MainMenuBackground.png.import` |
| `bullet/Scenes/UI/temp_score_scene.tscn:3` | `res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/PauseMenu.png.import` |
| `bullet/Scenes/UI/temp_score_scene.tscn:5` | `res://Assets/Tilesets/KeyboardAndMouse/MainMenuBackground.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/MainMenuBackground.png.import` |
| `bullet/Scenes/UI/Controls/0.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/0.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/0.png.import` |
| `bullet/Scenes/UI/Controls/1.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/1.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/1.png.import` |
| `bullet/Scenes/UI/Controls/2.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/2.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/2.png.import` |
| `bullet/Scenes/UI/Controls/3.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/3.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/3.png.import` |
| `bullet/Scenes/UI/Controls/4.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/4.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/4.png.import` |
| `bullet/Scenes/UI/Controls/5.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/5.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/5.png.import` |
| `bullet/Scenes/UI/Controls/6.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/6.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/6.png.import` |
| `bullet/Scenes/UI/Controls/7.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/7.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/7.png.import` |
| `bullet/Scenes/UI/Controls/8.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/8.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/8.png.import` |
| `bullet/Scenes/UI/Controls/9.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/9.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/9.png.import` |
| `bullet/Scenes/UI/Controls/A.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/a.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/a.png.import` |
| `bullet/Scenes/UI/Controls/Alt.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/alt.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/alt.png.import` |
| `bullet/Scenes/UI/Controls/Apostrophe.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/apostrophe.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/apostrophe.png.import` |
| `bullet/Scenes/UI/Controls/B.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/b.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/b.png.import` |
| `bullet/Scenes/UI/Controls/BackSlash.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/back_slash.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/back_slash.png.import` |
| `bullet/Scenes/UI/Controls/Backspace.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/backspace.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/backspace.png.import` |
| `bullet/Scenes/UI/Controls/BracketLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/bracket_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/bracket_left.png.import` |
| `bullet/Scenes/UI/Controls/BracketRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/bracket_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/bracket_right.png.import` |
| `bullet/Scenes/UI/Controls/C.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/c.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/c.png.import` |
| `bullet/Scenes/UI/Controls/Comma.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/comma.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/comma.png.import` |
| `bullet/Scenes/UI/Controls/ControllerA.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/a.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/a.png.import` |
| `bullet/Scenes/UI/Controls/ControllerB.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/b.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/b.png.import` |
| `bullet/Scenes/UI/Controls/ControllerDPadDown.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/d_pad_down.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/d_pad_down.png.import` |
| `bullet/Scenes/UI/Controls/ControllerDPadLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/d_pad_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/d_pad_left.png.import` |
| `bullet/Scenes/UI/Controls/ControllerDPadRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/d_pad_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/d_pad_right.png.import` |
| `bullet/Scenes/UI/Controls/ControllerDPadUp.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/d_pad_up.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/d_pad_up.png.import` |
| `bullet/Scenes/UI/Controls/ControllerHome.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/home.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/home.png.import` |
| `bullet/Scenes/UI/Controls/ControllerL1.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l1.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l1.png.import` |
| `bullet/Scenes/UI/Controls/ControllerL2.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l2.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l2.png.import` |
| `bullet/Scenes/UI/Controls/ControllerL3.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l3.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l3.png.import` |
| `bullet/Scenes/UI/Controls/ControllerL4.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l4.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l4.png.import` |
| `bullet/Scenes/UI/Controls/ControllerL5.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l5.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l5.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLP.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/lp.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/lp.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickDown.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_down.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_down.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickDownLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_down_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_down_left.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickDownRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_down_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_down_right.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_left.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_right.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickUp.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_up.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_up.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickUpLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_up_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_up_left.png.import` |
| `bullet/Scenes/UI/Controls/ControllerLStickUpRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/l_stick_up_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/l_stick_up_right.png.import` |
| `bullet/Scenes/UI/Controls/ControllerMenu.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/menu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/menu.png.import` |
| `bullet/Scenes/UI/Controls/ControllerR1.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r1.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r1.png.import` |
| `bullet/Scenes/UI/Controls/ControllerR2.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r2.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r2.png.import` |
| `bullet/Scenes/UI/Controls/ControllerR3.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r3.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r3.png.import` |
| `bullet/Scenes/UI/Controls/ControllerR4.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r4.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r4.png.import` |
| `bullet/Scenes/UI/Controls/ControllerR5.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r5.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r5.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRP.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/rp.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/rp.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickDown.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_down.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_down.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickDownLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_down_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_down_left.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickDownRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_down_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_down_right.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_left.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_right.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickUp.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_up.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_up.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickUpLeft.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_up_left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_up_left.png.import` |
| `bullet/Scenes/UI/Controls/ControllerRStickUpRight.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/r_stick_up_right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/r_stick_up_right.png.import` |
| `bullet/Scenes/UI/Controls/ControllerShare.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/share.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/share.png.import` |
| `bullet/Scenes/UI/Controls/ControllerView.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/view.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/view.png.import` |
| `bullet/Scenes/UI/Controls/ControllerX.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/x.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/x.png.import` |
| `bullet/Scenes/UI/Controls/ControllerY.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/controller/vertical_animation/y.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/controller/vertical_animation/y.png.import` |
| `bullet/Scenes/UI/Controls/Ctrl.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/ctrl.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/ctrl.png.import` |
| `bullet/Scenes/UI/Controls/D.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/d.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/d.png.import` |
| `bullet/Scenes/UI/Controls/Delete.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/delete.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/delete.png.import` |
| `bullet/Scenes/UI/Controls/Down.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/down.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/down.png.import` |
| `bullet/Scenes/UI/Controls/E.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/e.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/e.png.import` |
| `bullet/Scenes/UI/Controls/End.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/end.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/end.png.import` |
| `bullet/Scenes/UI/Controls/Enter.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/enter.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/enter.png.import` |
| `bullet/Scenes/UI/Controls/Equal.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/equal.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/equal.png.import` |
| `bullet/Scenes/UI/Controls/Escape.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/escape.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/escape.png.import` |
| `bullet/Scenes/UI/Controls/F.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f.png.import` |
| `bullet/Scenes/UI/Controls/F1.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f1.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f1.png.import` |
| `bullet/Scenes/UI/Controls/F10.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f10.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f10.png.import` |
| `bullet/Scenes/UI/Controls/F11.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f11.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f11.png.import` |
| `bullet/Scenes/UI/Controls/F12.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f12.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f12.png.import` |
| `bullet/Scenes/UI/Controls/F2.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f2.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f2.png.import` |
| `bullet/Scenes/UI/Controls/F3.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f3.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f3.png.import` |
| `bullet/Scenes/UI/Controls/F4.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f4.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f4.png.import` |
| `bullet/Scenes/UI/Controls/F5.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f5.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f5.png.import` |
| `bullet/Scenes/UI/Controls/F6.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f6.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f6.png.import` |
| `bullet/Scenes/UI/Controls/F7.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f7.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f7.png.import` |
| `bullet/Scenes/UI/Controls/F8.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f8.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f8.png.import` |
| `bullet/Scenes/UI/Controls/F9.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/f9.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/f9.png.import` |
| `bullet/Scenes/UI/Controls/G.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/g.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/g.png.import` |
| `bullet/Scenes/UI/Controls/H.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/h.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/h.png.import` |
| `bullet/Scenes/UI/Controls/Home.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/home.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/home.png.import` |
| `bullet/Scenes/UI/Controls/I.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/i.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/i.png.import` |
| `bullet/Scenes/UI/Controls/Insert.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/insert.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/insert.png.import` |
| `bullet/Scenes/UI/Controls/J.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/j.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/j.png.import` |
| `bullet/Scenes/UI/Controls/K.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/k.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/k.png.import` |
| `bullet/Scenes/UI/Controls/L.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/l.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/l.png.import` |
| `bullet/Scenes/UI/Controls/Left.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/left.png.import` |
| `bullet/Scenes/UI/Controls/LeftClick.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/mouse/vertical_animation/left.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/mouse/vertical_animation/left.png.import` |
| `bullet/Scenes/UI/Controls/M.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/m.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/m.png.import` |
| `bullet/Scenes/UI/Controls/MiddleClick.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/mouse/vertical_animation/middle.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/mouse/vertical_animation/middle.png.import` |
| `bullet/Scenes/UI/Controls/Minus.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/minus.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/minus.png.import` |
| `bullet/Scenes/UI/Controls/N.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/n.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/n.png.import` |
| `bullet/Scenes/UI/Controls/O.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/o.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/o.png.import` |
| `bullet/Scenes/UI/Controls/P.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/p.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/p.png.import` |
| `bullet/Scenes/UI/Controls/PageDown.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/page_down.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/page_down.png.import` |
| `bullet/Scenes/UI/Controls/PageUp.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/page_up.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/page_up.png.import` |
| `bullet/Scenes/UI/Controls/Pause.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/pause.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/pause.png.import` |
| `bullet/Scenes/UI/Controls/Period.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/period.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/period.png.import` |
| `bullet/Scenes/UI/Controls/Print.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/print.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/print.png.import` |
| `bullet/Scenes/UI/Controls/Q.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/q.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/q.png.import` |
| `bullet/Scenes/UI/Controls/QuestionMark.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/question_mark.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/question_mark.png.import` |
| `bullet/Scenes/UI/Controls/R.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/r.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/r.png.import` |
| `bullet/Scenes/UI/Controls/Right.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/right.png.import` |
| `bullet/Scenes/UI/Controls/RightClick.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/mouse/vertical_animation/right.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/mouse/vertical_animation/right.png.import` |
| `bullet/Scenes/UI/Controls/S.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/s.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/s.png.import` |
| `bullet/Scenes/UI/Controls/SemiColon.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/semi_colon.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/semi_colon.png.import` |
| `bullet/Scenes/UI/Controls/Shift.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/shift.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/shift.png.import` |
| `bullet/Scenes/UI/Controls/Slash.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/slash.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/slash.png.import` |
| `bullet/Scenes/UI/Controls/Space.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/space.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/space.png.import` |
| `bullet/Scenes/UI/Controls/T.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/t.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/t.png.import` |
| `bullet/Scenes/UI/Controls/Tab.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/tab.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/tab.png.import` |
| `bullet/Scenes/UI/Controls/Tilde.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/tilde.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/tilde.png.import` |
| `bullet/Scenes/UI/Controls/U.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/u.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/u.png.import` |
| `bullet/Scenes/UI/Controls/Up.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/up.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/up.png.import` |
| `bullet/Scenes/UI/Controls/V.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/v.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/v.png.import` |
| `bullet/Scenes/UI/Controls/W.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/w.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/w.png.import` |
| `bullet/Scenes/UI/Controls/WheelDown.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/mouse/vertical_animation/wheel_down.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/mouse/vertical_animation/wheel_down.png.import` |
| `bullet/Scenes/UI/Controls/WheelUp.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/mouse/vertical_animation/wheel_up.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/mouse/vertical_animation/wheel_up.png.import` |
| `bullet/Scenes/UI/Controls/X.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/x.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/x.png.import` |
| `bullet/Scenes/UI/Controls/Y.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/y.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/y.png.import` |
| `bullet/Scenes/UI/Controls/Z.tscn:4` | `res://Assets/Tilesets/KeyboardAndMouse/keyboard/vertical_animation/z.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/keyboard/vertical_animation/z.png.import` |
| `bullet/Scenes/UI/MainMenu/options.tscn:6` | `res://Assets/Tilesets/KeyboardAndMouse/MainMenuBackground.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/MainMenuBackground.png.import` |
| `bullet/Scenes/UI/MainMenu/options.tscn:11` | `res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/PauseMenu.png.import` |
| `bullet/Scenes/UI/PauseMenu/options_pause_menu.tscn:8` | `res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/PauseMenu.png.import` |
| `bullet/Scenes/UI/PauseMenu/pause_menu.tscn:7` | `res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png` | `bullet/Assets/Images/Tilemap/KeyboardAndMouse/PauseMenu.png.import` |

Raw engine output: [engine.log](engine.log). Audit loader: [check.gd](check.gd).

The log also contains a system certificate-store error unrelated to the moved files.
