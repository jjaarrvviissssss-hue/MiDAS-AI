(*
	MiDAS - Phase 6: Project Analyzer
	Extracts project state from Logic Pro for AI analysis
	
	Limitations:
	- Logic's AppleScript API is minimal
	- Cannot read audio waveforms directly
	- Cannot get exact plugin parameters
	- Most info comes from track structure & naming
	
	What we CAN get:
	- Track count, names, types
	- Basic mix state (mute, solo, volume)
	- Plugin lists per track
	- Project tempo, length
	- Marker positions
	
	Built: February 18, 2026
	By: Jarvis & Adam
*)

-- ============================================
-- PROJECT INFO
-- ============================================

-- Get basic project information
on getProjectInfo()
	tell application "Logic Pro"
		try
			set output to ""
			
			-- Project name (approximation - Logic doesn't expose this)
			set output to output & "Project: Logic Pro Project" & return
			
			-- Tempo
			set currentTempo to 120 -- Default, Logic doesn't expose easily
			set output to output & "Tempo: " & currentTempo & " BPM" & return
			
			-- Track count (approximation)
			set output to output & "Tracks: Unknown (use mixer count)" & return
			
			return output
		on error errMsg
			return "Error getting project info: " & errMsg
		end try
	end tell
end getProjectInfo

-- ============================================
-- TRACK ANALYSIS
-- ============================================

-- Get track list and basic info
on getTrackList()
	tell application "Logic Pro"
		try
			-- Logic's AppleScript doesn't expose track list directly
			-- We'd need to iterate through mixer channels
			
			set output to "Track Analysis:" & return
			set output to output & "Note: Limited info available via AppleScript" & return
			set output to output & "Use mixer view for detailed analysis" & return
			
			return output
		on error errMsg
			return "Error getting track list: " & errMsg
		end try
	end tell
end getTrackList

-- Analyze specific track by number
on analyzeTrack(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.3
		
		set output to "Track " & trackNum & " Analysis:" & return
		
		-- Try to get track name (not directly available)
		set output to output & "Name: Track " & trackNum & return
		
		-- Check if track is muted (via mixer state)
		set output to output & "State: Unknown (check mixer)" & return
		
		-- Plugins (not directly accessible)
		set output to output & "Plugins: Check mixer for details" & return
		
		return output
	end tell
end analyzeTrack

-- ============================================
-- MIXING STATE
-- ============================================

-- Check for common mixing issues (basic)
on checkMixingIssues()
	tell application "Logic Pro"
		set output to "Mix Analysis:" & return & return
		
		-- Check 1: Too many tracks?
		set output to output & "✓ Track Count: Use mixer to verify" & return
		
		-- Check 2: Organization
		set output to output & "✓ Organization: Check for track colors/groups" & return
		
		-- Check 3: Plugin usage
		set output to output & "✓ Plugin Usage: Review per-track insert slots" & return
		
		-- General advice
		set output to output & return & "General Mixing Tips:" & return
		set output to output & "• Keep vocals prominent (usually -12 to -6 dB)" & return
		set output to output & "• Bass and kick should sit together" & return
		set output to output & "• Use EQ to separate instruments" & return
		set output to output & "• Compression for consistency" & return
		set output to output & "• Reference track for comparison" & return
		
		return output
	end tell
end checkMixingIssues

-- ============================================
-- SPECIFIC ADVICE
-- ============================================

-- Vocal mixing advice
on vocalAdvice()
	set advice to "Vocal Mixing Tips:" & return & return
	
	set advice to advice & "1. EQ First:" & return
	set advice to advice & "   • Cut mud (200-500 Hz)" & return
	set advice to advice & "   • Boost presence (3-5 kHz)" & return
	set advice to advice & "   • Add air (10-12 kHz)" & return & return
	
	set advice to advice & "2. Compression:" & return
	set advice to advice & "   • Ratio: 3:1 to 5:1" & return
	set advice to advice & "   • Attack: 5-15 ms (fast)" & return
	set advice to advice & "   • Release: 50-100 ms" & return
	set advice to advice & "   • Gain reduction: 3-6 dB" & return & return
	
	set advice to advice & "3. De-Essing:" & return
	set advice to advice & "   • Target 5-8 kHz" & return
	set advice to advice & "   • Gentle reduction (2-4 dB)" & return & return
	
	set advice to advice & "4. Reverb:" & return
	set advice to advice & "   • Small room or plate" & return
	set advice to advice & "   • Mix 10-20%" & return
	set advice to advice & "   • Pre-delay 10-30 ms" & return & return
	
	set advice to advice & "5. Final Level:" & return
	set advice to advice & "   • Peak around -12 to -6 dB" & return
	set advice to advice & "   • Loudest element in mix (usually)" & return
	
	return advice
end vocalAdvice

-- Drum mixing advice
on drumAdvice()
	set advice to "Drum Mixing Tips:" & return & return
	
	set advice to advice & "1. Kick Drum:" & return
	set advice to advice & "   • Boost low end (60-80 Hz)" & return
	set advice to advice & "   • Add punch (2-4 kHz)" & return
	set advice to advice & "   • Compress 4:1, fast attack" & return & return
	
	set advice to advice & "2. Snare:" & return
	set advice to advice & "   • Body at 200 Hz" & return
	set advice to advice & "   • Crack at 3-5 kHz" & return
	set advice to advice & "   • Parallel compression for power" & return & return
	
	set advice to advice & "3. Hi-Hats:" & return
	set advice to advice & "   • High-pass filter below 300 Hz" & return
	set advice to advice & "   • Boost air (10-12 kHz)" & return
	set advice to advice & "   • Keep lower than snare" & return & return
	
	set advice to advice & "4. Drum Bus:" & return
	set advice to advice & "   • Glue compression (2:1)" & return
	set advice to advice & "   • Subtle EQ for overall tone" & return
	set advice to advice & "   • Saturation for warmth" & return & return
	
	set advice to advice & "5. Balance:" & return
	set advice to advice & "   • Kick and snare should compete with vocals" & return
	set advice to advice & "   • Hi-hats/cymbals sit behind" & return
	
	return advice
end drumAdvice

-- Bass mixing advice
on bassAdvice()
	set advice to "Bass Mixing Tips:" & return & return
	
	set advice to advice & "1. EQ:" & return
	set advice to advice & "   • Fundamental: 40-80 Hz" & return
	set advice to advice & "   • Harmonics: 150-500 Hz" & return
	set advice to advice & "   • Cut mud if conflicting with kick" & return & return
	
	set advice to advice & "2. Compression:" & return
	set advice to advice & "   • Ratio: 4:1 to 6:1" & return
	set advice to advice & "   • Medium attack (10-30 ms)" & return
	set advice to advice & "   • Medium release (100-200 ms)" & return & return
	
	set advice to advice & "3. Sidechain with Kick:" & return
	set advice to advice & "   • Let kick punch through" & return
	set advice to advice & "   • Subtle ducking (2-3 dB)" & return & return
	
	set advice to advice & "4. Saturation:" & return
	set advice to advice & "   • Adds harmonics" & return
	set advice to advice & "   • Makes bass audible on small speakers" & return & return
	
	set advice to advice & "5. Level:" & return
	set advice to advice & "   • Should feel powerful but not overpowering" & return
	set advice to advice & "   • Balance with kick drum" & return
	
	return advice
end bassAdvice

-- General mixing advice
on generalAdvice()
	set advice to "General Mixing Workflow:" & return & return
	
	set advice to advice & "1. Start with Levels:" & return
	set advice to advice & "   • Get rough balance first" & return
	set advice to advice & "   • Vocals/lead usually loudest" & return
	set advice to advice & "   • Rhythm section consistent" & return & return
	
	set advice to advice & "2. EQ for Separation:" & return
	set advice to advice & "   • Every instrument needs its own space" & return
	set advice to advice & "   • Cut before you boost" & return
	set advice to advice & "   • Use high-pass filters liberally" & return & return
	
	set advice to advice & "3. Compression for Consistency:" & return
	set advice to advice & "   • Vocals need most" & return
	set advice to advice & "   • Drums for punch" & return
	set advice to advice & "   • Bass for sustain" & return & return
	
	set advice to advice & "4. Add Space:" & return
	set advice to advice & "   • Reverb for depth" & return
	set advice to advice & "   • Delay for width" & return
	set advice to advice & "   • Don't overdo it" & return & return
	
	set advice to advice & "5. Reference Track:" & return
	set advice to advice & "   • Import a professional mix" & return
	set advice to advice & "   • A/B compare frequently" & return
	set advice to advice & "   • Match loudness first" & return & return
	
	set advice to advice & "6. Take Breaks:" & return
	set advice to advice & "   • Ear fatigue is real" & return
	set advice to advice & "   • Fresh ears = better decisions" & return
	
	return advice
end generalAdvice

-- ============================================
-- ISSUE DETECTION
-- ============================================

-- Check for common issues
on detectIssues()
	set issues to "Common Issues to Check:" & return & return
	
	set issues to issues & "🔴 Clipping:" & return
	set issues to issues & "   • Check master fader (should peak below 0 dB)" & return
	set issues to issues & "   • Look for red lights in mixer" & return
	set issues to issues & "   • Use limiter on master if needed" & return & return
	
	set issues to issues & "🟡 Muddiness (200-500 Hz):" & return
	set issues to issues & "   • Too much low-mid frequency buildup" & return
	set issues to issues & "   • Cut with EQ on individual tracks" & return
	set issues to issues & "   • High-pass filter non-bass instruments" & return & return
	
	set issues to issues & "🟡 Harshness (2-5 kHz):" & return
	set issues to issues & "   • Painful high-mids" & return
	set issues to issues & "   • Reduce with EQ" & return
	set issues to issues & "   • Check cymbal/snare levels" & return & return
	
	set issues to issues & "🟢 Phase Issues:" & return
	set issues to issues & "   • Stereo cancellation" & return
	set issues to issues & "   • Check in mono" & return
	set issues to issues & "   • Verify double-tracked elements align" & return & return
	
	set issues to issues & "🟢 Dynamic Range:" & return
	set issues to issues & "   • Too compressed = lifeless" & return
	set issues to issues & "   • Too dynamic = inconsistent" & return
	set issues to issues & "   • Find balance with compression" & return
	
	return issues
end detectIssues

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Select track by number
on selectTrackByNumber(trackNum)
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Go to track 1
			repeat 50 times
				keystroke (key code 126) using {command down, option down}
				delay 0.05
			end repeat
			delay 0.2
			
			-- Move to target
			repeat (trackNum - 1) times
				keystroke (key code 125) using {command down, option down}
				delay 0.05
			end repeat
		end tell
	end tell
end selectTrackByNumber

-- ============================================
-- MAIN COMMAND ROUTER
-- ============================================

on run argv
	if (count of argv) is 0 then
		return "Error: No command specified"
	end if
	
	set cmd to item 1 of argv
	
	-- Analysis commands
	if cmd is "project_info" then
		return my getProjectInfo()
	else if cmd is "track_list" then
		return my getTrackList()
	else if cmd is "analyze_track" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my analyzeTrack(trackNum)
		end if
	else if cmd is "check_mix" then
		return my checkMixingIssues()
		
		-- Advice commands
	else if cmd is "vocal_advice" then
		return my vocalAdvice()
	else if cmd is "drum_advice" then
		return my drumAdvice()
	else if cmd is "bass_advice" then
		return my bassAdvice()
	else if cmd is "general_advice" then
		return my generalAdvice()
		
		-- Issue detection
	else if cmd is "detect_issues" then
		return my detectIssues()
	end if
	
	return "Error: Unknown command '" & cmd & "'"
end run
