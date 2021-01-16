; Easy Access to Currently Opened Folders 
; Original author: Savage
;  - Fork by Leeroy
;  -- Fork by Valentin
; Invoke a menu of currently opened folders when you click 
; the middle mouse button inside Open / Save as dialogs or 
; Console (command prompt) windows. Select one of these 
; locations and the script will navigate there.

; CONFIG: CHOOSE A DIFFERENT HOTKEY
; You could also use a modified mouse button (such as ^MButton) or
; a keyboard hotkey. In the case of MButton, the tilde (~) prefix
; is used so that MButton's normal functionality is not lost when
; you click in other window types, such as a browser.

; Middle-click like original script by Savage
f_Hotkey = ~MButton
; Ctrl+G like in Listary
f_HotkeyCombo = ~^g

; END OF CONFIGURATION SECTION
; Do not make changes below this point unless you want to change
; the basic functionality of the script.

#NoTrayIcon
#SingleInstance, force ; Needed since the hotkey is dynamically created.

global currentPathExplorer

; Auto-execute section.
Hotkey, %f_Hotkey%, f_DisplayMenu
Hotkey, %f_HotkeyCombo%, f_DisplayMenu
return 

GetActiveExplorer() {
    static objShell := ComObjCreate("Shell.Application")
    WinHWND := WinActive("A")    ; Active window
    for Item in objShell.Windows
        if (Item.HWND = WinHWND)
            return Item        ; Return active window object
    return -1    ; No explorer windows match active window
}

NavRun(Path) {
    if (-1 != objIE := GetActiveExplorer())
        objIE.Navigate(Path)
    ;else
        ;Run, % Path
}

; Navigate to the chosen path
f_Navigate:
; Set destination path to be the selected menu item
f_path = %A_ThisMenuItem%

if f_path =
  return

if f_class = #32770 ; It's a dialog.
{
  ; Activate the window so that if the user is middle-clicking
  ; outside the dialog, subsequent clicks will also work:
  WinActivate ahk_id %f_window_id%
  ; Ctrl+L to convert Address bar from breadcrumbs to editbox
  Send ^{l}
  ; Wait for focus
  Sleep 50
  ; The control that's focused after Alt+D is thus the address bar
  ControlGetFocus, addressbar, a
  ; Put in the chosen path
  ControlSetText %addressbar%, % f_path, a
  ; Go there
  ControlSend %addressbar%, {Enter}, a
  ; Return focus to filename field
  ControlFocus Edit1, a
  return
}

if f_class = CabinetWClass
{
  NavRun(f_path)
  return
}

; In a console window, pushd to that directory
else if f_class = ConsoleWindowClass
{
  ; Because sometimes the mclick deactivates it.
  WinActivate, ahk_id %f_window_id%
  ; This will be in effect only for the duration of this thread.
  SetKeyDelay, 0
  ; Clear existing text from prompt and send pushd command
  Send, {Esc}pushd "%f_path%"{Enter}
  return
}

else if f_class = VirtualConsoleClass ; Support cmder
{
  ; Because sometimes the mclick deactivates it.
  WinActivate, ahk_id %f_window_id%
  ; This will be in effect only for the duration of this thread.
  SetKeyDelay, 0
  ; Clear existing text from prompt and send pushd command
  Send, {Esc}pushd "%f_path%"{Enter}
  return
}
return


RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

; Display the menu
f_DisplayMenu:
; Get active window identifiers for use in f_Navigate
WinGet, f_window_id, ID, a
WinGetClass, f_class, a

; Don't display menu unless it's a dialog or console window
if f_class not in #32770,ConsoleWindowClass,VirtualConsoleClass,CabinetWClass
  return
; Otherwise, put together the menu
WinGetTitle, currentPathExplorer, ahk_class %f_class%
;msgbox, % "test " . currentPathExplorer

GetCurrentPaths() {
  For pwb in ComObjCreate("Shell.Application").Windows
  ; Exclude special locations like Computer, Recycle Bin, Search Results
  If InStr(pwb.FullName, "explorer.exe") && InStr(pwb.LocationURL, "file:///") && pwb.document.folder.self.path != currentPathExplorer
  {
    ;msgbox, % "path: " . pwb.document.folder.self.path . " active: " . currentPathExplorer
    ; Get paths of currently opened Explorer windows
    Menu, CurrentLocations, Add, % pwb.document.folder.self.path, f_Navigate
    IniRead, iconpath, % pwb.document.folder.self.path . "\desktop.ini", .ShellClassInfo, IconResource
    
    ; Not same default folder icon for all (modif Val)
    if % iconpath != "ERROR" {
      icontab := StrSplit(iconpath, ",")
      if % icontab[2] > 0 {
        icontab[2] := icontab[2]+1 ; Pour contrer bug décalage icon
      }

      if StrSplit(icontab[1], ":").MaxIndex() < 2 && StrSplit(icontab[1], "%").MaxIndex() < 3 {  ; Pas de ":" et de "%...%" dans le path vers l'icone
        ;MsgBox, % "Path local au dossier " . pwb.document.folder.self.path
        icontab[1] := pwb.document.folder.self.path . "\" . icontab[1]
      }

      icontab[1] := StrReplace(icontab[1], "%userprofile%", USERPROFILE)  ; %userprofile% non géré par autohotkey
      
      ;MsgBox, % "path " . pwb.document.folder.self.path . " " . icontab[1] . " OK " .  icontab[2] . " OK " . testtt
      Menu, CurrentLocations, Icon, % pwb.document.folder.self.path, % icontab[1], % icontab[2]
    }
    else {
      Menu, CurrentLocations, Icon, % pwb.document.folder.self.path, %A_WinDir%\system32\imageres.dll, 4
    }
  }
}
; Get current paths and build menu with them
GetCurrentPaths()
; Don't halt the show if there are no paths and the menu is empty
Menu, CurrentLocations, UseErrorLevel
; Present the menu
Menu, CurrentLocations, Show
; If it doesn't exist show reassuring tooltip
If ErrorLevel
{
  ; Oh! Look at that taskbar. It's empty.
  ToolTip, No folders open
  SetTimer, RemoveToolTip, 1000
}
; Destroy the menu so it doesn't remember previously opened windows
Menu, CurrentLocations, Delete
return
