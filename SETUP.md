# MiDAS AI - Setup & Usage Guide

## Prerequisites

- **macOS** (for Logic Pro and AppleScript integration)
- **Logic Pro** installed
- **Python 3.8+**
- **Microphone** (external recommended for best quality)

---

## Installation

### 1. Install Python Dependencies

```bash
cd ~/Developer/MiDAS-AI
pip3 install -r requirements.txt
```

### 2. Install Audio Drivers (for PyAudio)

```bash
brew install portaudio
```

### 3. Grant Microphone Permissions

- System Settings → Privacy & Security → Microphone
- Enable for Terminal (or your Python environment)

### 4. Configure Logic Pro

**Create tracks:**
1. Open Logic Pro
2. Create a track named **"Record"** (this is where you'll punch vocals)
3. Create a track named **"Vocals"** (this is where takes will be stacked)

**Optional: Customize track names in script:**
Edit `logic-automation/punchobot.scpt`:
```applescript
property recordingTrackName : "Record"  -- Change to your recording track name
property vocalTrackName : "Vocals"      -- Change to your vocal track name
```

---

## Usage

### Start MiDAS

```bash
cd ~/Developer/MiDAS-AI
python3 coordinator.py
```

### Voice Commands (Phase 1)

| Command | Action |
|---------|--------|
| **"start punch"** / **"record"** | Start recording on Record track |
| **"next take"** | Stop, process, move to Vocals track |
| **"keep it"** | Same as "next take" |
| **"trash it"** | Delete current take |
| **"comp mode"** | Switch to comping view |

### Workflow Example

1. **Start MiDAS:**
   ```bash
   python3 coordinator.py
   ```

2. **Set up Logic Pro:**
   - Open your project
   - Set playhead to punch position
   - Ensure "Record" track exists and is selected

3. **Start recording:**
   - Say: **"start punch"**
   - MiDAS starts recording

4. **Finish take:**
   - Say: **"next take"**
   - MiDAS stops, trims, fades, and moves to Vocals track
   - Automatically ready for next punch

5. **Repeat:**
   - Say: **"start punch"** for next take
   - Continue until you have multiple takes stacked

6. **Comp your vocals:**
   - Say: **"comp mode"**
   - Select best parts from each take

---

## Advanced Options

### Use Whisper for Better Accuracy

```bash
# Install Whisper
pip3 install openai-whisper

# Run with Whisper
python3 coordinator.py --whisper
```

### Test Mode (Single Command)

```bash
python3 coordinator.py --test
```

### Customize Fade Length

Edit `punchobot.scpt`:
```applescript
property fadeLength : 0.01  -- Change to desired seconds (0.01 = 10ms)
```

---

## Troubleshooting

### "Microphone not found"
- Check System Settings → Privacy & Security → Microphone
- Ensure Terminal/Python has mic access

### "Logic Pro not responding"
- Ensure Logic Pro is open
- Check AppleScript permissions in System Settings → Privacy & Security → Automation

### "Commands not recognized"
- Speak clearly and at normal volume
- Reduce background noise
- Try `--whisper` flag for better accuracy
- Check calibration: MiDAS auto-calibrates on start

### "Tracks not found"
- Ensure you have tracks named "Record" and "Vocals" in Logic Pro
- Or edit track names in `punchobot.scpt`

---

## What's Next?

### Phase 1 Improvements
- [ ] Better transient detection algorithm
- [ ] Configurable fade curves
- [ ] Auto-return to punch position
- [ ] Visual feedback (GUI)
- [ ] Integration with Jarvis UI

### Phase 2: Mixing Automation
- [ ] Voice-controlled levels
- [ ] Plugin control
- [ ] Automation writing

### Future Phases
See `README.md` for full roadmap.

---

## Development

### Project Structure

```
MiDAS-AI/
├── coordinator.py           # Main entry point
├── logic-automation/
│   └── punchobot.scpt      # Logic Pro automation
├── voice-engine/
│   ├── recognizer.py       # Voice recognition
│   └── commander.py        # Command parser
└── requirements.txt        # Python dependencies
```

### Adding New Commands

1. **Add to AppleScript** (`punchobot.scpt`):
   ```applescript
   on myNewCommand()
       -- Your Logic Pro automation here
   end myNewCommand
   ```

2. **Map in Commander** (`commander.py`):
   ```python
   self.commands = {
       "my command": "myNewCommand",
       # ... existing commands
   }
   ```

3. **Test:**
   ```bash
   python3 coordinator.py --test
   ```

---

## Support

**Issues?** Check the troubleshooting section above.

**Feature requests?** Add to roadmap in `README.md`.

Built with 🔷 by Jarvis & Adam
