; =============================================================================
;  VIRTUAL DESKTOP HOTKEYS
; =============================================================================
;
;  Win + 1 ... 5      go to desktop 1 ... 5
;  Win + Shift + 1..5 move the active window to desktop 1 ... 5
;  Win + S            toggle the "p1" desktop (press again to go back)
;  Win + W            cycle through desktops named w1, w2, w3...
;  Win + Shift + R    reload this script
;
;  Named desktops are created the first time you go to them.
;  Key bindings live in the HOTKEYS section at the bottom.
;
;  Modifiers:  # = Win   ^ = Ctrl   ! = Alt   + = Shift
;
;
;  SETUP
;  -----
;  1. Install AutoHotkey v2: https://www.autohotkey.com
;
;  2. Put VirtualDesktopAccessor.dll next to this script:
;     https://github.com/Ciantic/VirtualDesktopAccessor/releases
;     Requires Windows 11 24H2, build 26100.2605+ (check with `winver`).
;
;  3. Stop Windows from using Win+1..9 for taskbar apps (PowerShell):
;
;         reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisabledHotkeys /t REG_SZ /d 123456789 /f
;         Stop-Process -Name explorer
;
;  4. Run this file. To start it at login, put a shortcut to it in
;     shell:startup (Win+R).
;
;  Hotkeys bound here override the Windows defaults for the same keys.
;
; =============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force       ; re-running the script replaces the old instance


; =============================================================================
;  LIBRARY
; =============================================================================

desktopLibrary := DllCall("LoadLibrary", "Str", A_ScriptDir "\VirtualDesktopAccessor.dll", "Ptr")
if !desktopLibrary
{
    MsgBox("Could not load VirtualDesktopAccessor.dll`n`n"
        . "Make sure it is in the same folder as this script:`n" A_ScriptDir)
    ExitApp()
}

; Resolve each function once at startup.
LookUpFunction(functionName) => DllCall("GetProcAddress", "Ptr", desktopLibrary, "AStr", functionName, "Ptr")

libGoToDesktop      := LookUpFunction("GoToDesktopNumber")
libCountDesktops    := LookUpFunction("GetDesktopCount")
libGetDesktopName   := LookUpFunction("GetDesktopName")
libSetDesktopName   := LookUpFunction("SetDesktopName")
libCreateDesktop    := LookUpFunction("CreateDesktop")
libCurrentDesktop   := LookUpFunction("GetCurrentDesktopNumber")
libMoveWindow       := LookUpFunction("MoveWindowToDesktopNumber")

; Desktop to return to when a toggle hotkey is pressed again (-1 = none).
desktopBeforeToggle := -1


; =============================================================================
;  HELPERS
; =============================================================================
;  Desktop indexes are 0-based: the first desktop is 0.

SwitchToDesktop(desktopIndex)
{
    DllCall(libGoToDesktop, "Int", desktopIndex, "Int")
}

; Moves the active window to the desktop (you stay where you are).
MoveActiveWindowToDesktop(desktopIndex)
{
    activeWindow := WinExist("A")
    if !activeWindow
        return
    DllCall(libMoveWindow, "Ptr", activeWindow, "Int", desktopIndex, "Int")
}

; Returns the desktop's name, or "" if it has none.
GetDesktopName(desktopIndex)
{
    nameBuffer := Buffer(1024, 0)
    if DllCall(libGetDesktopName, "Int", desktopIndex, "Ptr", nameBuffer, "Ptr", nameBuffer.Size, "Int") = -1
        return ""
    return StrGet(nameBuffer, "UTF-8")
}

; Returns the index of the desktop with this name (case-insensitive), or -1.
FindDesktopByName(desktopName)
{
    desktopCount := DllCall(libCountDesktops, "Int")
    Loop desktopCount
    {
        desktopIndex := A_Index - 1          ; A_Index is 1-based
        if GetDesktopName(desktopIndex) = desktopName
            return desktopIndex
    }
    return -1
}

; Goes to the named desktop, creating it first if it doesn't exist.
SwitchToNamedDesktop(desktopName)
{
    desktopIndex := FindDesktopByName(desktopName)
    if desktopIndex < 0
    {
        DllCall(libCreateDesktop, "Int")
        desktopIndex := DllCall(libCountDesktops, "Int") - 1   ; new desktops go at the end

        nameAsUtf8 := Buffer(StrPut(desktopName, "UTF-8"))
        StrPut(desktopName, nameAsUtf8, "UTF-8")
        DllCall(libSetDesktopName, "Int", desktopIndex, "Ptr", nameAsUtf8, "Int")
    }
    SwitchToDesktop(desktopIndex)
}

; Like SwitchToNamedDesktop, but if you're already there, goes back to the
; desktop you came from.
ToggleNamedDesktop(desktopName)
{
    global desktopBeforeToggle
    currentDesktop := DllCall(libCurrentDesktop, "Int")

    if currentDesktop = FindDesktopByName(desktopName) && desktopBeforeToggle >= 0
    {
        SwitchToDesktop(desktopBeforeToggle)
        return
    }
    desktopBeforeToggle := currentDesktop
    SwitchToNamedDesktop(desktopName)
}

; Cycles through desktops named <prefix><number> (e.g. w1, w2, w3) in
; Task View order. Starts at the first match if you're not on one, and
; creates <prefix>1 if none exist.
CycleNumberedDesktops(prefix)
{
    matchingDesktops := []
    Loop DllCall(libCountDesktops, "Int")
    {
        desktopIndex := A_Index - 1
        if RegExMatch(GetDesktopName(desktopIndex), "i)^\Q" prefix "\E\d+$")
            matchingDesktops.Push(desktopIndex)
    }

    if matchingDesktops.Length = 0
    {
        SwitchToNamedDesktop(prefix "1")
        return
    }

    ; Go to the next match after the current desktop, wrapping around.
    currentDesktop := DllCall(libCurrentDesktop, "Int")
    for position, desktopIndex in matchingDesktops
    {
        if desktopIndex = currentDesktop
        {
            nextPosition := Mod(position, matchingDesktops.Length) + 1
            SwitchToDesktop(matchingDesktops[nextPosition])
            return
        }
    }
    SwitchToDesktop(matchingDesktops[1])
}


; =============================================================================
;  HOTKEYS
; =============================================================================
;  Press Win+Shift+R after editing to reload.

; Numbered desktops (0-based: Win+1 -> desktop 0).
; Extend with e.g. #6::SwitchToDesktop(5) and add 6 to DisabledHotkeys.
#1::SwitchToDesktop(0)
#2::SwitchToDesktop(1)
#3::SwitchToDesktop(2)
#4::SwitchToDesktop(3)
#5::SwitchToDesktop(4)

; Move the active window to a numbered desktop.
#+1::MoveActiveWindowToDesktop(0)
#+2::MoveActiveWindowToDesktop(1)
#+3::MoveActiveWindowToDesktop(2)
#+4::MoveActiveWindowToDesktop(3)
#+5::MoveActiveWindowToDesktop(4)

; Named desktops, e.g.  #m::SwitchToNamedDesktop("Mail")

; Toggle: press again to go back.
#s::ToggleNamedDesktop("p1")

; Cycle through w1, w2, w3... (rename a desktop in Win+Tab to add it).
#w::CycleNumberedDesktops("w")

; Reload this script.
#+r::Reload()
