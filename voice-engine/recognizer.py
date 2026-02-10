"""
Voice Recognition Engine for MiDAS AI

Listens for voice commands and converts to text.
Supports both macOS Speech Recognition (free) and Whisper (higher accuracy).
"""

import speech_recognition as sr
import queue
import threading
from typing import Callable, Optional

class VoiceRecognizer:
    def __init__(self, use_whisper=False, energy_threshold=4000):
        """
        Initialize voice recognizer.
        
        Args:
            use_whisper: Use Whisper model instead of macOS recognition
            energy_threshold: Minimum audio energy to consider for recording
        """
        self.recognizer = sr.Recognizer()
        self.recognizer.energy_threshold = energy_threshold
        self.recognizer.dynamic_energy_threshold = True
        
        self.microphone = sr.Microphone()
        self.use_whisper = use_whisper
        
        self.command_queue = queue.Queue()
        self.is_listening = False
        self.listen_thread = None
        
        # Calibrate for ambient noise
        with self.microphone as source:
            print("🎤 Calibrating for ambient noise...")
            self.recognizer.adjust_for_ambient_noise(source, duration=1)
            print(f"✓ Energy threshold set to {self.recognizer.energy_threshold}")
    
    def start_listening(self, callback: Callable[[str], None]):
        """
        Start continuous listening for commands.
        
        Args:
            callback: Function to call when command is recognized
        """
        if self.is_listening:
            print("⚠️  Already listening")
            return
        
        self.is_listening = True
        self.listen_thread = threading.Thread(
            target=self._listen_loop,
            args=(callback,),
            daemon=True
        )
        self.listen_thread.start()
        print("🎤 MiDAS is listening...")
    
    def stop_listening(self):
        """Stop listening for commands."""
        self.is_listening = False
        if self.listen_thread:
            self.listen_thread.join(timeout=2)
        print("🔇 MiDAS stopped listening")
    
    def _listen_loop(self, callback: Callable[[str], None]):
        """Internal loop that continuously listens for speech."""
        with self.microphone as source:
            while self.is_listening:
                try:
                    # Listen for audio
                    audio = self.recognizer.listen(source, timeout=1, phrase_time_limit=5)
                    
                    # Recognize speech
                    try:
                        if self.use_whisper:
                            # Use Whisper model (more accurate, slower)
                            text = self.recognizer.recognize_whisper(audio, language="english")
                        else:
                            # Use macOS recognition (faster, free)
                            text = self.recognizer.recognize_sphinx(audio)
                        
                        if text:
                            text = text.lower().strip()
                            print(f"🎤 Heard: '{text}'")
                            callback(text)
                    
                    except sr.UnknownValueError:
                        # Speech was unintelligible
                        pass
                    except sr.RequestError as e:
                        print(f"⚠️  Recognition error: {e}")
                
                except sr.WaitTimeoutError:
                    # No speech detected, continue listening
                    continue
                except KeyboardInterrupt:
                    break
    
    def recognize_once(self) -> Optional[str]:
        """
        Listen for a single command and return the text.
        Blocking call.
        
        Returns:
            Recognized text or None if failed
        """
        with self.microphone as source:
            print("🎤 Listening...")
            try:
                audio = self.recognizer.listen(source, timeout=5, phrase_time_limit=5)
                
                if self.use_whisper:
                    text = self.recognizer.recognize_whisper(audio, language="english")
                else:
                    text = self.recognizer.recognize_sphinx(audio)
                
                return text.lower().strip() if text else None
            
            except sr.WaitTimeoutError:
                print("⏱️  Timeout - no speech detected")
                return None
            except sr.UnknownValueError:
                print("❓ Could not understand audio")
                return None
            except sr.RequestError as e:
                print(f"⚠️  Recognition error: {e}")
                return None


if __name__ == "__main__":
    # Test the recognizer
    print("=" * 60)
    print("MiDAS Voice Recognition Test")
    print("=" * 60)
    print()
    print("Say a command (or Ctrl+C to quit):")
    print()
    
    recognizer = VoiceRecognizer()
    
    def test_callback(text):
        print(f"✓ Recognized: '{text}'")
    
    try:
        recognizer.start_listening(test_callback)
        
        # Keep main thread alive
        while True:
            pass
    
    except KeyboardInterrupt:
        print("\n\nStopping...")
        recognizer.stop_listening()
