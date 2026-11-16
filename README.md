# AutoHotKey-DesktopManager

Keyboard shortcuts for Windows 11 virtual desktops, built on AutoHotkey v2 and
[VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor).

Jump straight to a desktop, send windows to other desktops, and keep named
desktops one keypress away. Named desktops are created the first time you go to
them.

## Hotkeys

| Hotkey               | Action                                                        |
| -------------------- | ------------------------------------------------------------- |
| `Win + 1` … `5`      | Go to desktop 1 … 5                                           |
| `Win + Shift + 1` … `5` | Move the active window to desktop 1 … 5 (you stay put)     |
| `Win + S`            | Toggle the desktop named `p1`; press again to go back         |
| `Win + W`            | Cycle through desktops named `w1`, `w2`, `w3`, …              |
| `Win + Shift + R`    | Reload the script                                             |

These override the Windows defaults for the same keys (for example, `Win + S`
normally opens Search).

## Requirements

- Windows 11 24H2, build 26100.2605 or later (check with `winver`)
- [AutoHotkey v2](https://www.autohotkey.com)
- `VirtualDesktopAccessor.dll` from the
  [VirtualDesktopAccessor releases](https://github.com/Ciantic/VirtualDesktopAccessor/releases)

The DLL is not included in this repository.

## Setup

1. Install AutoHotkey v2.
2. Download `VirtualDesktopAccessor.dll` and put it in the same folder as
   `DesktopMan.ahk`.
3. Stop Windows from using `Win + 1..9` to launch taskbar apps. In PowerShell:

   ```powershell
   reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisabledHotkeys /t REG_SZ /d 123456789 /f
   Stop-Process -Name explorer
   ```

   Explorer restarts on its own.
4. Run `DesktopMan.ahk`.
5. Optional: to start it at login, press `Win + R`, open `shell:startup`, and
   put a shortcut to `DesktopMan.ahk` in that folder.

## Named and cycling desktops

- **Toggle (`Win + S`)** goes to the desktop named `p1`, creating it if needed.
  Pressing it again while on `p1` returns you to the desktop you came from.
- **Cycle (`Win + W`)** steps through every desktop whose name is `w` followed
  by a number (`w1`, `w2`, …), in Task View order, wrapping around. If none
  exist, it creates `w1`. To add a desktop to the cycle, rename it in Task View
  (`Win + Tab`), e.g. to `w2`. Name matching is case-insensitive.

## Customizing

All bindings are in the `HOTKEYS` section at the bottom of `DesktopMan.ahk`.
Edit them, then press `Win + Shift + R` to reload.

Modifier symbols: `#` = Win, `^` = Ctrl, `!` = Alt, `+` = Shift.
Desktop indexes in the script are 0-based (`Win + 1` → desktop `0`).

Examples:

```ahk
; Jump to (or create) a desktop named "Mail"
#m::SwitchToNamedDesktop("Mail")

; Toggle a different named desktop
#d::ToggleNamedDesktop("Dev")

; Cycle desktops named t1, t2, t3...
#t::CycleNumberedDesktops("t")

; Add a sixth numbered desktop
#6::SwitchToDesktop(5)
#+6::MoveActiveWindowToDesktop(5)
```

If you bind `Win + 6` or higher, make sure that digit is in the
`DisabledHotkeys` registry value from step 3.

## Troubleshooting

- **"Could not load VirtualDesktopAccessor.dll"**: the DLL is missing or not in
  the same folder as the script.
- **Hotkeys do nothing or crash**: your Windows build may not match the DLL
  version. Check `winver` and download the matching release.
- **`Win + number` still opens taskbar apps**: redo step 3 and make sure
  Explorer restarted.

## License

[MIT](LICENSE)
