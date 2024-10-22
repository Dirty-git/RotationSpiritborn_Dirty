# RotationSpiritborn_Dirty

## Changelog
 ### v1.1.0
- Added custom enemy weights
- Default enemy weights adjusted (favours elites and bosses for targeting)
- Added readme and changelog

 ### v1.0.0
- Initial release

## Settings

### Main Settings
- **Enable Plugin**: Toggles the entire plugin on/off.
- **Max Targeting Range**: Sets the maximum range for finding targets around the player (1-16 units).
- **Targeting Refresh Interval**: Sets the time between target refresh checks (0.1-1 seconds).
- **Cursor Targeting Radius**: Sets the area size for selecting targets around the cursor (0.1-6 units).
- **Enemy Evaluation Radius**: Sets the area size around an enemy to evaluate if it's the best target (0.1-6 units).

### Custom Enemy Weights
- **Enable Custom Enemy Weights**: Toggles custom weighting for enemy types.
- **Normal Enemy Weight**: Sets the weight for normal enemies (1-10).
- **Elite Enemy Weight**: Sets the weight for elite enemies (1-50).
- **Champion Enemy Weight**: Sets the weight for champion enemies (1-50).
- **Boss Enemy Weight**: Sets the weight for boss enemies (1-100).

### Debug Settings
- **Enable Debug**: Toggles debug features on/off.
- **Display Targets**: Shows visual indicators for different types of targets.
- **Display Max Range**: Draws a circle indicating the max targeting range.
- **Display Melee Range**: Draws a circle indicating the melee range.
- **Display Enemy Circles**: Draws circles around enemies.
- **Display Cursor Target**: Shows the cursor related targeting features.


## Spells
The plugin includes settings for various Spiritborn spells. Each spell typically has the following options:
- Enable/Disable the spell
- Targeting mode
- Evaluation range
- Filter modes (Any Enemy, Elite & Boss Only, Boss Only)
- Minimum number of enemies for AoE spells
- Buff checking options

Spells included:
- Armored Hide
- Scourge
- Ravager
- The Hunter
- Soar
- Vortex
- Crushing Hand
- Counterattack
- The Seeker
- Touch of Death
- Concussive Stomp
- Payback
- Quill Volley
- Rake
- Razor Wings
- Rushing Claw
- Stinger
- The Devourer
- The Protector
- Toxic Skin
- Thrash
- Withering Fist
- Rock Splitter
- Thunderspike
- Evade

## Spell Priority
The priority of spells can be adjusted by changing the sequence of `use_ability` calls in the main.lua file. Spells listed earlier in the sequence have higher priority. To modify the spell priority:

1. Open the main.lua file.
2. Locate the section with `use_ability` calls at the end of on_update() function.
3. Reorder the `use_ability` calls to match your desired priority.
