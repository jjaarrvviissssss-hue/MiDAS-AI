(*
    MiDAS AI - Mixing Automation
    Phase 2: Level Control
    
    Voice-controlled track level adjustments, muting, soloing
    
    Built by Jarvis & Adam - February 2026
*)

use scripting additions
use application "Logic Pro"

-- ============================================================
-- TRACK SELECTION
-- ============================================================

-- Find track by name (case-insensitive, partial match)
on findTrack(trackName)
    tell application "Logic Pro"
        set trackList to every track
        repeat with t in trackList
            if name of t contains trackName then
                return t
            end if
        end repeat
    end tell
    return missing value
end findTrack

-- Get selected track
on getSelectedTrack()
    tell application "Logic Pro"
        try
            return selection track
        on error
            return missing value
        end try
    end tell
end getSelectedTrack

-- ============================================================
-- VOLUME CONTROL
-- ============================================================

-- Convert dB to fader value (Logic uses 0-1 range, where 0.75 ≈ 0dB)
on dbToFader(dbValue)
    -- Logic Pro fader: 0dB = 0.75, +6dB = 1.0, -∞ = 0
    -- Rough mapping: fader = 0.75 + (dB/24)
    set faderValue to 0.75 + (dbValue / 24)
    if faderValue < 0 then set faderValue to 0
    if faderValue > 1 then set faderValue to 1
    return faderValue
end dbToFader

-- Convert fader to dB (for display)
on faderToDb(faderValue)
    return (faderValue - 0.75) * 24
end faderToDb

-- Set track volume by dB (absolute)
on setTrackVolume(trackName, dbValue)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set volume of targetTrack to dbToFader(dbValue)
    end tell
    
    return {success:true, message:"Set " & trackName & " to " & dbValue & " dB"}
end setTrackVolume

-- Adjust track volume by dB (relative)
on adjustTrackVolume(trackName, dbChange)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set currentFader to volume of targetTrack
        set currentDb to faderToDb(currentFader)
        set newDb to currentDb + dbChange
        set volume of targetTrack to dbToFader(newDb)
    end tell
    
    set direction to "up"
    if dbChange < 0 then set direction to "down"
    
    return {success:true, message:trackName & " " & direction & " " & (abs of dbChange) & " dB"}
end adjustTrackVolume

-- Quick volume presets
on setVolumePreset(trackName, presetName)
    if presetName is "loud" then
        return setTrackVolume(trackName, 3)
    else if presetName is "normal" then
        return setTrackVolume(trackName, 0)
    else if presetName is "quiet" then
        return setTrackVolume(trackName, -6)
    else if presetName is "whisper" then
        return setTrackVolume(trackName, -12)
    else
        return {success:false, message:"Unknown preset: " & presetName}
    end if
end setVolumePreset

-- ============================================================
-- MUTE / SOLO
-- ============================================================

-- Mute track
on muteTrack(trackName)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set mute of targetTrack to true
    end tell
    
    return {success:true, message:"Muted " & trackName}
end muteTrack

-- Unmute track
on unmuteTrack(trackName)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set mute of targetTrack to false
    end tell
    
    return {success:true, message:"Unmuted " & trackName}
end unmuteTrack

-- Toggle mute
on toggleMute(trackName)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set isMuted to mute of targetTrack
        set mute of targetTrack to not isMuted
        
        if isMuted then
            set action to "unmuted"
        else
            set action to "muted"
        end if
    end tell
    
    return {success:true, message:trackName & " " & action}
end toggleMute

-- Solo track
on soloTrack(trackName)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set solo of targetTrack to true
    end tell
    
    return {success:true, message:"Soloed " & trackName}
end soloTrack

-- Unsolo track
on unsoloTrack(trackName)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set solo of targetTrack to false
    end tell
    
    return {success:true, message:"Unsoloed " & trackName}
end unsoloTrack

-- Unsolo all tracks
on unsoloAll()
    tell application "Logic Pro"
        set trackList to every track
        repeat with t in trackList
            set solo of t to false
        end repeat
    end tell
    
    return {success:true, message:"Cleared all solos"}
end unsoloAll

-- ============================================================
-- BATCH OPERATIONS
-- ============================================================

-- Adjust multiple tracks matching pattern
on adjustGroupVolume(trackPattern, dbChange)
    tell application "Logic Pro"
        set trackList to every track
        set matchedCount to 0
        
        repeat with t in trackList
            if name of t contains trackPattern then
                set currentFader to volume of t
                set currentDb to my faderToDb(currentFader)
                set newDb to currentDb + dbChange
                set volume of t to my dbToFader(newDb)
                set matchedCount to matchedCount + 1
            end if
        end repeat
    end tell
    
    if matchedCount is 0 then
        return {success:false, message:"No tracks found matching: " & trackPattern}
    end if
    
    set direction to "up"
    if dbChange < 0 then set direction to "down"
    
    return {success:true, message:matchedCount & " tracks " & direction & " " & (abs of dbChange) & " dB"}
end adjustGroupVolume

-- Reset all track volumes to 0dB
on resetAllVolumes()
    tell application "Logic Pro"
        set trackList to every track
        repeat with t in trackList
            set volume of t to 0.75 -- 0dB
        end repeat
    end tell
    
    return {success:true, message:"Reset all volumes to 0 dB"}
end resetAllVolumes

-- ============================================================
-- STATUS & INFO
-- ============================================================

-- Get track status
on getTrackStatus(trackName)
    set targetTrack to findTrack(trackName)
    if targetTrack is missing value then
        return {success:false, message:"Track not found: " & trackName}
    end if
    
    tell application "Logic Pro"
        set vol to volume of targetTrack
        set isMuted to mute of targetTrack
        set isSoloed to solo of targetTrack
        set dbValue to my faderToDb(vol)
    end tell
    
    set status to trackName & ": " & (round dbValue) & " dB"
    if isMuted then set status to status & " (muted)"
    if isSoloed then set status to status & " (solo)"
    
    return {success:true, message:status, volume:dbValue, muted:isMuted, soloed:isSoloed}
end getTrackStatus

-- List all tracks with volumes
on listAllTracks()
    tell application "Logic Pro"
        set trackList to every track
        set output to ""
        
        repeat with t in trackList
            set trackName to name of t
            set vol to volume of t
            set dbValue to my faderToDb(vol)
            set output to output & trackName & ": " & (round dbValue) & " dB" & return
        end repeat
    end tell
    
    return {success:true, message:output}
end listAllTracks

-- ============================================================
-- MAIN DISPATCH
-- ============================================================

on run argv
    -- Parse command-line arguments
    if (count of argv) is 0 then
        return {success:false, message:"No command specified"}
    end if
    
    set command to item 1 of argv
    
    -- Volume adjustment commands
    if command is "adjust" then
        set trackName to item 2 of argv
        set dbChange to item 3 of argv as number
        return adjustTrackVolume(trackName, dbChange)
        
    else if command is "set" then
        set trackName to item 2 of argv
        set dbValue to item 3 of argv as number
        return setTrackVolume(trackName, dbValue)
        
    else if command is "preset" then
        set trackName to item 2 of argv
        set presetName to item 3 of argv
        return setVolumePreset(trackName, presetName)
        
    -- Mute commands
    else if command is "mute" then
        set trackName to item 2 of argv
        return muteTrack(trackName)
        
    else if command is "unmute" then
        set trackName to item 2 of argv
        return unmuteTrack(trackName)
        
    else if command is "toggle-mute" then
        set trackName to item 2 of argv
        return toggleMute(trackName)
        
    -- Solo commands
    else if command is "solo" then
        set trackName to item 2 of argv
        return soloTrack(trackName)
        
    else if command is "unsolo" then
        set trackName to item 2 of argv
        return unsoloTrack(trackName)
        
    else if command is "unsolo-all" then
        return unsoloAll()
        
    -- Group commands
    else if command is "group-adjust" then
        set trackPattern to item 2 of argv
        set dbChange to item 3 of argv as number
        return adjustGroupVolume(trackPattern, dbChange)
        
    else if command is "reset-all" then
        return resetAllVolumes()
        
    -- Info commands
    else if command is "status" then
        set trackName to item 2 of argv
        return getTrackStatus(trackName)
        
    else if command is "list" then
        return listAllTracks()
        
    else
        return {success:false, message:"Unknown command: " & command}
    end if
end run
