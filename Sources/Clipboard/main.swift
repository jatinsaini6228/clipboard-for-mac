import AppKit
import ClipboardKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Install signal handlers so terminating from terminal cleanly persists storage
signal(SIGINT) { _ in
    AppState.shared.storage.save(synchronous: true)
    exit(0)
}
signal(SIGTERM) { _ in
    AppState.shared.storage.save(synchronous: true)
    exit(0)
}

app.run()
