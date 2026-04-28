; This script is a SSE Client demo that does not block the UI by spawning another AHK process (SSE_Watcher.exe) and exchanges data with it using WM_Copydata by using the Talk library by Avi Aryan, it has an OnExit routine so that when not active it can close the spawned watcher process.
#NoEnv
#SingleInstance Off
SetBatchLines, -1
#Include <talk>
global watcherProcess := "SSE_Watcher.exe"
global watcherPID := 0
global windowTitle := "SSE Events " RegExReplace(RandomStr(), "\W", "i")

if(!FileExist(watcherProcess)) {
	MsgBox 0x10, Error, Plase`, compile SSE_Watcher.exe first!
	ExitApp
}

OnExit("CloseSSE")

global sender := new talk("Background")
dataRcv := "initial"

Gui, Add, Text, w300 h100 vdataRcvTxt, ---
Gui, Show, w300 h100, % windowTitle ; Title is case sensitive for receiver, here we randomize title so that we can demo multiple clients with dynamic watchers

Run, % watcherProcess " """ windowTitle """",,, watcherPID 
return

PrintData:
	GuiControl,, dataRcvTxt, % dataRcv
return

GuiClose:
GuiEscape:
	ExitApp
	
CloseSSE(ExitReason, ExitCode) {
	global watcherPID
	Run, taskkill /PID %watcherPID% /F,, Hide
}

RandomStr(l = 16, i = 48, x = 122) { ; length, lowest and highest Asc value
	Loop, %l% {
		Random, r, i, x
		s .= Chr(r)
	}
	Return, s
}