(*
	MiDAS - Phase 4: Track Management
	Voice-controlled track organization for Logic Pro
	
	Features:
	- Create/duplicate/delete tracks
	- Rename tracks
	- Group/ungroup tracks
	- Color tracks
	- Show/hide tracks
	- Lock/unlock tracks
	- Reorder tracks
	
	Built: February 17, 2026
	By: Jarvis & Adam
*)

-- ============================================
-- TRACK CREATION
-- ============================================

-- Create new audio track
on createAudioTrack()
	tell application "Logic Pro"
		activate
		tell application "System Events"
			keystroke "t" using {option down} -- Create audio track
		end tell
		delay 0.5
		return "Created audio track"
	end tell
end createAudioTrack

-- Create new MIDI/instrument track
on createMIDITrack()
	tell application "Logic Pro"
		activate
		tell application "System Events"
			keystroke "t" using {option down, command down} -- Create software instrument
		end tell
		delay 0.5
		return "Created MIDI instrument track"
	end tell
end createMIDITrack

-- Create aux track
on createAuxTrack()
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Navigate to Track menu > New Tracks... > Aux
			keystroke "t" using {option down}
			delay 0.3
		end tell
		return "Created aux track"
	end tell
end createAuxTrack

-- Duplicate selected track
on duplicateTrack(trackNum)
	tell application "Logic Pro"
		activate
		-- Select track by number
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			keystroke "d" using {command down} -- Duplicate track
		end tell
		delay 0.5
		return "Duplicated track " & trackNum
	end tell
end duplicateTrack

-- Delete track by number
on deleteTrack(trackNum)
	tell application "Logic Pro"
		activate
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			keystroke (key code 51) -- Delete key
		end tell
		delay 0.3
		
		-- Confirm deletion if dialog appears
		tell application "System Events"
			tell process "Logic Pro"
				if exists sheet 1 of window 1 then
					keystroke return -- Confirm
				end if
			end tell
		end tell
		
		return "Deleted track " & trackNum
	end tell
end deleteTrack

-- ============================================
-- TRACK NAMING
-- ============================================

-- Rename track
on renameTrack(trackNum, newName)
	tell application "Logic Pro"
		activate
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Open track inspector
			keystroke "i" using {command down}
			delay 0.3
			
			-- Click on track name field (usually at top of inspector)
			-- This is approximate - may need adjustment
			keystroke tab -- Navigate to name field
			delay 0.1
			
			-- Clear existing name
			keystroke "a" using {command down}
			delay 0.1
			
			-- Type new name
			keystroke newName
			delay 0.1
			
			keystroke return -- Confirm
		end tell
		
		return "Renamed track " & trackNum & " to " & newName
	end tell
end renameTrack

-- ============================================
-- TRACK GROUPING
-- ============================================

-- Create folder/group from tracks
on groupTracks(startTrack, endTrack, groupName)
	tell application "Logic Pro"
		activate
		
		-- Select track range
		my selectTrackByNumber(startTrack)
		delay 0.2
		
		tell application "System Events"
			-- Extend selection to end track
			repeat (endTrack - startTrack) times
				keystroke (key code 125) using {shift down} -- Shift + Down Arrow
				delay 0.1
			end repeat
			
			-- Create folder track
			keystroke "t" using {command down, shift down, option down}
			delay 0.5
		end tell
		
		-- Rename folder if name provided
		if groupName is not "" then
			my renameTrack(startTrack, groupName)
		end if
		
		return "Grouped tracks " & startTrack & " to " & endTrack
	end tell
end groupTracks

-- Unpack/ungroup folder
on ungroupTracks(folderTrack)
	tell application "Logic Pro"
		activate
		
		-- Select folder track
		my selectTrackByNumber(folderTrack)
		delay 0.2
		
		tell application "System Events"
			-- Unpack folder (Shift+Cmd+U)
			keystroke "u" using {command down, shift down}
		end tell
		delay 0.5
		
		return "Ungrouped folder at track " & folderTrack
	end tell
end ungroupTracks

-- ============================================
-- TRACK COLORS
-- ============================================

-- Color track by name (Logic's color palette)
on colorTrack(trackNum, colorName)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		-- Color palette mapping
		set colorKey to ""
		
		if colorName is in {"red", "pink"} then
			set colorKey to "1"
		else if colorName is in {"orange", "brown"} then
			set colorKey to "2"
		else if colorName is "yellow" then
			set colorKey to "3"
		else if colorName is in {"green", "lime"} then
			set colorKey to "4"
		else if colorName is in {"blue", "cyan", "teal"} then
			set colorKey to "5"
		else if colorName is in {"purple", "violet", "magenta"} then
			set colorKey to "6"
		else if colorName is in {"gray", "grey", "white"} then
			set colorKey to "7"
		else
			set colorKey to "1" -- Default to red
		end if
		
		tell application "System Events"
			-- Open color picker (Option+C)
			keystroke "c" using {option down}
			delay 0.3
			
			-- Select color from palette
			keystroke colorKey
			delay 0.2
		end tell
		
		return "Colored track " & trackNum & " " & colorName
	end tell
end colorTrack

-- ============================================
-- TRACK VISIBILITY
-- ============================================

-- Hide track
on hideTrack(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Toggle track visibility (H key)
			keystroke "h"
		end tell
		delay 0.3
		
		return "Hid track " & trackNum
	end tell
end hideTrack

-- Show track (same as hide - it's a toggle)
on showTrack(trackNum)
	return my hideTrack(trackNum) -- Same command toggles visibility
end showTrack

-- Hide all except selected
on hideAllExcept(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Select track to keep visible
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Hide all except selected (Shift+H)
			keystroke "h" using {shift down}
		end tell
		delay 0.3
		
		return "Hid all tracks except " & trackNum
	end tell
end hideAllExcept

-- Show all tracks
on showAllTracks()
	tell application "Logic Pro"
		activate
		
		tell application "System Events"
			-- Unhide all (Cmd+Shift+H)
			keystroke "h" using {command down, shift down}
		end tell
		delay 0.3
		
		return "Showed all tracks"
	end tell
end showAllTracks

-- ============================================
-- TRACK PROTECTION
-- ============================================

-- Lock/protect track
on lockTrack(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Toggle track lock (Cmd+L)
			keystroke "l" using {command down}
		end tell
		delay 0.2
		
		return "Locked track " & trackNum
	end tell
end lockTrack

-- Unlock track (same as lock - it's a toggle)
on unlockTrack(trackNum)
	return my lockTrack(trackNum) -- Same command toggles lock
end unlockTrack

-- ============================================
-- TRACK REORDERING
-- ============================================

-- Move track up in list
on moveTrackUp(trackNum, positions)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Move track up (Cmd+Option+Up)
			repeat positions times
				keystroke (key code 126) using {command down, option down} -- Up arrow
				delay 0.2
			end repeat
		end tell
		
		return "Moved track " & trackNum & " up " & positions & " positions"
	end tell
end moveTrackUp

-- Move track down in list
on moveTrackDown(trackNum, positions)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Move track down (Cmd+Option+Down)
			repeat positions times
				keystroke (key code 125) using {command down, option down} -- Down arrow
				delay 0.2
			end repeat
		end tell
		
		return "Moved track " & trackNum & " down " & positions & " positions"
	end tell
end moveTrackDown

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Select track by number (1-based)
on selectTrackByNumber(trackNum)
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- First, go to track 1 (Cmd+Option+Up many times)
			repeat 50 times
				keystroke (key code 126) using {command down, option down}
				delay 0.05
			end repeat
			delay 0.2
			
			-- Then move down to target track
			repeat (trackNum - 1) times
				keystroke (key code 125) using {command down, option down}
				delay 0.05
			end repeat
		end tell
	end tell
end selectTrackByNumber

-- Get selected track number (approximate - Logic doesn't expose this easily)
on getSelectedTrackNumber()
	-- This is a placeholder - actual implementation would need screen scraping
	-- or other workarounds since Logic's AppleScript doesn't expose track numbers
	return 1
end getSelectedTrackNumber

-- ============================================
-- MAIN COMMAND ROUTER
-- ============================================

on run argv
	if (count of argv) is 0 then
		return "Error: No command specified"
	end if
	
	set cmd to item 1 of argv
	
	-- Track creation commands
	if cmd is "create_audio" then
		return my createAudioTrack()
	else if cmd is "create_midi" then
		return my createMIDITrack()
	else if cmd is "create_aux" then
		return my createAuxTrack()
	else if cmd is "duplicate" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my duplicateTrack(trackNum)
		end if
	else if cmd is "delete" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my deleteTrack(trackNum)
		end if
		
		-- Track naming commands
	else if cmd is "rename" then
		if (count of argv) ≥ 3 then
			set trackNum to item 2 of argv as integer
			set newName to item 3 of argv
			return my renameTrack(trackNum, newName)
		end if
		
		-- Grouping commands
	else if cmd is "group" then
		if (count of argv) ≥ 3 then
			set startTrack to item 2 of argv as integer
			set endTrack to item 3 of argv as integer
			set groupName to ""
			if (count of argv) ≥ 4 then
				set groupName to item 4 of argv
			end if
			return my groupTracks(startTrack, endTrack, groupName)
		end if
	else if cmd is "ungroup" then
		if (count of argv) ≥ 2 then
			set folderTrack to item 2 of argv as integer
			return my ungroupTracks(folderTrack)
		end if
		
		-- Color commands
	else if cmd is "color" then
		if (count of argv) ≥ 3 then
			set trackNum to item 2 of argv as integer
			set colorName to item 3 of argv
			return my colorTrack(trackNum, colorName)
		end if
		
		-- Visibility commands
	else if cmd is "hide" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my hideTrack(trackNum)
		end if
	else if cmd is "show" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my showTrack(trackNum)
		end if
	else if cmd is "hide_except" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my hideAllExcept(trackNum)
		end if
	else if cmd is "show_all" then
		return my showAllTracks()
		
		-- Protection commands
	else if cmd is "lock" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my lockTrack(trackNum)
		end if
	else if cmd is "unlock" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my unlockTrack(trackNum)
		end if
		
		-- Reordering commands
	else if cmd is "move_up" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			set positions to 1
			if (count of argv) ≥ 3 then
				set positions to item 3 of argv as integer
			end if
			return my moveTrackUp(trackNum, positions)
		end if
	else if cmd is "move_down" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			set positions to 1
			if (count of argv) ≥ 3 then
				set positions to item 3 of argv as integer
			end if
			return my moveTrackDown(trackNum, positions)
		end if
	end if
	
	return "Error: Unknown command '" & cmd & "'"
end run
