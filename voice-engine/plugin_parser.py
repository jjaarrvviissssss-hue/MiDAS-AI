#!/usr/bin/env python3
"""
MiDAS - Phase 5: Plugin Control Voice Command Parser
Parses natural language commands for plugin management
Built: February 18, 2026
"""

import json
import re
import subprocess
from pathlib import Path

class PluginParser:
    def __init__(self):
        # Load command patterns
        commands_file = Path(__file__).parent / 'plugin_commands.json'
        with open(commands_file, 'r') as f:
            self.commands = json.load(f)
        
        # AppleScript file path
        self.script_path = Path(__file__).parent.parent / 'logic-automation' / 'plugin_control.scpt'
        
    def parse(self, text):
        """Parse natural language command and return AppleScript command"""
        text = text.lower().strip()
        
        # Try each command category
        for category, patterns_list in self.commands.items():
            if category in ['common_plugins']:
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
            if var == 'num':
                # Match track numbers (1-99)
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(\d+)')
            elif var == 'slot':
                # Match plugin slot numbers (1-15)
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(\d+)')
            elif var == 'amount':
                # Match amounts (1-20)
                regex_pattern = regex_pattern.replace(f'{{{var}}}', r'(\d+)')
            elif var == 'plugin':
                # Match plugin names (greedy)
                plugin_names = '|'.join(self._get_all_plugin_names())
                regex_pattern = regex_pattern.replace(f'{{{var}}}', f'({plugin_names})')
            elif var == 'name':
                # Match preset names (greedy)
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
    
    def _get_all_plugin_names(self):
        """Get all valid plugin names"""
        all_names = []
        for plugin_list in self.commands['common_plugins'].values():
            all_names.extend(plugin_list)
        return all_names
    
    def _normalize_plugin_name(self, plugin_input):
        """Normalize plugin name to standard name"""
        for standard, variants in self.commands['common_plugins'].items():
            if plugin_input.lower() in variants:
                return standard
        return plugin_input  # Return as-is if not in common list
    
    def _build_command(self, action, vars_dict):
        """Build AppleScript command from action and variables"""
        args = []
        
        # Handle different actions
        if action == 'load_plugin':
            plugin = self._normalize_plugin_name(vars_dict['plugin'])
            args = ['load_plugin', vars_dict['num'], plugin, '1']  # Default to slot 1
        elif action == 'load_plugin_selected':
            plugin = self._normalize_plugin_name(vars_dict['plugin'])
            args = ['load_plugin', '1', plugin, '1']  # Current track, slot 1
        elif action == 'load_logic_plugin':
            # Extract plugin type from pattern
            args = ['load_logic', vars_dict['num'], 'compressor']  # Placeholder
        elif action == 'vocal_chain':
            args = ['vocal_chain', vars_dict['num']]
        elif action == 'drum_bus':
            args = ['drum_bus', vars_dict['num']]
        elif action == 'bypass_plugin':
            args = ['bypass', vars_dict['num'], vars_dict['slot']]
        elif action == 'bypass_all':
            args = ['bypass_all', vars_dict['num']]
        elif action == 'enable_plugin':
            args = ['bypass', vars_dict['num'], vars_dict['slot']]  # Same as bypass (toggle)
        elif action == 'open_plugin':
            args = ['open_plugin', vars_dict['num'], vars_dict['slot']]
        elif action == 'close_plugin':
            args = ['close_plugin']
        elif action == 'adjust_up':
            args = ['adjust', 'up', vars_dict['amount']]
        elif action == 'adjust_down':
            args = ['adjust', 'down', vars_dict['amount']]
        elif action == 'save_preset':
            args = ['save_preset', vars_dict['name']]
        elif action == 'load_preset':
            args = ['load_preset', vars_dict['name']]
        elif action == 'remove_plugin':
            args = ['remove', vars_dict['num'], vars_dict['slot']]
        elif action == 'remove_all':
            args = ['remove_all', vars_dict['num']]
        elif action == 'next_plugin':
            args = ['next']
        elif action == 'previous_plugin':
            args = ['previous']
        elif action == 'show_all_plugins':
            args = ['show_all', vars_dict['num']]
        
        return {
            'action': action,
            'args': args,
            'description': self._describe_action(action, vars_dict)
        }
    
    def _describe_action(self, action, vars_dict):
        """Generate human-readable description of action"""
        if action == 'load_plugin':
            return f"Loading {vars_dict['plugin']} on track {vars_dict['num']}"
        elif action == 'load_plugin_selected':
            return f"Loading {vars_dict['plugin']} on current track"
        elif action == 'vocal_chain':
            return f"Loading vocal chain on track {vars_dict['num']}"
        elif action == 'drum_bus':
            return f"Loading drum bus on track {vars_dict['num']}"
        elif action == 'bypass_plugin':
            return f"Bypassing plugin {vars_dict['slot']} on track {vars_dict['num']}"
        elif action == 'bypass_all':
            return f"Bypassing all plugins on track {vars_dict['num']}"
        elif action == 'enable_plugin':
            return f"Enabling plugin {vars_dict['slot']} on track {vars_dict['num']}"
        elif action == 'open_plugin':
            return f"Opening plugin {vars_dict['slot']} on track {vars_dict['num']}"
        elif action == 'close_plugin':
            return "Closing plugin window"
        elif action == 'adjust_up':
            return f"Increasing parameter by {vars_dict['amount']}"
        elif action == 'adjust_down':
            return f"Decreasing parameter by {vars_dict['amount']}"
        elif action == 'save_preset':
            return f"Saving preset: {vars_dict['name']}"
        elif action == 'load_preset':
            return f"Loading preset: {vars_dict['name']}"
        elif action == 'remove_plugin':
            return f"Removing plugin {vars_dict['slot']} from track {vars_dict['num']}"
        elif action == 'remove_all':
            return f"Removing all plugins from track {vars_dict['num']}"
        elif action == 'next_plugin':
            return "Moving to next plugin"
        elif action == 'previous_plugin':
            return "Moving to previous plugin"
        elif action == 'show_all_plugins':
            return f"Showing all plugins on track {vars_dict['num']}"
        return "Executing plugin command"
    
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
    """Test the plugin command parser"""
    parser = PluginParser()
    
    test_commands = [
        # Plugin loading
        "add compressor to track 3",
        "load eq on track 5",
        "vocal chain on track 2",
        "drum bus on track 7",
        
        # Bypass
        "bypass plugin 2 on track 4",
        "bypass all plugins on track 3",
        "enable plugin 1 on track 5",
        
        # Windows
        "open plugin 2 on track 3",
        "close plugin",
        
        # Parameters
        "increase parameter 5",
        "decrease parameter 3",
        
        # Presets
        "save preset vocal bright",
        "load preset rock drums",
        
        # Removal
        "remove plugin 3 from track 5",
        "remove all plugins from track 2",
        
        # Navigation
        "next plugin",
        "previous plugin",
        "show all plugins on track 4"
    ]
    
    print("=" * 60)
    print("PLUGIN CONTROL COMMAND PARSER TEST")
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
