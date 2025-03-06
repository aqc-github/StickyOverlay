import Cocoa

@objc class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    var statusItem: NSStatusItem!
    var pinTrayWindow: PinTrayWindow!
    private var inputMenu: NSMenu!
    private var textField: NSTextField!
    private var stickyNotes: [StickyNoteWindow] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the menu bar tray
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "Pin Tray")
            button.action = #selector(showInputMenu)
            button.target = self
        }

        // Initialize the pin tray window
        pinTrayWindow = PinTrayWindow()

        // Load existing sticky notes from UserDefaults
        loadStickyNotes()

        // Add a global event monitor for Enter key to create sticky notes
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.inputMenu != nil && event.keyCode == 36 && !(self?.textField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty ?? true) {
                self?.createStickyNoteFromInput()
                self?.inputMenu.cancelTracking()
                return nil
            }
            return event
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc private func showInputMenu() {
        inputMenu = NSMenu(title: "New Sticky")
        inputMenu.delegate = self
        
        let menuItem = NSMenuItem()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
        
        textField = NSTextField(frame: NSRect(x: 5, y: 5, width: 190, height: 20))
        textField.placeholderString = "New Sticky Note"
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.delegate = self
        view.addSubview(textField)
        
        menuItem.view = view
        inputMenu.addItem(menuItem)
        inputMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: statusItem.button)
    }

    private func createStickyNoteFromInput() {
        let text = textField.stringValue.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty {
            addNewStickyNote(withText: text)
        }
        textField.stringValue = ""
    }

    private func addNewStickyNote(withText text: String) {
        let stickyNote = StickyNoteWindow(text: text, pinTrayWindow: pinTrayWindow, onPin: { [weak self] stickyNote in
            self?.pinStickyNote(stickyNote)
        })
        let offset = CGFloat(stickyNotes.count) * 40
        let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 1280, height: 800)
        let newFrame = NSRect(
            x: screenSize.width / 2 - 100 + offset,
            y: screenSize.height / 2 - 75 - offset,
            width: 200,
            height: 150
        )
        stickyNote.setFrame(newFrame, display: true)
        stickyNotes.append(stickyNote)
        saveStickyNotes()
    }

    private func pinStickyNote(_ stickyNote: StickyNoteWindow) {
        if let index = stickyNotes.firstIndex(of: stickyNote) {
            stickyNotes.remove(at: index)
            saveStickyNotes()
            print("Pinned sticky note removed, new count: \(stickyNotes.count)")
        }
    }

    private func loadStickyNotes() {
        if let savedNotes = UserDefaults.standard.array(forKey: "StickyNotes") as? [[String: Any]] {
            for noteData in savedNotes {
                guard let frameDict = noteData["frame"] as? [String: CGFloat],
                      let text = noteData["text"] as? String else { continue }
                let frame = NSRect(
                    x: frameDict["x"] ?? 0,
                    y: frameDict["y"] ?? 0,
                    width: frameDict["width"] ?? 200,
                    height: frameDict["height"] ?? 150
                )
                let stickyNote = StickyNoteWindow(text: text, pinTrayWindow: pinTrayWindow, onPin: { [weak self] stickyNote in
                    self?.pinStickyNote(stickyNote)
                })
                stickyNote.setFrame(frame, display: true)
                stickyNotes.append(stickyNote)
            }
            print("Loaded \(stickyNotes.count) sticky notes")
        } else {
            print("No saved sticky notes found")
        }
    }

    private func saveStickyNotes() {
        let notesData = stickyNotes.map { note -> [String: Any] in
            let frame = note.frame
            return [
                "frame": [
                    "x": frame.origin.x,
                    "y": frame.origin.y,
                    "width": frame.size.width,
                    "height": frame.size.height
                ],
                "text": note.textField.stringValue
            ]
        }
        UserDefaults.standard.set(notesData, forKey: "StickyNotes")
        print("Saved \(notesData.count) sticky notes to UserDefaults")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // No additional cleanup needed as sticky notes are saved on every change
    }
}

// MARK: - NSMenuDelegate
extension AppDelegate {
    func menuDidClose(_ menu: NSMenu) {
        inputMenu = nil
        textField = nil
    }
}

// MARK: - NSTextFieldDelegate
extension AppDelegate: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            createStickyNoteFromInput()
            inputMenu?.cancelTracking()
            return true
        }
        return false
    }
}
