#!/usr/bin/env python3
"""
MiDAS - Phase 4: Track Management Voice Command Parser
Parses natural language commands for track organization, grouping, and visual management
Built: February 17, 2026
"""

import json
import re
import subprocess
from pathlib import Path

class TrackParser:
    def __init__(self):
        # Load command patterns
        commands_file = Path(__file__).parent / 'track_commands.json'
        with open(commands_file, 'r') as f:
            self.commands = json.load(f)
        
        # AppleScript file path
        self.script_path = Path(__file__).parent.parent / 'logic-automation' / 'track_management.scpt'
        
    def parse(self, text):
        """Parse natural language command and return AppleScript command"""
        text = text.lower().strip()
        
        # Try each command category
        for category, patterns_list in self.commands.items():
            if category in ['color_names', 'common_track_names']:
                continue
                
            for pattern_group in patterns_list:
                result = self._try_patterns(text, pattern_group)
                if result:
                    return result
        
        return None
    
    def _try_patterns(self, text, pattern_group):
        """Try matching text against a pattern group"""
        patterns = pattern_group['patterns']
        action = pattern_group['action']
        vars_needed = pattern_group.get('vars', [])
        
        for pattern in patterns:
            match_result = self._match_pattern(text, pattern, vars_needed)
            if match_result is not None:  # Changed from 'if match_result:' to handle empty dict {}
                return self._build_command(action, match_result)
        
        return None
    
    def _match_pattern(self, text, pattern, vars_needed):
        """Match text against a single pattern with variables"""
        # Convert pattern to regex
        regex_pattern = pattern
        var_dict = {}
        
        # If no variables, just do exact match
        if not vars_needed:
            if text == pattern:
                return {}
            else:
                return None
        
        # Replace variables with regex captures
        for var in vars_needed:
            if var == 'num':
                # Match track numbers (1-99)
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(\d+)')
            elif var == 'amount':
                # Match amounts (1-20)
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(\d+)')
            elif var == 'start' or var == 'end':
                # Match track range numbers
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(\d+)')
            elif var == 'color':
                # Match color names
                colors = '|'.join(self._get_all_color_names())
                regex_pattern = regex_pattern.replace(f'{{{var}}}', f'({colors})')
            elif var == 'name':
                # Match track names (greedy - captures rest of string)
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(.+)')
        
        # Try to match
        regex_pattern = '^' + regex_pattern + '$'
        match = re.match(regex_pattern, text)
        
        if match:
            # Extract variables
            for i, var in enumerate(vars_needed):
                var_dict[var] = match.group(i + 1)
            return var_dict
        
        return None
    
    def _get_all_color_names(self):
        """Get all valid color names"""
        all_colors = []
        for color_list in self.commands['color_names'].values():
            all_colors.extend(color_list)
        return all_colors
    
    def _normalize_color(self, color_input):
        """Normalize color name to standard color"""
        for standard, variants in self.commands['color_names'].items():
            if color_input.lower() in variants:
                return standard
        return 'red'  # Default
    
    def _build_command(self, action, vars_dict):
        """Build AppleScript command from action and variables"""
        args = []
        
        # Handle different actions
        if action == 'create_audio':
            args = ['create_audio']
        elif action == 'create_midi':
            args = ['create_midi']
        elif action == 'create_aux':
            args = ['create_aux']
        elif action == 'duplicate':
            args = ['duplicate', vars_dict['num']]
        elif action == 'delete':
            args = ['delete', vars_dict['num']]
        elif action == 'rename':
            args = ['rename', vars_dict['num'], vars_dict['name']]
        elif action == 'rename_selected':
            # Rename currently selected track (use track 1 as placeholder)
            args = ['rename', '1', vars_dict['name']]
        elif action == 'group':
            args = ['group', vars_dict['start'], vars_dict['end']]
        elif action == 'group_named':
            args = ['group', vars_dict['start'], vars_dict['end'], vars_dict['name']]
        elif action == 'ungroup':
            args = ['ungroup', vars_dict['num']]
        elif action == 'color':
            color = self._normalize_color(vars_dict['color'])
            args = ['color', vars_dict['num'], color]
        elif action == 'color_selected':
            color = self._normalize_color(vars_dict['color'])
            args = ['color', '1', color]
        elif action == 'hide':
            args = ['hide', vars_dict['num']]
        elif action == 'show':
            args = ['show', vars_dict['num']]
        elif action == 'hide_except':
            args = ['hide_except', vars_dict['num']]
        elif action == 'show_all':
            args = ['show_all']
        elif action == 'lock':
            args = ['lock', vars_dict['num']]
        elif action == 'unlock':
            args = ['unlock', vars_dict['num']]
        elif action == 'move_up':
            args = ['move_up', vars_dict['num'], '1']
        elif action == 'move_down':
            args = ['move_down', vars_dict['num'], '1']
        elif action == 'move_up_amount':
            args = ['move_up', vars_dict['num'], vars_dict['amount']]
        elif action == 'move_down_amount':
            args = ['move_down', vars_dict['num'], vars_dict['amount']]
        elif action == 'move_to_top':
            args = ['move_up', vars_dict['num'], '50']  # Move 50 positions (enough to reach top)
        elif action == 'move_to_bottom':
            args = ['move_down', vars_dict['num'], '50']  # Move 50 positions (enough to reach bottom)
        
        return {
            'action': action,
            'args': args,
            'description': self._describe_action(action, vars_dict)
        }
    
    def _describe_action(self, action, vars_dict):
        """Generate human-readable description of action"""
        if action == 'create_audio':
            return "Creating audio track"
        elif action == 'create_midi':
            return "Creating MIDI instrument track"
        elif action == 'create_aux':
            return "Creating aux track"
        elif action == 'duplicate':
            return f"Duplicating track {vars_dict['num']}"
        elif action == 'delete':
            return f"Deleting track {vars_dict['num']}"
        elif action == 'rename':
            return f"Renaming track {vars_dict['num']} to {vars_dict['name']}"
        elif action == 'rename_selected':
            return f"Renaming selected track to {vars_dict['name']}"
        elif action in ['group', 'group_named']:
            return f"Grouping tracks {vars_dict['start']} to {vars_dict['end']}"
        elif action == 'ungroup':
            return f"Ungrouping folder at track {vars_dict['num']}"
        elif action in ['color', 'color_selected']:
            return f"Coloring track {vars_dict.get('color', 'red')}"
        elif action == 'hide':
            return f"Hiding track {vars_dict['num']}"
        elif action == 'show':
            return f"Showing track {vars_dict['num']}"
        elif action == 'hide_except':
            return f"Hiding all except track {vars_dict['num']}"
        elif action == 'show_all':
            return "Showing all tracks"
        elif action == 'lock':
            return f"Locking track {vars_dict['num']}"
        elif action == 'unlock':
            return f"Unlocking track {vars_dict['num']}"
        elif action in ['move_up', 'move_up_amount']:
            return f"Moving track {vars_dict['num']} up"
        elif action in ['move_down', 'move_down_amount']:
            return f"Moving track {vars_dict['num']} down"
        elif action == 'move_to_top':
            return f"Moving track {vars_dict['num']} to top"
        elif action == 'move_to_bottom':
            return f"Moving track {vars_dict['num']} to bottom"
        return "Executing command"
    
    def execute(self, command):
        """Execute AppleScript command"""
        if not command:
            return {"success": False, "error": "No command parsed"}
        
        try:
            # Build osascript command
            cmd = ['osascript', str(self.script_path)] + command['args']
            
            # Execute
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                return {
                    "success": True,
                    "output": result.stdout.strip(),
                    "description": command['description']
                }
            else:
                return {
                    "success": False,
                    "error": result.stderr.strip(),
                    "description": command['description']
                }
        
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "error": "Command timed out",
                "description": command['description']
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "description": command['description']
            }
    
    def process_voice_command(self, text):
        """Complete pipeline: parse → execute → return result"""
        command = self.parse(text)
        
        if not command:
            return {
                "success": False,
                "error": "Could not understand command",
                "original": text
            }
        
        result = self.execute(command)
        result['original'] = text
        result['action'] = command['action']
        
        return result


# ============================================
# TESTING
# ============================================

def test_parser():
    """Test the track command parser"""
    parser = TrackParser()
    
    test_commands = [
        # Track creation
        "create audio track",
        "new midi track",
        "add instrument",
        "duplicate track 3",
        "delete track 5",
        
        # Track naming
        "rename track 2 to lead vocal",
        "name track 4 drums",
        "call this bass",
        
        # Grouping
        "group tracks 1 to 4",
        "group 5 to 8 as vocals",
        "ungroup track 2",
        
        # Colors
        "color track 3 red",
        "make track 5 blue",
        "paint this green",
        
        # Visibility
        "hide track 7",
        "show track 3",
        "hide all except 2",
        "show all tracks",
        
        # Protection
        "lock track 4",
        "unlock track 6",
        
        # Reordering
        "move track 3 up",
        "move 5 down",
        "move track 2 to top",
        "move 8 to bottom"
    ]
    
    print("=" * 60)
    print("TRACK MANAGEMENT COMMAND PARSER TEST")
    print("=" * 60)
    
    passed = 0
    failed = 0
    
    for cmd_text in test_commands:
        command = parser.parse(cmd_text)
        if command:
            print(f"\n✅ '{cmd_text}'")
            print(f"   Action: {command['action']}")
            print(f"   Args: {command['args']}")
            print(f"   Description: {command['description']}")
            passed += 1
        else:
            print(f"\n❌ '{cmd_text}' - NO MATCH")
            failed += 1
    
    print("\n" + "=" * 60)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)


if __name__ == '__main__':
    test_parser()
