# TETR.IO ad blocker

Blocks TETR.IO Desktop's in-game/menu ads without modifying the game files, using a Chromium launch flag that makes the ad networks' hostnames fail to resolve.

## Files

- `block-tetrio-ads.cmd` — double-click wrapper.
- `block-tetrio-ads.ps1` — the actual script.

Keep both files in the same folder.

## Requirements

- Windows 10/11 with TETR.IO Desktop installed.
- PowerShell 5.1 (already included with Windows).
- No admin rights required.

## Apply

1. Install TETR.IO Desktop and launch it once (this registers the `tetrio://` protocol handler).
2. Copy both files above to a folder on the new PC.
3. Double-click `block-tetrio-ads.cmd`.
4. Read the output and press any key to close.

Or, from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\block-tetrio-ads.ps1
```

The script automatically finds the TETR.IO executable, patches every matching Desktop / Start Menu / taskbar shortcut, and patches the `tetrio://` protocol handler. It is safe to run multiple times.

## What it changes

- Adds `--host-resolver-rules="MAP ... ~NOTFOUND"` to shortcut arguments for:
  - Freestar / pub.network
  - Google AdSense / DoubleClick
  - Amazon Publisher Services
  - Rubicon, PubMatic, AdNexus, Criteo, Index Exchange, and other ad bidders
- Updates `HKEY_CURRENT_USER\Software\Classes\tetrio\shell\open\command` so `tetrio://` links also launch with the flag.

Nothing in the TETR.IO install directory is modified, so auto-updates will not overwrite the fix.

## Important

- Launch TETR.IO from a patched shortcut. Running `TETR.IO.exe` directly from File Explorer will not have the flag.
- If TETR.IO is already open, close it fully first (it only allows one instance at a time).
- If you create a new shortcut later, re-run the script.
- If you reinstall Windows or TETR.IO, copy the two files over and run the script again.

## Undo

From PowerShell, in the folder containing the scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\block-tetrio-ads.ps1 -Uninstall
```

This removes the flag from all shortcuts and restores the original protocol handler command.

## Troubleshooting

- **"TETR.IO.exe not found"** — install TETR.IO Desktop first, then run the script again.
- **Windows SmartScreen warning** — right-click the `.cmd` file, choose *Properties*, check *Unblock*, then Apply.
- **Ads still appear** — make sure you launched from a patched shortcut and that no older TETR.IO process is still running.
