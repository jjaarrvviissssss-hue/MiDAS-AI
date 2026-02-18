(*
    MiDAS AI - Navigation & Transport Control
    Phase 3: Smart playback, markers, looping
    
    Voice-controlled Logic Pro navigation
    
    Built by Jarvis & Adam - February 2026
*)

use scripting additions
use application "Logic Pro"

-- ============================================================
-- TRANSPORT CONTROL
-- ============================================================

-- Play from current position
on playFromHere()
    tell application "Logic Pro"
        play
    end tell
    return {success:true, message:"Playing"}
end playFromHere

-- Stop playback
on stopPlayback()
    tell application "Logic Pro"
        stop
    end tell
    return {success:true, message:"Stopped"}
end stopPlayback

-- Pause (stop and return to last start position)
on pausePlayback()
    tell application "Logic Pro"
        stop
        -- Logic automatically returns to last play start position
    end tell
    return {success:true, message:"Paused"}
end pausePlayback

-- Toggle play/stop
on togglePlayback()
    tell application "Logic Pro"
        if playing then
            stop
            set action to "Stopped"
        else
            play
            set action to "Playing"
        end if
    end tell
    return {success:true, message:action}
end togglePlayback

-- Rewind to beginning
on rewindToStart()
    tell application "Logic Pro"
        stop
        set playhead position to 1
    end tell
    return {success:true, message:"Rewound to start"}
end rewindToStart

-- Fast forward by bars
on fastForward(numBars)
    tell application "Logic Pro"
        set currentPos to playhead position
        set newPos to currentPos + numBars
        set playhead position to newPos
    end tell
    return {success:true, message:"Jumped forward " & numBars & " bars"}
end fastForward

-- Rewind by bars
on rewind(numBars)
    tell application "Logic Pro"
        set currentPos to playhead position
        set newPos to currentPos - numBars
        if newPos < 1 then set newPos to 1
        set playhead position to newPos
    end tell
    return {success:true, message:"Jumped back " & numBars & " bars"}
end rewind

-- ============================================================
-- MARKER NAVIGATION
-- ============================================================

-- Jump to marker by name
on jumpToMarker(markerName)
    tell application "Logic Pro"
        try
            set markerList to every marker
            repeat with m in markerList
                if name of m contains markerName then
                    set playhead position to position of m
                    return {success:true, message:"Jumped to " & markerName}
                end if
            end repeat
            return {success:false, message:"Marker not found: " & markerName}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end jumpToMarker

-- Jump to marker by number (1-indexed)
on jumpToMarkerNumber(markerNum)
    tell application "Logic Pro"
        try
            set markerList to every marker
            if markerNum > (count of markerList) then
                return {success:false, message:"Only " & (count of markerList) & " markers exist"}
            end if
            set targetMarker to item markerNum of markerList
            set playhead position to position of targetMarker
            return {success:true, message:"Jumped to marker " & markerNum}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end jumpToMarkerNumber

-- List all markers
on listMarkers()
    tell application "Logic Pro"
        try
            set markerList to every marker
            set output to "Markers:" & return
            repeat with i from 1 to count of markerList
                set m to item i of markerList
                set output to output & i & ". " & name of m & " (bar " & position of m & ")" & return
            end repeat
            return {success:true, message:output}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end listMarkers

-- Jump to next marker
on nextMarker()
    tell application "Logic Pro"
        try
            set currentPos to playhead position
            set markerList to every marker
            
            repeat with m in markerList
                if position of m > currentPos then
                    set playhead position to position of m
                    return {success:true, message:"Jumped to " & name of m}
                end if
            end repeat
            
            return {success:false, message:"No marker ahead"}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end nextMarker

-- Jump to previous marker
on previousMarker()
    tell application "Logic Pro"
        try
            set currentPos to playhead position
            set markerList to every marker
            set lastMarker to missing value
            
            repeat with m in markerList
                if position of m < currentPos then
                    set lastMarker to m
                else
                    exit repeat
                end if
            end repeat
            
            if lastMarker is not missing value then
                set playhead position to position of lastMarker
                return {success:true, message:"Jumped to " & name of lastMarker}
            else
                return {success:false, message:"No marker before"}
            end if
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end previousMarker

-- Create marker at current position
on createMarker(markerName)
    tell application "Logic Pro"
        try
            set currentPos to playhead position
            make new marker with properties {name:markerName, position:currentPos}
            return {success:true, message:"Created marker: " & markerName}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end createMarker

-- ============================================================
-- CYCLE/LOOP CONTROL
-- ============================================================

-- Set loop between two positions
on setLoop(startBar, endBar)
    tell application "Logic Pro"
        try
            set cycle on
            set cycle start to startBar
            set cycle end to endBar
            return {success:true, message:"Loop set: bars " & startBar & "-" & endBar}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end setLoop

-- Toggle loop on/off
on toggleLoop()
    tell application "Logic Pro"
        set loopStatus to cycle
        set cycle to not loopStatus
        if cycle then
            set action to "enabled"
        else
            set action to "disabled"
        end if
    end tell
    return {success:true, message:"Loop " & action}
end toggleLoop

-- Loop current selection (requires selection)
on loopSelection()
    tell application "Logic Pro"
        try
            -- This assumes user has made a region selection
            set cycle on
            return {success:true, message:"Looping selection"}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end loopSelection

-- Set loop to section by marker names
on loopBetweenMarkers(startMarkerName, endMarkerName)
    tell application "Logic Pro"
        try
            set markerList to every marker
            set startPos to missing value
            set endPos to missing value
            
            repeat with m in markerList
                if name of m contains startMarkerName then
                    set startPos to position of m
                end if
                if name of m contains endMarkerName then
                    set endPos to position of m
                end if
            end repeat
            
            if startPos is missing value or endPos is missing value then
                return {success:false, message:"Markers not found"}
            end if
            
            set cycle on
            set cycle start to startPos
            set cycle end to endPos
            
            return {success:true, message:"Looping " & startMarkerName & " to " & endMarkerName}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end loopBetweenMarkers

-- Loop N bars from current position
on loopFromHere(numBars)
    tell application "Logic Pro"
        try
            set currentPos to playhead position
            set cycle on
            set cycle start to currentPos
            set cycle end to currentPos + numBars
            return {success:true, message:"Looping " & numBars & " bars from here"}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end loopFromHere

-- ============================================================
-- TEMPO CONTROL
-- ============================================================

-- Set tempo (BPM)
on setTempo(bpm)
    tell application "Logic Pro"
        try
            set tempo to bpm
            return {success:true, message:"Tempo set to " & bpm & " BPM"}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end setTempo

-- Get current tempo
on getTempo()
    tell application "Logic Pro"
        try
            set currentTempo to tempo
            return {success:true, message:"Tempo: " & currentTempo & " BPM", tempo:currentTempo}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end getTempo

-- Adjust tempo by amount
on adjustTempo(bpmChange)
    tell application "Logic Pro"
        try
            set currentTempo to tempo
            set newTempo to currentTempo + bpmChange
            if newTempo < 30 then set newTempo to 30
            if newTempo > 300 then set newTempo to 300
            set tempo to newTempo
            
            set direction to "up"
            if bpmChange < 0 then set direction to "down"
            
            return {success:true, message:"Tempo " & direction & " to " & newTempo & " BPM"}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end adjustTempo

-- ============================================================
-- POSITION QUERIES
-- ============================================================

-- Get current playhead position
on getPlayheadPosition()
    tell application "Logic Pro"
        try
            set currentPos to playhead position
            return {success:true, message:"Bar " & currentPos, position:currentPos}
        on error errMsg
            return {success:false, message:"Error: " & errMsg}
        end try
    end tell
end getPlayheadPosition

-- Check if playing
on isPlaying()
    tell application "Logic Pro"
        set playStatus to playing
    end tell
    if playStatus then
        set message to "Playing"
    else
        set message to "Stopped"
    end if
    return {success:true, message:message, playing:playStatus}
end isPlaying

-- ============================================================
-- MAIN DISPATCH
-- ============================================================

on run argv
    if (count of argv) is 0 then
        return {success:false, message:"No command specified"}
    end if
    
    set command to item 1 of argv
    
    -- Transport commands
    if command is "play" then
        return playFromHere()
    else if command is "stop" then
        return stopPlayback()
    else if command is "pause" then
        return pausePlayback()
    else if command is "toggle-play" then
        return togglePlayback()
    else if command is "rewind-start" then
        return rewindToStart()
    else if command is "fast-forward" then
        set bars to item 2 of argv as number
        return fastForward(bars)
    else if command is "rewind" then
        set bars to item 2 of argv as number
        return rewind(bars)
    
    -- Marker commands
    else if command is "jump-marker" then
        set markerName to item 2 of argv
        return jumpToMarker(markerName)
    else if command is "jump-marker-num" then
        set markerNum to item 2 of argv as number
        return jumpToMarkerNumber(markerNum)
    else if command is "list-markers" then
        return listMarkers()
    else if command is "next-marker" then
        return nextMarker()
    else if command is "prev-marker" then
        return previousMarker()
    else if command is "create-marker" then
        set markerName to item 2 of argv
        return createMarker(markerName)
    
    -- Loop commands
    else if command is "set-loop" then
        set startBar to item 2 of argv as number
        set endBar to item 3 of argv as number
        return setLoop(startBar, endBar)
    else if command is "toggle-loop" then
        return toggleLoop()
    else if command is "loop-selection" then
        return loopSelection()
    else if command is "loop-between-markers" then
        set startMarker to item 2 of argv
        set endMarker to item 3 of argv
        return loopBetweenMarkers(startMarker, endMarker)
    else if command is "loop-from-here" then
        set bars to item 2 of argv as number
        return loopFromHere(bars)
    
    -- Tempo commands
    else if command is "set-tempo" then
        set bpm to item 2 of argv as number
        return setTempo(bpm)
    else if command is "get-tempo" then
        return getTempo()
    else if command is "adjust-tempo" then
        set bpmChange to item 2 of argv as number
        return adjustTempo(bpmChange)
    
    -- Query commands
    else if command is "get-position" then
        return getPlayheadPosition()
    else if command is "is-playing" then
        return isPlaying()
    
    else
        return {success:false, message:"Unknown command: " & command}
    end if
end run
