# type-into-mc.ps1
# Types the current clipboard contents into the currently-focused window,
# one line at a time with Enter between lines. Built to get code into a
# CC:Tweaked `edit` buffer in Minecraft when native clipboard paste is
# unreliable and HTTP (wget/pastebin) is blocked by the server.
#
# Characters are injected via SendInput + KEYEVENTF_UNICODE rather than
# SendKeys. SendKeys simulates real key-presses, so a "/" press gets
# intercepted by Minecraft's "open chat/command" keybind before it ever
# reaches the CC:Tweaked text buffer, closing the editor mid-paste.
# KEYEVENTF_UNICODE delivers each character as a text event instead of a
# real key, so no keybind ever sees a literal "/" keypress -- only Enter is
# sent as an actual key, since the edit buffer needs a real newline.
#
# Usage:
#   powershell -File type-into-mc.ps1
#
# Workflow:
#   1. Copy the code you want (Ctrl+C) from wherever it lives.
#   2. In Minecraft, open the turtle's terminal and run: edit jarvis
#   3. Run this script. You get a countdown to alt-tab back into Minecraft
#      and make sure the edit buffer has focus/cursor is at the top.
#   4. Don't touch the keyboard/mouse while it types.
#   5. When done, Ctrl+S in-game to save, then exit the editor.
#
# Notes:
#   - -DelayMs controls per-character pause (ms). Increase if the game
#     drops input (happens under high server tick load / low FPS).
#   - -CountdownSeconds controls how long you get to alt-tab back in.

param(
    [int]$DelayMs = 0,

    [int]$CountdownSeconds = 5
)

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class InputSender {
    [StructLayout(LayoutKind.Sequential)]
    struct KEYBDINPUT {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct INPUT {
        public uint type;
        public KEYBDINPUT ki;
        // padding to match union size on 64-bit (INPUT is a union of
        // MOUSEINPUT/KEYBDINPUT/HARDWAREINPUT; KEYBDINPUT is smallest so we
        // pad explicitly rather than relying on struct layout tricks)
        public ulong padding;
    }

    const uint INPUT_KEYBOARD = 1;
    const uint KEYEVENTF_UNICODE = 0x0004;
    const uint KEYEVENTF_KEYUP = 0x0002;
    const ushort VK_RETURN = 0x0D;

    [DllImport("user32.dll", SetLastError = true)]
    static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    public static void SendUnicodeChar(char c) {
        INPUT[] inputs = new INPUT[2];
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].ki.wVk = 0;
        inputs[0].ki.wScan = c;
        inputs[0].ki.dwFlags = KEYEVENTF_UNICODE;

        inputs[1].type = INPUT_KEYBOARD;
        inputs[1].ki.wVk = 0;
        inputs[1].ki.wScan = c;
        inputs[1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;

        SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
    }

    public static void SendEnter() {
        INPUT[] inputs = new INPUT[2];
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].ki.wVk = VK_RETURN;
        inputs[0].ki.dwFlags = 0;

        inputs[1].type = INPUT_KEYBOARD;
        inputs[1].ki.wVk = VK_RETURN;
        inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;

        SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
    }
}
"@

$clipboardText = Get-Clipboard -Raw
if ([string]::IsNullOrEmpty($clipboardText)) {
    Write-Error "Clipboard is empty."
    exit 1
}

$lines = $clipboardText -split "`r`n|`n"

Write-Host "Loaded $($lines.Count) lines from clipboard."
Write-Host "Switch to Minecraft now. Typing starts in $CountdownSeconds seconds..."

for ($i = $CountdownSeconds; $i -gt 0; $i--) {
    Write-Host "$i..."
    Start-Sleep -Seconds 1
}

Write-Host "Typing now. Do not touch the keyboard or mouse."

$skippedLines = @()
$lineNum = 0

foreach ($line in $lines) {
    $lineNum++
    if ($line.Contains('/')) {
        $skippedLines += $lineNum
    }
    foreach ($ch in $line.ToCharArray()) {
        if ($ch -eq '/') {
            continue
        }
        [InputSender]::SendUnicodeChar($ch)
        if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }
    }
    [InputSender]::SendEnter()
    if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }
}

if ($skippedLines.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped '/' on line(s): $($skippedLines -join ', ') -- go fix those by hand."
}
Write-Host "Done. Save in-game with Ctrl+S, then exit the editor."
