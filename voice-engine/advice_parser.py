#!/usr/bin/env python3
"""
MiDAS - Phase 6: AI Advice Voice Command Parser
Parses natural language questions for mixing advice
Built: February 18, 2026
"""

import json
import re
import subprocess
from pathlib import Path

class AdviceParser:
    def __init__(self):
        # Load command patterns
        commands_file = Path(__file__).parent / 'advice_commands.json'
        with open(commands_file, 'r') as f:
            self.commands = json.load(f)
        
        # AppleScript file path
        self.script_path = Path(__file__).parent.parent / 'logic-automation' / 'project_analyzer.scpt'
        
    def parse(self, text):
        """Parse natural language question and return advice command"""
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
            if var == 'num':
                # Match track numbers (1-99)
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
        if action == 'check_mix':
            args = ['check_mix']
        elif action == 'analyze_track':
            args = ['analyze_track', vars_dict['num']]
        elif action == 'project_info':
            args = ['project_info']
        elif action == 'vocal_advice':
            args = ['vocal_advice']
        elif action == 'drum_advice':
            args = ['drum_advice']
        elif action == 'bass_advice':
            args = ['bass_advice']
        elif action == 'general_advice':
            args = ['general_advice']
        elif action == 'detect_issues':
            args = ['detect_issues']
        elif action in ['check_clipping', 'check_mud', 'check_harsh']:
            # These map to detect_issues with specific focus
            args = ['detect_issues']
        elif action == 'show_help':
            args = ['show_help']
        
        return {
            'action': action,
            'args': args,
            'description': self._describe_action(action, vars_dict)
        }
    
    def _describe_action(self, action, vars_dict):
        """Generate human-readable description of action"""
        if action == 'check_mix':
            return "Analyzing mix for issues"
        elif action == 'analyze_track':
            return f"Analyzing track {vars_dict['num']}"
        elif action == 'project_info':
            return "Getting project information"
        elif action == 'vocal_advice':
            return "Providing vocal mixing advice"
        elif action == 'drum_advice':
            return "Providing drum mixing advice"
        elif action == 'bass_advice':
            return "Providing bass mixing advice"
        elif action == 'general_advice':
            return "Providing general mixing advice"
        elif action == 'detect_issues':
            return "Detecting common mixing issues"
        elif action == 'check_clipping':
            return "Checking for clipping"
        elif action == 'check_mud':
            return "Checking for muddiness"
        elif action == 'check_harsh':
            return "Checking for harshness"
        elif action == 'show_help':
            return "Showing help"
        return "Processing advice request"
    
    def execute(self, command):
        """Execute advice command"""
        if not command:
            return {"success": False, "error": "No command parsed"}
        
        # Handle help specially (no AppleScript needed)
        if command['action'] == 'show_help':
            return self._show_help()
        
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
    
    def _show_help(self):
        """Show available commands"""
        help_text = """
MiDAS AI - Voice Commands Available:

🎙️ Analysis:
• "analyze the mix" - Check overall mix
• "analyze track [number]" - Check specific track
• "project info" - Get project details

🎯 Specific Advice:
• "how do I mix vocals" - Vocal mixing tips
• "how do I mix drums" - Drum mixing tips
• "how do I mix bass" - Bass mixing tips
• "general mixing tips" - Overall workflow

🔍 Issue Detection:
• "what needs fixing" - Detect common issues
• "check for clipping" - Check levels
• "sounds muddy" - Low-mid frequency advice
• "sounds harsh" - High frequency advice

💡 Help:
• "help" - Show this message
• "what can you do" - Show capabilities
        """
        return {
            "success": True,
            "output": help_text.strip(),
            "description": "Showing help"
        }
    
    def process_voice_command(self, text):
        """Complete pipeline: parse → execute → return result"""
        command = self.parse(text)
        
        if not command:
            return {
                "success": False,
                "error": "Could not understand question",
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
    """Test the advice command parser"""
    parser = AdviceParser()
    
    test_commands = [
        # Analysis
        "analyze the mix",
        "check the mix",
        "how does this sound",
        "analyze track 3",
        "project info",
        
        # Specific advice
        "how do i mix vocals",
        "vocal mixing tips",
        "how do i mix drums",
        "drum mixing tips",
        "how do i mix bass",
        "general mixing tips",
        
        # Issue detection
        "what needs fixing",
        "any issues",
        "check for clipping",
        "sounds muddy",
        "sounds harsh",
        
        # Help
        "help",
        "what can you do"
    ]
    
    print("=" * 60)
    print("AI ADVICE COMMAND PARSER TEST")
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
