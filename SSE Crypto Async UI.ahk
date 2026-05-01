; Async SSE cryptocurrency dashboard.
; Starts SSE_Watcher.ahk in the background and receives /crypto snapshots through WM_COPYDATA.
; Could be made much easier with cJSON lib or similar.
#NoEnv
#SingleInstance Off
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
#Include <talk>

global watcherProcess := "SSE_Watcher.ahk"
global watcherPID := 0
global streamUrl := "http://127.0.0.1:8000/crypto"
global windowTitle := "SSE Crypto " RegExReplace(RandomStr(), "\W", "i")
global dataRcv := ""
global symbolRows := {}
global previousPrices := {}
global lastUpdate := ""

if (!FileExist(watcherProcess)) {
	MsgBox 0x10, Error, Could not find SSE_Watcher.ahk!
	ExitApp
}

OnExit("CloseSSE")

global sender := new talk("Background")

Gui, Margin, 14, 12
Gui, Font, s10, Segoe UI
Gui, Add, Text, xm ym w780 vHeaderText, Connecting to %streamUrl% ...
Gui, Font, s9, Segoe UI
Gui, Add, ListView, xm y+10 w900 h330 vCryptoList Grid AltSubmit, #|Symbol|Name|Price USD|1h pct|24h pct|Volume 24h|Market Cap|Trend
Gui, Add, Text, xm y+10 w900 vStatusText, Waiting for first crypto snapshot...

LV_ModifyCol(1, 35)
LV_ModifyCol(2, 70)
LV_ModifyCol(3, 120)
LV_ModifyCol(4, 105)
LV_ModifyCol(5, 70)
LV_ModifyCol(6, 70)
LV_ModifyCol(7, 110)
LV_ModifyCol(8, 115)
LV_ModifyCol(9, 75)

Gui, Show, w930 h420, % windowTitle

Run, % watcherProcess " """ windowTitle """ """ streamUrl """",,, watcherPID
return

PrintData:
	if (SubStr(dataRcv, 1, 1) = "[")
		UpdateCryptoPanel(dataRcv)
	else
		GuiControl,, StatusText, % dataRcv
return

UpdateCryptoPanel(json) {
	global symbolRows, previousPrices, lastUpdate

	pos := 1
	rowNumber := 0
	gainers := 0
	losers := 0
	pattern := "\{""name"":""([^""]+)"",""symbol"":""([^""]+)"",""price"":([0-9.]+),""change1h"":(-?[0-9.]+),""change24h"":(-?[0-9.]+),""volume24h"":([0-9.]+),""marketCap"":([0-9.]+)\}"

	Gui, ListView, CryptoList

	while (pos := RegExMatch(json, pattern, coin, pos)) {
		rowNumber++
		name := coin1
		symbol := coin2
		price := coin3 + 0
		change1h := coin4 + 0
		change24h := coin5 + 0
		volume24h := coin6 + 0
		marketCap := coin7 + 0

		trend := "FLAT"
		if (previousPrices.HasKey(symbol)) {
			if (price > previousPrices[symbol])
				trend := "UP"
			else if (price < previousPrices[symbol])
				trend := "DOWN"
		}

		if (change24h >= 0)
			gainers++
		else
			losers++

		previousPrices[symbol] := price
		priceText := FormatPrice(price)
		change1hText := FormatSigned(change1h) "%"
		change24hText := FormatSigned(change24h) "%"
		volumeText := FormatLarge(volume24h)
		marketCapText := FormatLarge(marketCap)

		if (!symbolRows.HasKey(symbol)) {
			row := LV_Add("", rowNumber, symbol, name, priceText, change1hText, change24hText, volumeText, marketCapText, trend)
			symbolRows[symbol] := row
		} else {
			row := symbolRows[symbol]
			LV_Modify(row, "", rowNumber, symbol, name, priceText, change1hText, change24hText, volumeText, marketCapText, trend)
		}

		pos += StrLen(coin)
	}

	lastUpdate := A_Hour ":" A_Min ":" A_Sec
	GuiControl,, HeaderText, % "Crypto SSE stream: " rowNumber " assets updating every 3 seconds"
	GuiControl,, StatusText, % "Last update " lastUpdate "    Gainers: " gainers "    Losers: " losers
}

FormatPrice(value) {
	if (value < 10)
		return "$" Format("{:.4f}", value)
	return "$" Format("{:.2f}", value)
}

FormatSigned(value) {
	if (value > 0)
		return "+" Format("{:.2f}", value)
	return Format("{:.2f}", value)
}

FormatLarge(value) {
	if (value >= 1000000000000)
		return "$" Format("{:.2f}", value / 1000000000000) "T"
	if (value >= 1000000000)
		return "$" Format("{:.2f}", value / 1000000000) "B"
	if (value >= 1000000)
		return "$" Format("{:.2f}", value / 1000000) "M"
	if (value >= 1000)
		return "$" Format("{:.2f}", value / 1000) "K"
	return "$" Format("{:.0f}", value)
}

GuiClose:
GuiEscape:
	ExitApp

CloseSSE(ExitReason, ExitCode) {
	global watcherPID
	if (watcherPID)
		Run, taskkill /PID %watcherPID% /F,, Hide
}

RandomStr(l = 16, i = 48, x = 122) {
	Loop, %l% {
		Random, r, i, x
		s .= Chr(r)
	}
	Return, s
}
