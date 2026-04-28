# SSE Client Example

This is an implementation of two ways of adding SSE event reader support for AutoHotkey scripts without relying on JavaScript.

## General Considerations

- A feedback ping is mandatory every now and then, otherwise the connection may end up hanging up due to inactivity.

- I have established my SSE server written in go to send a ping every 10s ``heartbeatTicker``.

- I have established AutoHotkey to have a timeout of 120s so that temporarely service downtime does not break the running process.

```autohotkey
timeout := 120000 ; 120 seconds
```

- There are no reconnections in this implementation right now, you'd have to manage them on your own, be it with a settimer, a loop or a new "thread" on error if using the async version.

## Synchronous Example

- The synchronous example does not require a GUI since everything is self-contained in the script.

- There is a huge drawback to this version, since AutoHotkey is single-threaded, the main thread is effectively locked until the next ping or message is received. This results in GUIs not responding, script not doing anything else while receiving a message, etc. You can use this version for example for showing notifications or triggering other events, but overall I would not recommend using it except for logging SSE events.

## Asynchronous Example

- This method uses a "hack" to provide a feeling of concurrency by starting a secondary process, the "SSE_Watcher" which is independent to the main script's process.
  
  It receives the GUI name that spawned it as its main parameter and is able to communicate with its parent process asynchronously via Windows events (WM_COPYDATA).
  
  This watcher gets locked while receiving SSE events but that is its only task beside sending back the SSE response to the parent script using the aforementioned Windows messaging method for IPC.
- It is recommended for SSE_Watcher.ahk to be compiled due to AutoHotkey path compatibility.
- The main script is no longer blocked by the response request, those responses come from the watcher process associated to it.
- This method requires a GUI (can be hidden) to retrieve changes from the other process.




