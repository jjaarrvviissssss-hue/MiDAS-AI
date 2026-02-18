(*
	MiDAS - Phase 5: Plugin Control
	Voice-controlled plugin management for Logic Pro
	
	Features:
	- Load plugins on tracks
	- Bypass/enable plugins
	- Adjust parameters (basic)
	- Navigate plugin windows
	- Remove plugins
	
	Note: Logic Pro's AppleScript has limited plugin support.
	Most operations use keyboard shortcuts and UI automation.
	
	Built: February 17, 2026
	By: Jarvis & Adam
*)

-- ============================================
-- PLUGIN LOADING
-- ============================================

-- Open plugin insert menu for current track
on openPluginMenu(insertSlot)
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Click on insert slot (using keyboard navigation)
			-- Insert slots are accessed via Channel Strip
			
			-- Open mixer (X)
			keystroke "x"
			delay 0.3
			
			-- Navigate to insert slot (Tab to move through)
			-- This is approximate - may need adjustment per setup
			repeat insertSlot times
				keystroke tab
				delay 0.1
			end repeat
			
			-- Open plugin menu (click or Enter)
			keystroke return
			delay 0.4
		end tell
		
		return "Opened plugin insert menu"
	end tell
end openPluginMenu

-- Load plugin by name (searches in plugin menu)
on loadPlugin(trackNum, pluginName, insertSlot)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.3
		
		-- Open insert slot
		my openPluginMenu(insertSlot)
		delay 0.3
		
		tell application "System Events"
			-- Type plugin name to search
			keystroke pluginName
			delay 0.5
			
			-- Select first match (usually correct)
			keystroke return
			delay 0.5
		end tell
		
		return "Loaded " & pluginName & " on track " & trackNum
	end tell
end loadPlugin

-- Load common Logic plugins (known shortcuts)
on loadLogicPlugin(trackNum, pluginType)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Open quick plugin menu (Control+Click simulation)
			-- Different approach: use Channel EQ shortcut or direct plugin shortcuts
			
			if pluginType is "eq" then
				-- Load Channel EQ (if available via menu)
				my loadPlugin(trackNum, "Channel EQ", 1)
			else if pluginType is "compressor" then
				my loadPlugin(trackNum, "Compressor", 1)
			else if pluginType is "reverb" then
				my loadPlugin(trackNum, "Space Designer", 1)
			else if pluginType is "delay" then
				my loadPlugin(trackNum, "Delay Designer", 1)
			end if
		end tell
		
		return "Loaded " & pluginType & " on track " & trackNum
	end tell
end loadLogicPlugin

-- ============================================
-- PLUGIN BYPASS
-- ============================================

-- Bypass/enable plugin at insert slot
on bypassPlugin(trackNum, insertSlot)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Open mixer
			keystroke "x"
			delay 0.3
			
			-- Navigate to plugin slot
			-- Use Tab to move through inserts
			repeat insertSlot times
				keystroke tab
				delay 0.1
			end repeat
			
			-- Toggle bypass (usually Option+Click, but we'll use keyboard)
			-- Power button on plugin is usually Cmd+Shift+B or similar
			keystroke "b" using {command down}
			delay 0.2
		end tell
		
		return "Toggled bypass for plugin " & insertSlot & " on track " & trackNum
	end tell
end bypassPlugin

-- Bypass all plugins on a track
on bypassAllPlugins(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Bypass all inserts (Shift+Cmd+B or similar)
			-- This might need adjustment based on Logic version
			keystroke "b" using {command down, shift down}
			delay 0.3
		end tell
		
		return "Bypassed all plugins on track " & trackNum
	end tell
end bypassAllPlugins

-- ============================================
-- PLUGIN PARAMETERS
-- ============================================

-- Open plugin window
on openPluginWindow(trackNum, insertSlot)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Open mixer
			keystroke "x"
			delay 0.3
			
			-- Navigate to plugin slot
			repeat insertSlot times
				keystroke tab
				delay 0.1
			end repeat
			
			-- Double-click to open (or Enter)
			keystroke return
			delay 0.5
		end tell
		
		return "Opened plugin " & insertSlot & " on track " & trackNum
	end tell
end openPluginWindow

-- Close plugin window
on closePluginWindow()
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Close front window (Cmd+W)
			keystroke "w" using {command down}
			delay 0.2
		end tell
		
		return "Closed plugin window"
	end tell
end closePluginWindow

-- Adjust plugin parameter (generic - uses arrow keys)
on adjustParameter(direction, amount)
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Assumes plugin window is open and parameter is selected
			
			-- Use arrow keys or +/- to adjust
			if direction is "up" or direction is "increase" then
				repeat amount times
					keystroke (key code 126) -- Up arrow
					delay 0.1
				end repeat
			else if direction is "down" or direction is "decrease" then
				repeat amount times
					keystroke (key code 125) -- Down arrow
					delay 0.1
				end repeat
			end if
		end tell
		
		return "Adjusted parameter " & direction & " by " & amount
	end tell
end adjustParameter

-- ============================================
-- PLUGIN PRESETS
-- ============================================

-- Save plugin preset
on savePreset(presetName)
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Assumes plugin window is open
			
			-- Open preset menu (usually at top of plugin)
			-- Use keyboard shortcut or navigate with Tab
			keystroke tab -- Move to preset selector
			delay 0.2
			
			keystroke return -- Open preset menu
			delay 0.3
			
			-- Save preset option (usually at bottom)
			-- Type to search or navigate
			keystroke "Save" -- Type to find "Save Preset"
			delay 0.3
			
			keystroke return
			delay 0.4
			
			-- Type preset name
			keystroke presetName
			delay 0.2
			
			keystroke return -- Confirm
			delay 0.3
		end tell
		
		return "Saved preset: " & presetName
	end tell
end savePreset

-- Load plugin preset
on loadPreset(presetName)
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Assumes plugin window is open
			
			-- Open preset menu
			keystroke tab
			delay 0.2
			keystroke return
			delay 0.3
			
			-- Type preset name to search
			keystroke presetName
			delay 0.3
			
			keystroke return -- Select
			delay 0.3
		end tell
		
		return "Loaded preset: " & presetName
	end tell
end loadPreset

-- ============================================
-- PLUGIN REMOVAL
-- ============================================

-- Remove plugin from insert slot
on removePlugin(trackNum, insertSlot)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Open mixer
			keystroke "x"
			delay 0.3
			
			-- Navigate to plugin slot
			repeat insertSlot times
				keystroke tab
				delay 0.1
			end repeat
			
			-- Remove plugin (usually Delete or Backspace)
			keystroke (key code 51) -- Delete key
			delay 0.3
			
			-- Confirm if dialog appears
			keystroke return
			delay 0.2
		end tell
		
		return "Removed plugin from slot " & insertSlot & " on track " & trackNum
	end tell
end removePlugin

-- Remove all plugins from track
on removeAllPlugins(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Remove plugins from each slot (up to 15 slots)
			repeat with i from 1 to 15
				my removePlugin(trackNum, i)
				delay 0.2
			end repeat
		end tell
		
		return "Removed all plugins from track " & trackNum
	end tell
end removeAllPlugins

-- ============================================
-- PLUGIN NAVIGATION
-- ============================================

-- Navigate to next plugin on track
on nextPlugin()
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Assumes mixer is open
			-- Tab to next insert
			keystroke tab
			delay 0.2
		end tell
		
		return "Moved to next plugin"
	end tell
end nextPlugin

-- Navigate to previous plugin on track
on previousPlugin()
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Shift+Tab to previous insert
			keystroke tab using {shift down}
			delay 0.2
		end tell
		
		return "Moved to previous plugin"
	end tell
end previousPlugin

-- Show all plugins on track (opens mixer channel strip)
on showAllPlugins(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Select track
		my selectTrackByNumber(trackNum)
		delay 0.2
		
		tell application "System Events"
			-- Open mixer (X) to show channel strip with all inserts
			keystroke "x"
			delay 0.3
		end tell
		
		return "Showing all plugins for track " & trackNum
	end tell
end showAllPlugins

-- ============================================
-- COMMON PLUGIN PRESETS
-- ============================================

-- Load common vocal chain
on loadVocalChain(trackNum)
	tell application "Logic Pro"
		activate
		
		-- Load typical vocal processing chain
		my loadLogicPlugin(trackNum, "eq")
		delay 0.5
		my loadLogicPlugin(trackNum, "compressor")
		delay 0.5
		my loadPlugin(trackNum, "DeEsser", 3)
		delay 0.5
		my loadPlugin(trackNum, "Space Designer", 4)
		delay 0.5
		
		return "Loaded vocal chain on track " & trackNum
	end tell
end loadVocalChain

-- Load common drum bus chain
on loadDrumBus(trackNum)
	tell application "Logic Pro"
		activate
		
		my loadLogicPlugin(trackNum, "compressor")
		delay 0.5
		my loadLogicPlugin(trackNum, "eq")
		delay 0.5
		my loadPlugin(trackNum, "Exciter", 3)
		delay 0.5
		
		return "Loaded drum bus chain on track " & trackNum
	end tell
end loadDrumBus

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Select track by number (reused from track_management)
on selectTrackByNumber(trackNum)
	tell application "Logic Pro"
		activate
		tell application "System Events"
			-- Go to track 1 first
			repeat 50 times
				keystroke (key code 126) using {command down, option down}
				delay 0.05
			end repeat
			delay 0.2
			
			-- Move to target track
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
	
	-- Plugin loading commands
	if cmd is "load_plugin" then
		if (count of argv) ≥ 4 then
			set trackNum to item 2 of argv as integer
			set pluginName to item 3 of argv
			set insertSlot to item 4 of argv as integer
			return my loadPlugin(trackNum, pluginName, insertSlot)
		end if
	else if cmd is "load_logic" then
		if (count of argv) ≥ 3 then
			set trackNum to item 2 of argv as integer
			set pluginType to item 3 of argv
			return my loadLogicPlugin(trackNum, pluginType)
		end if
	else if cmd is "vocal_chain" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my loadVocalChain(trackNum)
		end if
	else if cmd is "drum_bus" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my loadDrumBus(trackNum)
		end if
		
		-- Bypass commands
	else if cmd is "bypass" then
		if (count of argv) ≥ 3 then
			set trackNum to item 2 of argv as integer
			set insertSlot to item 3 of argv as integer
			return my bypassPlugin(trackNum, insertSlot)
		end if
	else if cmd is "bypass_all" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my bypassAllPlugins(trackNum)
		end if
		
		-- Window commands
	else if cmd is "open_plugin" then
		if (count of argv) ≥ 3 then
			set trackNum to item 2 of argv as integer
			set insertSlot to item 3 of argv as integer
			return my openPluginWindow(trackNum, insertSlot)
		end if
	else if cmd is "close_plugin" then
		return my closePluginWindow()
		
		-- Parameter commands
	else if cmd is "adjust" then
		if (count of argv) ≥ 3 then
			set direction to item 2 of argv
			set amount to item 3 of argv as integer
			return my adjustParameter(direction, amount)
		end if
		
		-- Preset commands
	else if cmd is "save_preset" then
		if (count of argv) ≥ 2 then
			set presetName to item 2 of argv
			return my savePreset(presetName)
		end if
	else if cmd is "load_preset" then
		if (count of argv) ≥ 2 then
			set presetName to item 2 of argv
			return my loadPreset(presetName)
		end if
		
		-- Removal commands
	else if cmd is "remove" then
		if (count of argv) ≥ 3 then
			set trackNum to item 2 of argv as integer
			set insertSlot to item 3 of argv as integer
			return my removePlugin(trackNum, insertSlot)
		end if
	else if cmd is "remove_all" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my removeAllPlugins(trackNum)
		end if
		
		-- Navigation commands
	else if cmd is "next" then
		return my nextPlugin()
	else if cmd is "previous" then
		return my previousPlugin()
	else if cmd is "show_all" then
		if (count of argv) ≥ 2 then
			set trackNum to item 2 of argv as integer
			return my showAllPlugins(trackNum)
		end if
	end if
	
	return "Error: Unknown command '" & cmd & "'"
end run
