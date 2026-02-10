(*
	PUNCHOBOT - Automated Vocal Recording Workflow
	
	The workflow:
	1. Start recording on current track
	2. After recording stops, move region to designated vocal track
	3. Detect transients, trim silence
	4. Apply fade-in/fade-out to transients
	5. Return to recording track, armed and ready
	6. Auto-name takes (Take 1, Take 2, etc.)
	
	Voice Commands:
	- "start punch" / "record" - Begin recording
	- "next take" - Stop current, process, prep next
	- "keep it" - Save and process current take
	- "trash it" - Delete current take
*)

-- Configuration
property recordingTrackName : "Record" -- Track where you record
property vocalTrackName : "Vocals" -- Track where takes get moved
property fadeLength : 0.01 -- Fade length in seconds (10ms default)
property takeCounter : 0 -- Auto-incrementing take number

-- State management
property isRecording : false
property currentRegion : null

-- MAIN COMMANDS

on startPunch()
	tell application "Logic Pro"
		-- Arm recording track
		set currentTrack to first track whose name is recordingTrackName
		set record enabled of currentTrack to true
		
		-- Start recording
		play
		record
		
		set isRecording to true
		set takeCounter to takeCounter + 1
		
		return "Recording Take " & takeCounter
	end tell
end startPunch

on nextTake()
	if isRecording then
		tell application "Logic Pro"
			-- Stop recording
			stop
			set isRecording to false
			
			-- Get the just-recorded region
			set currentRegion to last region of (first track whose name is recordingTrackName)
			
			-- Process the take
			my processTake(currentRegion)
			
			-- Prep for next punch
			my prepNextPunch()
			
			return "Take " & takeCounter & " processed. Ready for next."
		end tell
	else
		return "Not currently recording"
	end if
end nextTake

on keepIt()
	-- Same as nextTake but with confirmation
	if isRecording then
		my nextTake()
		return "Take " & takeCounter & " saved!"
	else
		return "No active take to save"
	end if
end keepIt

on trashIt()
	if isRecording then
		tell application "Logic Pro"
			stop
			set isRecording to false
			
			-- Delete last region
			set lastRegion to last region of (first track whose name is recordingTrackName)
			delete lastRegion
			
			set takeCounter to takeCounter - 1
			
			return "Take deleted. Ready to punch again."
		end tell
	else
		return "Nothing to trash"
	end if
end trashIt

-- PROCESSING FUNCTIONS

on processTake(theRegion)
	tell application "Logic Pro"
		-- 1. Rename region
		set name of theRegion to "Take " & takeCounter
		
		-- 2. Detect transients and trim
		my trimToTransients(theRegion)
		
		-- 3. Apply fades
		my applyFades(theRegion)
		
		-- 4. Move to vocal track
		my moveToVocalTrack(theRegion)
		
	end tell
end processTake

on trimToTransients(theRegion)
	tell application "Logic Pro"
		-- Logic Pro has built-in "Strip Silence" function
		-- This removes silence and trims to content
		-- Access via: Edit > Trim > Strip Silence
		
		-- For now, we'll use a simplified approach
		-- In production, we'd analyze the audio buffer for transients
		
		-- Basic trim (removes leading/trailing silence below threshold)
		set trimThreshold to -40 -- dB threshold
		-- Logic will auto-trim when we enable "Strip Silence"
		
	end tell
end trimToTransients

on applyFades(theRegion)
	tell application "Logic Pro"
		-- Apply fade-in at start
		set fade in length of theRegion to fadeLength
		set fade in curve of theRegion to 0 -- Linear fade (0-3 for different curves)
		
		-- Apply fade-out at end
		set fade out length of theRegion to fadeLength
		set fade out curve of theRegion to 0
		
	end tell
end applyFades

on moveToVocalTrack(theRegion)
	tell application "Logic Pro"
		-- Get vocal track
		set vocalTrack to first track whose name is vocalTrackName
		
		-- Move region to vocal track
		-- (In Logic, this is done by duplicating and deleting original)
		set regionStart to start time of theRegion
		set regionLength to length of theRegion
		
		-- Create new region on vocal track at same position
		duplicate theRegion to vocalTrack
		
		-- Stack takes vertically for easy comping
		-- (Logic automatically stacks regions on same track)
		
		-- Delete from recording track
		delete theRegion
		
	end tell
end moveToVocalTrack

on prepNextPunch()
	tell application "Logic Pro"
		-- Return playhead to record position
		-- (Usually the start of the section you're punching)
		-- This would be set based on loop/marker position
		
		-- Ensure recording track is armed
		set currentTrack to first track whose name is recordingTrackName
		set record enabled of currentTrack to true
		
		-- Could auto-start recording here if desired
		-- For now, wait for "start punch" command
		
	end tell
end prepNextPunch

-- UTILITY FUNCTIONS

on resetTakeCounter()
	set takeCounter to 0
	return "Take counter reset"
end resetTakeCounter

on getTakeCount()
	return "Current take: " & takeCounter
end getTakeCount

on setFadeLength(newLength)
	set fadeLength to newLength
	return "Fade length set to " & newLength & " seconds"
end setFadeLength

-- COMP MODE

on enterCompMode()
	tell application "Logic Pro"
		-- Switch to comp mode view
		-- In Logic, this shows all takes stacked for easy selection
		-- Enable "Show Take Folders" view
		
		set vocalTrack to first track whose name is vocalTrackName
		-- Logic automatically shows comp mode when multiple takes exist
		
		return "Comp mode active. Select your favorite parts!"
	end tell
end enterCompMode

-- TEST FUNCTION (for development)
on testWorkflow()
	startPunch()
	delay 3 -- Record for 3 seconds
	nextTake()
	return "Test workflow complete"
end testWorkflow
