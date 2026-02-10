#!/bin/bash
# MiDAS AI - Quick Install Script

echo "🔷 Installing MiDAS AI..."
echo ""

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.8+"
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"

# Check for pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 not found. Please install pip"
    exit 1
fi

echo "✓ pip3 found"

# Check for Homebrew (for portaudio)
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew not found. Install from https://brew.sh"
    echo "   (Required for PyAudio/microphone support)"
fi

# Install portaudio if brew exists
if command -v brew &> /dev/null; then
    echo ""
    echo "📦 Installing portaudio..."
    brew install portaudio
fi

# Install Python dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

echo ""
echo "=" * 60
echo "✅ MiDAS AI Installation Complete!"
echo "=" * 60
echo ""
echo "Next steps:"
echo "1. Open Logic Pro"
echo "2. Create tracks named 'Record' and 'Vocals'"
echo "3. Grant microphone permissions (System Settings)"
echo "4. Run: python3 coordinator.py"
echo ""
echo "See SETUP.md for detailed instructions."
echo ""
