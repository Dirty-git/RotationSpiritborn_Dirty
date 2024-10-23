# RotationSpiritborn_Dirty

## Custom Spell Priority

The priority of spells can be adjusted by changing the sequence in spell_priority.lua file. Spells listed earlier in the sequence have higher priority. To modify the spell priority:

1. Open the spell_priority.lua file.
2. Reorder the entries in `spell_priority` list to match your desired priority.
3. Save the file.

Note: This also reorders the spells in the UI. So you can check in-game if the priority is correct. If a spell is not visible, make sure the the name is correctly spelled and in the list.

## Changelog

### v1.2.0

- Added customizable spell priority
- Increased ability usage speed for better performance
- Upgraded targeting system with better score calculation
- Reworked UI
- Added score display to the debug/display_targets

### v1.1.1

- GUI label fixes (all settings should now save correctly)

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
