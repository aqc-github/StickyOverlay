import Cocoa

class StickyOverlayViewController: NSViewController {
    private var stickyNotes: [StickyNoteWindow] = []
    private let statusItem: NSStatusItem
    private let pinTrayWindow: PinTrayWindow
    private var isDragging: Bool = false
    private var draggedWindow: StickyNoteWindow?

    init(statusItem: NSStatusItem, pinTrayWindow: PinTrayWindow) {
        self.statusItem = statusItem
        self.pinTrayWindow = pinTrayWindow
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect.zero)
        print("StickyOverlayViewController loadView called")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("StickyOverlayViewController viewDidLoad called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadStickyNotes()
        }
    }

    private func loadStickyNotes() {
        print("Loading sticky notes from UserDefaults")
        if let savedNotes = UserDefaults.standard.array(forKey: "StickyNotes") as? [[String: Any]] {
            print("Found \(savedNotes.count) saved sticky notes")
            for noteData in savedNotes {
                guard let frameDict = noteData["frame"] as? [String: CGFloat],
                      let text = noteData["text"] as? String else { continue }
                let frame = NSRect(
                    x: frameDict["x"] ?? 0,
                    y: frameDict["y"] ?? 0,
                    width: frameDict["width"] ?? 200,
                    height: frameDict["height"] ?? 150
                )
                let stickyNote = StickyNoteWindow(controller: self)
                stickyNote.setFrame(frame, display: true)
                stickyNote.textField.stringValue = text
                stickyNotes.append(stickyNote)
                print("Loaded sticky note with frame: \(frame), text: \(text)")
            }
        } else {
            print("No saved sticky notes, creating a new one")
            addNewStickyNote()
        }
        print("Sticky note count: \(stickyNotes.count)")
    }

    @objc func addNewStickyNote() {
        print("Adding new sticky note")
        let stickyNote = StickyNoteWindow(controller: self)
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
        print("Created sticky note with frame: \(newFrame)")
        saveStickyNotes()
        print("Sticky note count: \(stickyNotes.count)")
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

    func didBeginDragging(_ window: StickyNoteWindow) {
        isDragging = true
        draggedWindow = window
        checkProximityToPinIcon()
    }

    func didDrag(_ window: StickyNoteWindow) {
        checkProximityToPinIcon()
        window.highlightForPinning(isOverTray(window))
    }

    func didEndDragging(_ window: StickyNoteWindow) {
        isDragging = false
        if isOverTray(window) {
            print("Sticky note dropped on tray")
            window.animateAndClose(to: pinTrayWindow.frame.origin)
        } else {
            print("Sticky note not dropped on tray")
        }
        pinTrayWindow.setIsVisible(false)
        draggedWindow = nil
    }

    private func checkProximityToPinIcon() {
        guard isDragging, let draggedWindow = draggedWindow,
              let button = statusItem.button,
              let buttonWindow = button.window else {
            print("Hiding pin tray: not dragging or no button")
            pinTrayWindow.setIsVisible(false)
            return
        }
        
        let buttonFrameInScreen = buttonWindow.convertToScreen(button.frame)
        let windowFrameInScreen = draggedWindow.frame
        
        let proximityRect = NSRect(
            x: buttonFrameInScreen.origin.x - 100,
            y: buttonFrameInScreen.origin.y - 100,
            width: buttonFrameInScreen.width + 200,
            height: buttonFrameInScreen.height + 100
        )
        
        if NSIntersectsRect(windowFrameInScreen, proximityRect) {
            print("Showing pin tray: sticky note in proximity")
            pinTrayWindow.positionBelowStatusItem(statusItem)
            pinTrayWindow.setIsVisible(true)
        } else {
            print("Hiding pin tray: sticky note not in proximity")
            pinTrayWindow.setIsVisible(false)
        }
    }

    private func isOverTray(_ window: StickyNoteWindow) -> Bool {
        let windowFrameInScreen = window.frame
        let trayFrameInScreen = pinTrayWindow.frame
        let intersects = NSIntersectsRect(windowFrameInScreen, trayFrameInScreen)
        print("Checking if over tray - Window frame: \(windowFrameInScreen), Tray frame: \(trayFrameInScreen), Intersects: \(intersects)")
        return intersects
    }
}
