#!/usr/bin/env python3
"""
MiDAS AI - Main Coordinator

Orchestrates voice recognition and command execution.
This is the main entry point for MiDAS.
"""

import sys
import os
import time
from pathlib import Path

# Add voice-engine to path
sys.path.insert(0, str(Path(__file__).parent / "voice-engine"))

from recognizer import VoiceRecognizer
from commander import Commander

class MiDAS:
    """Main MiDAS AI coordinator."""
    
    def __init__(self, use_whisper=False):
        """
        Initialize MiDAS.
        
        Args:
            use_whisper: Use Whisper model for voice recognition (more accurate, slower)
        """
        print("🔷 Initializing MiDAS AI...")
        print()
        
        # Initialize components
        self.recognizer = VoiceRecognizer(use_whisper=use_whisper)
        self.commander = Commander()
        
        # Set up callbacks
        self.commander.on_command = self.on_command_recognized
        self.commander.on_error = self.on_error
        
        # State
        self.is_running = False
        self.total_commands = 0
        self.successful_commands = 0
        
        print("✓ Voice recognizer ready")
        print("✓ Command parser ready")
        print()
    
    def start(self):
        """Start MiDAS and begin listening for commands."""
        if self.is_running:
            print("⚠️  MiDAS is already running")
            return
        
        self.is_running = True
        
        print("=" * 60)
        print("🔷 MiDAS AI - PHASE 1: PUNCHOBOT")
        print("=" * 60)
        print()
        print("Voice Commands:")
        print("  • 'start punch' / 'record'  - Start recording")
        print("  • 'next take'               - Finish & process current take")
        print("  • 'keep it'                 - Save current take")
        print("  • 'trash it'                - Delete current take")
        print("  • 'comp mode'               - Enter comping mode")
        print()
        print("🎤 Listening... (Ctrl+C to quit)")
        print("-" * 60)
        print()
        
        try:
            # Start voice recognition
            self.recognizer.start_listening(self.handle_voice_input)
            
            # Keep main thread alive
            while self.is_running:
                time.sleep(0.1)
        
        except KeyboardInterrupt:
            print("\n")
            self.stop()
    
    def stop(self):
        """Stop MiDAS."""
        if not self.is_running:
            return
        
        print("-" * 60)
        print()
        print("🔷 Stopping MiDAS...")
        self.recognizer.stop_listening()
        self.is_running = False
        
        # Stats
        print()
        print("Session Stats:")
        print(f"  Commands processed: {self.total_commands}")
        print(f"  Successful: {self.successful_commands}")
        if self.total_commands > 0:
            success_rate = (self.successful_commands / self.total_commands) * 100
            print(f"  Success rate: {success_rate:.0f}%")
        print()
        print("✓ MiDAS stopped")
        print()
    
    def handle_voice_input(self, text: str):
        """
        Handle voice input from recognizer.
        
        Args:
            text: Recognized speech text
        """
        self.total_commands += 1
        
        # Parse and execute command
        success = self.commander.handle_voice_input(text)
        
        if success:
            self.successful_commands += 1
    
    def on_command_recognized(self, command):
        """Callback when command is successfully recognized."""
        # Could provide audio/visual feedback here
        # For now, just print
        print(f"  ✓ Executing: {command.action}")
    
    def on_error(self, error: str):
        """Callback when error occurs."""
        print(f"  ❌ Error: {error}")


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="MiDAS AI - Voice-controlled music production")
    parser.add_argument(
        "--whisper",
        action="store_true",
        help="Use Whisper model for voice recognition (more accurate, slower)"
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="Run in test mode (single command)"
    )
    
    args = parser.parse_args()
    
    if args.test:
        # Test mode: recognize one command
        print("🔷 MiDAS AI - Test Mode")
        print()
        print("Say a command:")
        recognizer = VoiceRecognizer(use_whisper=args.whisper)
        text = recognizer.recognize_once()
        
        if text:
            print(f"\n✓ Recognized: '{text}'")
            commander = Commander()
            commander.handle_voice_input(text)
        else:
            print("\n✗ No command recognized")
    else:
        # Normal mode: continuous listening
        midas = MiDAS(use_whisper=args.whisper)
        midas.start()


if __name__ == "__main__":
    main()
