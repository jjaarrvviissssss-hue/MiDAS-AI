#!/usr/bin/env python3
"""
MiDAS - Phase 7: Session Management Voice Command Parser
Parses natural language commands for session templates and organization
Built: February 18, 2026
"""

import json
import re
import subprocess
from pathlib import Path

class SessionParser:
    def __init__(self):
        # Load command patterns
        commands_file = Path(__file__).parent / 'session_commands.json'
        with open(commands_file, 'r') as f:
            self.commands = json.load(f)
        
        # AppleScript file path
        self.script_path = Path(__file__).parent.parent / 'logic-automation' / 'session_manager.scpt'
        
    def parse(self, text):
        """Parse natural language command and return session command"""
        text = text.lower().strip()
        
        # Try each command category
        for category, patterns_list in self.commands.items():
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
            if match_result is not None:
                return self._build_command(action, match_result)
        
        return None
    
    def _match_pattern(self, text, pattern, vars_needed):
        """Match text against a single pattern with variables"""
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
            if var == 'bpm':
                # Match BPM values (30-300)
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(\d+)')
        
        # Try to match
        regex_pattern = '^' + regex_pattern + '$'
        match = re.match(regex_pattern, text)
        
        if match:
            # Extract variables
            for i, var in enumerate(vars_needed):
                var_dict[var] = match.group(i + 1)
            return var_dict
        
        return None
    
    def _build_command(self, action, vars_dict):
        """Build AppleScript command from action and variables"""
        args = []
        
        # Handle different actions
        if action == 'vocal_session':
            args = ['vocal_session']
        elif action == 'beat_session':
            args = ['beat_session']
        elif action == 'full_song_session':
            args = ['full_song_session']
        elif action == 'organize':
            args = ['organize']
        elif action == 'standard_markers':
            args = ['standard_markers']
        elif action == 'reset_mixer':
            args = ['reset_mixer']
        elif action == 'set_tempo':
            args = ['set_tempo', vars_dict['bpm']]
        
        return {
            'action': action,
            'args': args,
            'description': self._describe_action(action, vars_dict)
        }
    
    def _describe_action(self, action, vars_dict):
        """Generate human-readable description of action"""
        if action == 'vocal_session':
            return "Creating vocal recording session template"
        elif action == 'beat_session':
            return "Creating beat production session template"
        elif action == 'full_song_session':
            return "Creating full song session template"
        elif action == 'organize':
            return "Organizing tracks by type"
        elif action == 'standard_markers':
            return "Creating standard song section markers"
        elif action == 'reset_mixer':
            return "Resetting mixer (clearing solo/mute)"
        elif action == 'set_tempo':
            return f"Setting project tempo to {vars_dict['bpm']} BPM"
        return "Executing session command"
    
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
                timeout=30  # Longer timeout for template creation
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
    """Test the session command parser"""
    parser = SessionParser()
    
    test_commands = [
        # Templates
        "create vocal session",
        "vocal template",
        "create beat session",
        "beat template",
        "create full song session",
        
        # Organization
        "organize tracks",
        "clean up project",
        "create standard markers",
        
        # Quick ops
        "reset mixer",
        "clear mixer",
        "set tempo to 120",
        "tempo 140",
        "90 bpm"
    ]
    
    print("=" * 60)
    print("SESSION MANAGEMENT COMMAND PARSER TEST")
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
