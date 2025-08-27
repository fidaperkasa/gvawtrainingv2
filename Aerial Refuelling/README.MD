# AAR Tracking Script (RefuelTracker) for DCS World

A robust Air-to-Air Refueling (AAR) tracking system for DCS World multiplayer servers. Tracks player refueling performance, provides statistics, and maintains leaderboards.

## Features

- ✅ **Real-time AAR Tracking** - Monitors fuel transfer during air-to-air refueling
- ✅ **Player Statistics** - Personal refueling metrics and grades
- ✅ **Leaderboards** - Top refuelers ranking system  
- ✅ **F10 Radio Menu** - Easy access to stats and leaderboards
- ✅ **Smart Session Management** - Handles multiple refueling contacts per player
- ✅ **Cooldown System** - Prevents duplicate detection between refueling sessions
- ✅ **Comprehensive Logging** - Timestamped log files for each mission session
- ✅ **Multiplayer Ready** - Supports multiple players and aircraft types

## Installation

1. **Download** the `aar.lua` script
2. **Place** in your DCS server's scripts directory:
   ```
   Saved Games/DCS.../Scripts/aar.lua
   ```
3. **Add** to `missionScripting.lua`:
   ```lua
   dofile(lfs.writedir().."/Scripts/aar.lua")
   ```

## Configuration

Edit these values in the script to customize behavior:

```lua
-- Polling interval (seconds)
local MONITOR_INTERVAL = 1

-- Contact confirmation time (seconds of fuel increase)
local CONTACT_CONFIRM = 3

-- Disconnect timeout (seconds without fuel increase)  
local STOP_TOLERANCE = 60

-- Session cleanup interval (seconds)
local SESSION_CLEANUP_INTERVAL = 60
```

## Usage

### In-game Commands
- **F10 Menu** → **AAR Statistics** → **My Statistics** - View personal refueling stats
- **F10 Menu** → **AAR Statistics** → **Leaderboards** - View server leaderboard

### Statistics Tracked
- Total fuel taken (0.0-1.0 scale)
- Number of refueling contacts
- Best single refuel amount
- Total refueling time
- Performance grades (Poor/Good/Excellent)

### Grading System
- **Excellent**: 30+ seconds stable contact
- **Good**: 15-29 seconds stable contact  
- **Poor**: Less than 15 seconds

## Supported Aircraft

### Receivers (All player-flown aircraft)
- all player-controlled aircraft

### Tankers (Automatically detected)
- KC-135 Stratotanker
- KC-130 Hercules
- S-3 Viking
- Il-78 Midas

## Log Files

The script creates timestamped log files in:
```
Saved Games/DCS.../Logs/aar-YYYYMMDD-HHMMSS.log
```

Example: `aar-20250828-143022.log`

Logs include:
- Refueling contact events
- Disconnect events
- Statistics updates
- Session management events

## Technical Details

### Session Management
- Unique sessions per player per refueling contact
- 5-second cooldown between contacts
- Automatic cleanup of stale sessions
- Crash/leave event handling

### Error Handling  
- Robust unit validation with pcall protection
- Invalid object filtering
- Graceful degradation on errors

### To-Do-List
- Integration to DCSServerBot (soon)
- Enhanchment of Calculation for Statistics and Grading

### Performance
- Efficient polling system (1-second intervals)
- Minimal CPU overhead
- Memory-efficient session management

## Version History

### v1.0.3 (Current)
- Fixed duplicate onDisconnect functions
- Added proper session cleanup
- Implemented cooldown system
- Enhanced error handling
- Added timestamped log files

### v1.0.2
- Initial stable release
- Basic refuel tracking
- Statistics system
- F10 menu integration

## Support

For issues or feature requests, please:
1. Check existing log files in `/Logs/` directory
2. Review DCS.log for error messages
3. Ensure proper script installation

## License

This script is provided as-is for the DCS community. Feel free to modify and adapt for your server needs.

## Credits

**Developed by:** EagleEye  
**Version:** 1.0.3 Stable  
**Tested on:** DCS World 2.9+

---

*Happy Refueling! 🛩️➡️⛽*
