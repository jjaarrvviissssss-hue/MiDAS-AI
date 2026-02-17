"""
MiDAS AI - Mixing Command Parser
Parses natural language mixing commands into AppleScript calls

Built by Jarvis & Adam - February 2026
"""

import json
import re
import subprocess
from pathlib import Path

class MixingParser:
    def __init__(self):
        self.commands_file = Path(__file__).parent / "mixing_commands.json"
        self.script_dir = Path(__file__).parent.parent / "logic-automation"
        self.load_commands()
    
    def load_commands(self):
        """Load command patterns from JSON"""
        with open(self.commands_file, 'r') as f:
            self.commands = json.load(f)
        
        self.fuzzy_amounts = self.commands.get('fuzzy_amounts', {})
        self.track_aliases = self.commands.get('track_aliases', {})
    
    def normalize_track_name(self, track):
        """Convert aliases to canonical track names"""
        track_lower = track.lower().strip()
        return self.track_aliases.get(track_lower, track_lower)
    
    def parse_amount(self, amount_str):
        """Convert amount string to dB value"""
        if not amount_str:
            return None
        
        # Remove common words
        amount_str = amount_str.lower().strip()
        amount_str = amount_str.replace('db', '').replace('decibel', '').strip()
        
        # Check fuzzy amounts
        if amount_str in self.fuzzy_amounts:
            return self.fuzzy_amounts[amount_str]
        
        # Try to parse as number
        try:
            return float(amount_str)
        except:
            # Default to 3 dB
            return 3
    
    def match_pattern(self, text, patterns):
        """Match text against command patterns"""
        text_lower = text.lower().strip()
        
        for pattern in patterns:
            # Check if pattern has variables
            has_vars = '{' in pattern
            
            if not has_vars:
                # Simple literal match
                if pattern == text_lower:
                    return {}
            else:
                # Convert pattern to regex
                # {track} = capture group for track name
                # {amount} = capture group for amount
                # {group} = capture group for group name
                # {preset} = capture group for preset name
                
                regex_pattern = re.escape(pattern)
                regex_pattern = regex_pattern.replace(r'\{track\}', r'(?P<track>[\w\s-]+?)')
                regex_pattern = regex_pattern.replace(r'\{amount\}', r'(?P<amount>[\w\s.]+?)')
                regex_pattern = regex_pattern.replace(r'\{group\}', r'(?P<group>[\w\s-]+?)')
                regex_pattern = regex_pattern.replace(r'\{preset\}', r'(?P<preset>\w+)')
                regex_pattern = '^' + regex_pattern + '$'
                
                match = re.match(regex_pattern, text_lower, re.IGNORECASE)
                if match:
                    return match.groupdict()
        
        return None
    
    def parse(self, text):
        """
        Parse voice command into AppleScript call
        Returns: (success, command_type, params, message)
        """
        text = text.strip()
        
        # Try each command type
        for cmd_type, cmd_data in self.commands.items():
            if cmd_type in ['fuzzy_amounts', 'track_aliases']:
                continue  # Skip metadata
            
            patterns = cmd_data.get('patterns', [])
            match = self.match_pattern(text, patterns)
            
            if match is not None:  # {} is falsy but valid match
                return self.build_command(cmd_type, match, cmd_data, text)
        
        return (False, None, None, f"Unknown mixing command: {text}")
    
    def build_command(self, cmd_type, params, cmd_data, original_text=''):
        """Build AppleScript command from parsed params"""
        script = cmd_data.get('script', 'mixing.scpt')
        script_path = self.script_dir / script
        
        # Extract and normalize parameters
        track = params.get('track')
        if track:
            track = self.normalize_track_name(track)
        
        amount = params.get('amount')
        if amount:
            amount = self.parse_amount(amount)
        
        group = params.get('group')
        if group:
            group = self.normalize_track_name(group)
        
        preset = params.get('preset')
        
        # Build command based on type
        if cmd_type == 'volume_adjust':
            # Determine direction from original text
            text_lower = original_text.lower()
            is_up = any(word in text_lower for word in ['up', 'louder', 'raise', 'increase', 'bring up', 'turn up'])
            
            if amount is None:
                amount = cmd_data.get('default_amount', 3)
            
            # Apply direction
            if is_up:
                amount = abs(amount)
            else:
                amount = -abs(amount)
            
            return (True, 'adjust', [script_path, 'adjust', track, str(amount)], 
                    f"Adjusting {track} {'+' if amount > 0 else ''}{amount} dB")
        
        elif cmd_type == 'volume_set':
            if preset:
                return (True, 'preset', [script_path, 'preset', track, preset],
                        f"Setting {track} to {preset}")
            else:
                return (True, 'set', [script_path, 'set', track, str(amount)],
                        f"Setting {track} to {amount} dB")
        
        elif cmd_type == 'mute':
            return (True, 'mute', [script_path, 'mute', track],
                    f"Muting {track}")
        
        elif cmd_type == 'unmute':
            return (True, 'unmute', [script_path, 'unmute', track],
                    f"Unmuting {track}")
        
        elif cmd_type == 'toggle_mute':
            return (True, 'toggle-mute', [script_path, 'toggle-mute', track],
                    f"Toggling mute on {track}")
        
        elif cmd_type == 'solo':
            return (True, 'solo', [script_path, 'solo', track],
                    f"Soloing {track}")
        
        elif cmd_type == 'unsolo':
            if 'all' in original_text.lower() or 'everything' in original_text.lower():
                return (True, 'unsolo-all', [script_path, 'unsolo-all'],
                        "Clearing all solos")
            else:
                return (True, 'unsolo', [script_path, 'unsolo', track],
                        f"Unsoloing {track}")
        
        elif cmd_type == 'group_adjust':
            is_up = 'up' in original_text.lower()
            if is_up:
                amount = abs(amount)
            else:
                amount = -abs(amount)
            
            return (True, 'group-adjust', [script_path, 'group-adjust', group, str(amount)],
                    f"Adjusting all {group} tracks {'+' if amount > 0 else ''}{amount} dB")
        
        elif cmd_type == 'reset':
            return (True, 'reset-all', [script_path, 'reset-all'],
                    "Resetting all volumes to 0 dB")
        
        elif cmd_type == 'status':
            return (True, 'status', [script_path, 'status', track],
                    f"Getting status of {track}")
        
        elif cmd_type == 'list_tracks':
            return (True, 'list', [script_path, 'list'],
                    "Listing all tracks")
        
        else:
            return (False, None, None, f"Unknown command type: {cmd_type}")
    
    def execute(self, text):
        """Parse and execute mixing command"""
        success, cmd_type, params, message = self.parse(text)
        
        if not success:
            return {'success': False, 'message': message}
        
        print(f"🎛️  {message}")
        
        # Execute AppleScript
        try:
            result = subprocess.run(
                ['osascript'] + params,
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                # Parse AppleScript return value (if any)
                output = result.stdout.strip()
                return {
                    'success': True,
                    'message': message,
                    'output': output,
                    'command_type': cmd_type
                }
            else:
                error = result.stderr.strip()
                return {
                    'success': False,
                    'message': f"AppleScript error: {error}"
                }
        
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'message': "Command timed out"
            }
        except Exception as e:
            return {
                'success': False,
                'message': f"Execution error: {str(e)}"
            }


# ============================================================
# TEST / DEMO
# ============================================================

if __name__ == "__main__":
    parser = MixingParser()
    
    print("🎛️  MiDAS AI - Mixing Command Parser")
    print("="*60)
    print()
    
    # Test commands
    test_commands = [
        "vocals up 3 dB",
        "drums down a bit",
        "turn bass up 6",
        "louder vocals",
        "mute drums",
        "solo vocals",
        "unsolo all",
        "all drums up 2",
        "set vocals to 0 dB",
        "make drums loud",
        "what's vocals at",
        "list tracks"
    ]
    
    print("Testing command parsing:")
    print()
    
    for cmd in test_commands:
        success, cmd_type, params, message = parser.parse(cmd)
        if success:
            print(f"✅ \"{cmd}\"")
            print(f"   → {message}")
            print(f"   → Command: {cmd_type}")
            print(f"   → Params: {params[2:]}")  # Skip script path
        else:
            print(f"❌ \"{cmd}\"")
            print(f"   → {message}")
        print()
    
    print("="*60)
    print()
    print("To test with Logic Pro:")
    print("  parser = MixingParser()")
    print("  parser.execute('vocals up 3 dB')")
