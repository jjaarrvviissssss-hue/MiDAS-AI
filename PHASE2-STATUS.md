# Phase 2: Mixing Automation - Status

**Started:** February 17, 2026  
**Current Status:** 🟡 Level Control Built (Untested)

---

## ✅ What's Built

### 1. AppleScript Mixing Engine
**File:** `logic-automation/mixing.scpt`

Complete Logic Pro mixing automation:
- ✅ Track selection (by name, partial match)
- ✅ Volume control (absolute & relative dB)
- ✅ Volume presets (loud, normal, quiet, whisper)
- ✅ Mute/unmute tracks
- ✅ Solo/unsolo tracks
- ✅ Batch operations (adjust multiple tracks)
- ✅ Status reporting (current volume, mute, solo state)

**Functions:**
- `adjustTrackVolume(trackName, dbChange)` - Relative adjustment
- `setTrackVolume(trackName, dbValue)` - Absolute level
- `setVolumePreset(trackName, presetName)` - Quick presets
- `muteTrack(trackName)` / `unmuteTrack(trackName)` - Mute control
- `toggleMute(trackName)` - Toggle mute state
- `soloTrack(trackName)` / `unsoloTrack(trackName)` - Solo control
- `unsoloAll()` - Clear all solos
- `adjustGroupVolume(trackPattern, dbChange)` - Batch adjust
- `resetAllVolumes()` - Reset all to 0 dB
- `getTrackStatus(trackName)` - Get current state
- `listAllTracks()` - Show all tracks with levels

### 2. Voice Command Mapping
**File:** `voice-engine/mixing_commands.json`

Natural language command patterns:
- ✅ Volume adjust patterns ("vocals up 3 dB", "drums down a bit")
- ✅ Fuzzy amount parsing ("a bit" = 2 dB, "a lot" = 6 dB)
- ✅ Track name aliases (vocal→vocals, drum→drums, etc.)
- ✅ Mute/solo commands
- ✅ Status queries
- ✅ Batch operations ("all drums up 2")

**Supported Commands:**
- "vocals up 3 dB" / "turn vocals up" / "louder vocals"
- "drums down a bit" / "quieter drums"
- "mute drums" / "silence bass"
- "solo vocals" / "only vocals" / "just vocals"
- "unsolo all" / "bring back everything"
- "set vocals to 0 dB" / "vocals to -6"
- "make drums loud" / "make vocals quiet"
- "all drums up 2" / "guitar tracks down 3"
- "reset all volumes"
- "what's vocals at" / "check drums"
- "list tracks"

### 3. Command Parser
**File:** `voice-engine/mixing_parser.py`

Intelligent command parsing & execution:
- ✅ Pattern matching with variables ({track}, {amount}, {preset})
- ✅ Track name normalization & aliasing
- ✅ Fuzzy amount parsing ("a bit" → 2 dB)
- ✅ Direction detection (up/down from context)
- ✅ AppleScript execution
- ✅ Error handling & feedback
- ✅ Test suite

**Features:**
- Handles natural variations ("vocals up 3" = "turn vocals up 3 dB")
- Supports track name shortcuts ("vocal" → "vocals")
- Intelligent direction parsing (context-aware)
- Batch operations (pattern matching for multiple tracks)

---

## 🧪 Testing Status

### ❌ Not Yet Tested
- Needs Logic Pro with tracks named:
  - "Vocals" or "vocal" track
  - "Drums" or "drum" tracks
  - "Bass" track
  - Other instruments

### ✅ Parser Tested
- All command patterns parse correctly
- Track name normalization works
- Amount parsing handles fuzzy inputs
- Direction detection accurate

---

## 📊 Phase 2 Progress

### Level Control (Current)
- ✅ AppleScript engine (complete)
- ✅ Command mapping (complete)
- ✅ Parser & executor (complete)
- ⏳ Testing with Logic Pro (pending)

### Plugin Loading (Next)
- ⏳ Load plugins by name
- ⏳ Remove/bypass plugins
- ⏳ Preset chains

### Processing Presets (Future)
- ⏳ Vocal chain presets
- ⏳ Drum processing templates
- ⏳ Master bus chains

### Automation Writing (Future)
- ⏳ Write volume automation
- ⏳ Touch/latch modes
- ⏳ Clear automation

---

## 🚀 Next Steps

1. **Test with Logic Pro:**
   ```bash
   cd ~/Developer/MiDAS-AI
   python3 voice-engine/mixing_parser.py  # Test parser
   
   # Then test individual commands:
   osascript logic-automation/mixing.scpt adjust vocals 3
   osascript logic-automation/mixing.scpt mute drums
   osascript logic-automation/mixing.scpt list
   ```

2. **Integrate with Coordinator:**
   Update `coordinator.py` to recognize mixing commands

3. **Voice Control Testing:**
   Test end-to-end: voice → recognizer → parser → Logic

4. **Build Plugin Loading:**
   Next feature in Phase 2

---

## 💡 Usage Examples

Once integrated with voice recognition:

**Volume Control:**
- "Vocals up 3 dB" → Raises vocals by 3 dB
- "Drums down a bit" → Lowers drums by 2 dB
- "Louder vocals" → Raises vocals by default amount (3 dB)
- "Set bass to 0 dB" → Sets bass to unity gain
- "Make drums quiet" → Sets drums to -6 dB preset

**Mute/Solo:**
- "Mute drums" → Mutes drum tracks
- "Solo vocals" → Solos vocal track
- "Unsolo all" → Clears all solos
- "Toggle bass" → Toggles bass mute on/off

**Batch Operations:**
- "All drums up 2" → Raises all tracks with "drums" in name by 2 dB
- "All guitars down 3" → Lowers all guitar tracks by 3 dB

**Status:**
- "What's vocals at" → Reports current vocal level
- "Check drums" → Shows drums status (level, mute, solo)
- "List tracks" → Shows all tracks with levels

---

## 🔧 Technical Details

### dB Conversion
Logic Pro uses 0-1 fader range:
- 0.75 = 0 dB (unity)
- 1.0 = +6 dB (max)
- 0 = -∞ dB (silence)

Formula: `fader = 0.75 + (dB / 24)`

### Track Matching
- Case-insensitive partial matching
- "vocal" matches "Vocals", "Lead Vocal", etc.
- Aliases normalize common variations

### Command Priority
Patterns are tried in order:
1. Specific patterns ("turn {track} up {amount}")
2. General patterns ("{track} up {amount}")
3. Implicit patterns ("louder {track}")

---

## 📈 Stats

**Lines of Code (Phase 2 only):**
- AppleScript: ~400 lines
- Python: ~400 lines
- JSON: ~150 lines
- **Total:** ~950 lines

**Commands Supported:** 50+ variations  
**Time to Build:** ~2 hours

---

Built with 🔷 by Jarvis & Adam
