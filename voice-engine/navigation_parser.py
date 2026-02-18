"""
MiDAS AI - Navigation Command Parser
Parses natural language navigation commands into AppleScript calls

Built by Jarvis & Adam - February 2026
"""

import json
import re
import subprocess
from pathlib import Path

class NavigationParser:
    def __init__(self):
        self.commands_file = Path(__file__).parent / "navigation_commands.json"
        self.script_dir = Path(__file__).parent.parent / "logic-automation"
        self.load_commands()
    
    def load_commands(self):
        """Load command patterns from JSON"""
        with open(self.commands_file, 'r') as f:
            self.commands = json.load(f)
        
        self.fuzzy_amounts = self.commands.get('fuzzy_amounts', {})
        self.common_sections = self.commands.get('common_sections', {})
    
    def parse_amount(self, amount_str):
        """Convert amount string to number"""
        if not amount_str:
            return None
        
        amount_str = amount_str.lower().strip()
        amount_str = amount_str.replace('bars', '').replace('bar', '').strip()
        
        # Check fuzzy amounts
        if amount_str in self.fuzzy_amounts:
            return self.fuzzy_amounts[amount_str]
        
        # Try to parse as number
        try:
            return int(amount_str)
        except:
            return None
    
    def normalize_section_name(self, section):
        """Convert common section name variations to canonical names"""
        section_lower = section.lower().strip()
        
        for canonical, variations in self.common_sections.items():
            if section_lower in variations:
                return canonical
        
        return section_lower
    
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
                regex_pattern = re.escape(pattern)
                regex_pattern = regex_pattern.replace(r'\{amount\}', r'(?P<amount>[\d\s]+?)')
                regex_pattern = regex_pattern.replace(r'\{marker\}', r'(?P<marker>[\w\s]+)')
                regex_pattern = regex_pattern.replace(r'\{start_marker\}', r'(?P<start_marker>[\w\s]+?)')
                regex_pattern = regex_pattern.replace(r'\{end_marker\}', r'(?P<end_marker>[\w\s]+)')
                regex_pattern = regex_pattern.replace(r'\{name\}', r'(?P<name>[\w\s]+)')
                regex_pattern = regex_pattern.replace(r'\{start\}', r'(?P<start>\d+)')
                regex_pattern = regex_pattern.replace(r'\{end\}', r'(?P<end>\d+)')
                regex_pattern = regex_pattern.replace(r'\{bpm\}', r'(?P<bpm>\d+)')
                regex_pattern = regex_pattern.replace(r'\{number\}', r'(?P<number>\d+)')
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
            if cmd_type in ['fuzzy_amounts', 'common_sections']:
                continue  # Skip metadata
            
            patterns = cmd_data.get('patterns', [])
            match = self.match_pattern(text, patterns)
            
            if match is not None:
                return self.build_command(cmd_type, match, cmd_data, text)
        
        return (False, None, None, f"Unknown navigation command: {text}")
    
    def build_command(self, cmd_type, params, cmd_data, original_text=''):
        """Build AppleScript command from parsed params"""
        script = cmd_data.get('script', 'navigation.scpt')
        script_path = self.script_dir / script
        
        # Transport commands
        if cmd_type == 'transport':
            text_lower = original_text.lower()
            
            if any(x in text_lower for x in ['play', 'start']):
                if 'pause' in text_lower:
                    return (True, 'toggle-play', [script_path, 'toggle-play'],
                            "Toggling playback")
                else:
                    return (True, 'play', [script_path, 'play'],
                            "Playing")
            elif 'stop' in text_lower:
                return (True, 'stop', [script_path, 'stop'],
                        "Stopping")
            elif 'pause' in text_lower:
                return (True, 'pause', [script_path, 'pause'],
                        "Pausing")
            elif any(x in text_lower for x in ['rewind', 'beginning', 'start over', 'top']):
                return (True, 'rewind-start', [script_path, 'rewind-start'],
                        "Rewinding to start")
        
        # Jump forward/back
        elif cmd_type == 'jump_forward':
            amount = params.get('amount')
            amount = self.parse_amount(amount) if amount else cmd_data.get('default_amount', 4)
            return (True, 'fast-forward', [script_path, 'fast-forward', str(amount)],
                    f"Jumping forward {amount} bars")
        
        elif cmd_type == 'jump_back':
            amount = params.get('amount')
            amount = self.parse_amount(amount) if amount else cmd_data.get('default_amount', 4)
            return (True, 'rewind', [script_path, 'rewind', str(amount)],
                    f"Jumping back {amount} bars")
        
        # Marker navigation
        elif cmd_type == 'jump_to_marker':
            marker = params.get('marker')
            marker = self.normalize_section_name(marker)
            return (True, 'jump-marker', [script_path, 'jump-marker', marker],
                    f"Jumping to {marker}")
        
        elif cmd_type == 'marker_nav':
            text_lower = original_text.lower()
            
            if 'next' in text_lower:
                return (True, 'next-marker', [script_path, 'next-marker'],
                        "Jumping to next marker")
            elif 'previous' in text_lower or 'last' in text_lower:
                return (True, 'prev-marker', [script_path, 'prev-marker'],
                        "Jumping to previous marker")
            elif params.get('number'):
                num = int(params['number'])
                return (True, 'jump-marker-num', [script_path, 'jump-marker-num', str(num)],
                        f"Jumping to marker {num}")
        
        # Create marker
        elif cmd_type == 'create_marker':
            name = params.get('name')
            name = self.normalize_section_name(name)
            return (True, 'create-marker', [script_path, 'create-marker', name],
                    f"Creating marker: {name}")
        
        # List markers
        elif cmd_type == 'list_markers':
            return (True, 'list-markers', [script_path, 'list-markers'],
                    "Listing markers")
        
        # Loop section (by bars)
        elif cmd_type == 'loop_section':
            start = int(params.get('start', 1))
            end = int(params.get('end', 8))
            return (True, 'set-loop', [script_path, 'set-loop', str(start), str(end)],
                    f"Looping bars {start} to {end}")
        
        # Loop between markers
        elif cmd_type == 'loop_markers':
            start_marker = self.normalize_section_name(params.get('start_marker', ''))
            end_marker = self.normalize_section_name(params.get('end_marker', ''))
            return (True, 'loop-between-markers',
                    [script_path, 'loop-between-markers', start_marker, end_marker],
                    f"Looping {start_marker} to {end_marker}")
        
        # Loop from here
        elif cmd_type == 'loop_from_here':
            amount = params.get('amount')
            amount = self.parse_amount(amount) if amount else cmd_data.get('default_amount', 8)
            return (True, 'loop-from-here', [script_path, 'loop-from-here', str(amount)],
                    f"Looping {amount} bars from here")
        
        # Toggle loop
        elif cmd_type == 'toggle_loop':
            return (True, 'toggle-loop', [script_path, 'toggle-loop'],
                    "Toggling loop")
        
        # Set tempo
        elif cmd_type == 'tempo_set':
            bpm = int(params.get('bpm', 120))
            return (True, 'set-tempo', [script_path, 'set-tempo', str(bpm)],
                    f"Setting tempo to {bpm} BPM")
        
        # Adjust tempo
        elif cmd_type == 'tempo_adjust':
            text_lower = original_text.lower()
            amount = params.get('amount')
            amount = int(amount) if amount else cmd_data.get('default_amount', 5)
            
            is_up = any(x in text_lower for x in ['up', 'faster', 'speed up'])
            if not is_up:
                amount = -amount
            
            return (True, 'adjust-tempo', [script_path, 'adjust-tempo', str(amount)],
                    f"Adjusting tempo by {amount} BPM")
        
        # Query tempo
        elif cmd_type == 'tempo_query':
            return (True, 'get-tempo', [script_path, 'get-tempo'],
                    "Getting tempo")
        
        # Query position
        elif cmd_type == 'position_query':
            return (True, 'get-position', [script_path, 'get-position'],
                    "Getting position")
        
        else:
            return (False, None, None, f"Unknown command type: {cmd_type}")
    
    def execute(self, text):
        """Parse and execute navigation command"""
        success, cmd_type, params, message = self.parse(text)
        
        if not success:
            return {'success': False, 'message': message}
        
        print(f"🎵 {message}")
        
        # Execute AppleScript
        try:
            result = subprocess.run(
                ['osascript'] + params,
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
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
    parser = NavigationParser()
    
    print("🎵 MiDAS AI - Navigation Command Parser")
    print("="*60)
    print()
    
    # Test commands
    test_commands = [
        "play",
        "stop",
        "jump to chorus",
        "loop 8 to 16",
        "loop verse to chorus",
        "forward 4 bars",
        "back 8",
        "set tempo 120",
        "faster 10",
        "what's the tempo",
        "next marker",
        "create marker bridge",
        "loop 8 bars",
        "toggle loop"
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
    print("  parser = NavigationParser()")
    print("  parser.execute('play')")
