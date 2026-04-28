; This script is a SSE Client demo that blocks the UI while not receiving any data due to AHK's single thread nature
#NoEnv
#SingleInstance Off
SetBatchLines, -1

global url := "http://127.0.0.1:8000/events"
global buffer := ""
global hInternet := 0
global hUrl := 0
global stop := false

Gui, Add, Edit, w700 h380 vLog ReadOnly
Gui, Show,, SSE Client Example

AppendLog("Connected to " . url . " ...")

SetTimer, StartSSE, -10
return


StartSSE:
    ConnectAndReadSSE(url)
return


ConnectAndReadSSE(url) {
    global hInternet, hUrl, stop

    agent := "AutoHotkey-SSE"
    headers := "Accept: text/event-stream`r`nCache-Control: no-cache`r`n"

    ; INTERNET_OPEN_TYPE_PRECONFIG = 0
	hInternet := DllCall("wininet\InternetOpen"
		, "Str", agent
		, "UInt", 0
		, "Ptr", 0
		, "Ptr", 0
		, "UInt", 0
		, "Ptr")

	if (!hInternet) {
		AppendLog("[ERROR] InternetOpen falló. A_LastError=" . A_LastError)
		return
	}

	timeout := 120000 ; 120 segundos

	DllCall("wininet\InternetSetOption"
		, "Ptr", hInternet
		, "UInt", 6
		, "UIntP", timeout
		, "UInt", 4)

    ; Flags:
    ; INTERNET_FLAG_RELOAD         = 0x80000000
    ; INTERNET_FLAG_NO_CACHE_WRITE = 0x04000000
    ; INTERNET_FLAG_PRAGMA_NOCACHE = 0x00000100
    flags := 0x80000000 | 0x04000000 | 0x00000100

    hUrl := DllCall("wininet\InternetOpenUrl"
        , "Ptr", hInternet
        , "Str", url
        , "Str", headers
        , "UInt", StrLen(headers)
        , "UInt", flags
        , "Ptr", 0
        , "Ptr")

    if (!hUrl) {
        AppendLog("[ERROR] InternetOpenUrl falló. A_LastError=" . A_LastError)
        DllCall("wininet\InternetCloseHandle", "Ptr", hInternet)
        hInternet := 0
        return
    }

    AppendLog("Connected. Waiting for events...")

    Loop {
        if (stop)
            break

        VarSetCapacity(buf, 4096, 0)
        bytesRead := 0

        ok := DllCall("wininet\InternetReadFile"
            , "Ptr", hUrl
            , "Ptr", &buf
            , "UInt", 4096
            , "UIntP", bytesRead)

        if (!ok) {
            AppendLog("[ERROR] InternetReadFile failed. A_LastError=" . A_LastError)
            break
        }

        if (bytesRead = 0) {
            AppendLog("[Connection closed by the server]")
            break
        }

        chunk := StrGet(&buf, bytesRead, "UTF-8")
        ProcessSSEChunk(chunk)

        Sleep, 10
    }

    if (hUrl) {
        DllCall("wininet\InternetCloseHandle", "Ptr", hUrl)
        hUrl := 0
    }

    if (hInternet) {
        DllCall("wininet\InternetCloseHandle", "Ptr", hInternet)
        hInternet := 0
    }
}


ProcessSSEChunk(chunk) {
    global buffer

    buffer .= chunk

    ; Normalize line breaks
    buffer := StrReplace(buffer, "`r`n", "`n")
    buffer := StrReplace(buffer, "`r", "`n")

    ; SSE Event ends with empty line: `n`n
    while (pos := InStr(buffer, "`n`n")) {
        rawEvent := SubStr(buffer, 1, pos - 1)
        buffer := SubStr(buffer, pos + 2)

        data := ""

        Loop, Parse, rawEvent, `n
        {
            line := A_LoopField

            ; SSE comment, for example connected:
            ; : connected
            if (SubStr(line, 1, 1) = ":")
                continue

            ; Normal SSE line:
            ; data: message
            if (SubStr(line, 1, 5) = "data:")
                data .= Trim(SubStr(line, 6)) "`n"
        }

        if (data != "")
            AppendLog(RTrim(data, "`n"))
    }
}


AppendLog(text) {
    GuiControlGet, oldLog,, Log
    GuiControl,, Log, % oldLog . text . "`r`n"
}


GuiClose:
    stop := true

    if (hUrl)
        DllCall("wininet\InternetCloseHandle", "Ptr", hUrl)

    if (hInternet)
        DllCall("wininet\InternetCloseHandle", "Ptr", hInternet)

    ExitApp
return