"""
Command Parser for MiDAS AI

Maps voice commands to Logic Pro actions.
Handles variations and fuzzy matching.
"""

import subprocess
from typing import Optional, Callable, Dict
from dataclasses import dataclass
import difflib

@dataclass
class Command:
    """Represents a recognized command."""
    action: str
    params: dict = None
    confidence: float = 1.0

class Commander:
    """Parses voice commands and executes Logic Pro actions."""
    
    def __init__(self):
        # Command mappings (voice text -> action)
        self.commands = {
            # Phase 1: Punchobot
            "start punch": "startPunch",
            "record": "startPunch",
            "start recording": "startPunch",
            "punch in": "startPunch",
            
            "next take": "nextTake",
            "next": "nextTake",
            "done": "nextTake",
            "finish": "nextTake",
            
            "keep it": "keepIt",
            "save it": "keepIt",
            "that's good": "keepIt",
            "keep that": "keepIt",
            
            "trash it": "trashIt",
            "delete it": "trashIt",
            "redo": "trashIt",
            "nah": "trashIt",
            
            "comp mode": "enterCompMode",
            "comping": "enterCompMode",
            "show comps": "enterCompMode",
            
            # Utility
            "reset counter": "resetTakeCounter",
            "how many takes": "getTakeCount",
            
            # Future commands can be added here
        }
        
        # Aliases for fuzzy matching
        self.aliases = {
            "start": "start punch",
            "rec": "record",
            "save": "keep it",
            "delete": "trash it",
            "comp": "comp mode",
        }
        
        # AppleScript file path
        self.script_path = "/Users/midas/Developer/MiDAS-AI/logic-automation/punchobot.scpt"
        
        # Callbacks for feedback
        self.on_command: Optional[Callable[[Command], None]] = None
        self.on_error: Optional[Callable[[str], None]] = None
    
    def parse(self, text: str) -> Optional[Command]:
        """
        Parse voice input text into a command.
        
        Args:
            text: Voice recognition text
        
        Returns:
            Command object or None if not recognized
        """
        text = text.lower().strip()
        
        # Direct match
        if text in self.commands:
            return Command(action=self.commands[text])
        
        # Check aliases
        if text in self.aliases:
            mapped = self.aliases[text]
            return Command(action=self.commands[mapped])
        
        # Fuzzy matching (handle small variations)
        matches = difflib.get_close_matches(text, self.commands.keys(), n=1, cutoff=0.75)
        if matches:
            matched_text = matches[0]
            confidence = difflib.SequenceMatcher(None, text, matched_text).ratio()
            return Command(
                action=self.commands[matched_text],
                confidence=confidence
            )
        
        # Check if text contains a known command
        for cmd_text, action in self.commands.items():
            if cmd_text in text or text in cmd_text:
                return Command(action=action, confidence=0.8)
        
        return None
    
    def execute(self, command: Command) -> Optional[str]:
        """
        Execute a command by calling the corresponding AppleScript function.
        
        Args:
            command: Command to execute
        
        Returns:
            Response from AppleScript or None if failed
        """
        try:
            # Build osascript command
            script_call = f"""
            osascript {self.script_path} <<EOF
            tell application "Logic Pro"
                activate
            end tell
            
            -- Load the script
            set scriptFile to POSIX file "{self.script_path}"
            set scriptObj to load script scriptFile
            
            -- Call the function
            tell scriptObj
                {command.action}()
            end tell
            EOF
            """
            
            # Execute AppleScript
            result = subprocess.run(
                ["osascript", "-e", f'tell script "{self.script_path}" to {command.action}()'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                response = result.stdout.strip()
                print(f"✓ Executed: {command.action}")
                if response:
                    print(f"  Response: {response}")
                return response
            else:
                error = result.stderr.strip()
                print(f"⚠️  Error executing {command.action}: {error}")
                if self.on_error:
                    self.on_error(error)
                return None
        
        except subprocess.TimeoutExpired:
            error = f"Command {command.action} timed out"
            print(f"⏱️  {error}")
            if self.on_error:
                self.on_error(error)
            return None
        except Exception as e:
            error = f"Exception executing {command.action}: {e}"
            print(f"❌ {error}")
            if self.on_error:
                self.on_error(error)
            return None
    
    def handle_voice_input(self, text: str) -> bool:
        """
        Handle voice input: parse and execute command.
        
        Args:
            text: Voice recognition text
        
        Returns:
            True if command was executed, False otherwise
        """
        command = self.parse(text)
        
        if command:
            if command.confidence < 0.9:
                print(f"⚠️  Low confidence ({command.confidence:.0%}): '{text}' -> {command.action}")
            
            if self.on_command:
                self.on_command(command)
            
            self.execute(command)
            return True
        else:
            print(f"❓ Unknown command: '{text}'")
            return False


if __name__ == "__main__":
    # Test the commander
    print("=" * 60)
    print("MiDAS Command Parser Test")
    print("=" * 60)
    print()
    
    commander = Commander()
    
    # Test commands
    test_inputs = [
        "start punch",
        "record",
        "next take",
        "keep it",
        "trash it",
        "comp mode",
        "start",  # Alias
        "rec",    # Alias
        "unknown command",  # Should fail
    ]
    
    for text in test_inputs:
        print(f"\nInput: '{text}'")
        command = commander.parse(text)
        if command:
            print(f"  ✓ Action: {command.action} (confidence: {command.confidence:.0%})")
        else:
            print(f"  ✗ Not recognized")
