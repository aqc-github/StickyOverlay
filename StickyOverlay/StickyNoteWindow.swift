import Cocoa

class StickyNoteWindow: NSWindow {
    private(set) var textField: NSTextField!
    private weak var controller: StickyOverlayViewController?
    private var stickyContentView: NSView! // Renamed to avoid conflict with NSWindow's contentView

    init(controller: StickyOverlayViewController) {
        self.controller = controller
        let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 1280, height: 800)
        print("Screen size: \(screenSize)")
        let initialFrame = NSRect(
            x: screenSize.width / 2 - 100,
            y: screenSize.height / 2 - 75,
            width: 200,
            height: 150
        )
        print("Initial frame: \(initialFrame)")
        
        super.init(
            contentRect: initialFrame,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        print("StickyNoteWindow initialized with frame: \(frame)")
        setupWindow()
    }

    private func setupWindow() {
        print("Setting up StickyNoteWindow")
        isMovableByWindowBackground = true
        // Set the window level to be always on top
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        isOpaque = false
        backgroundColor = .clear
        
        stickyContentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 150))
        stickyContentView.wantsLayer = true
        stickyContentView.layer?.backgroundColor = NSColor.yellow.withAlphaComponent(0.8).cgColor
        stickyContentView.layer?.cornerRadius = 5
        stickyContentView.layer?.shadowOpacity = 0.3
        stickyContentView.layer?.shadowRadius = 3
        stickyContentView.layer?.shadowOffset = NSSize(width: 0, height: -2)
        self.contentView = stickyContentView // Assign to NSWindow's contentView
        
        textField = NSTextField(frame: NSRect(x: 5, y: 5, width: frame.width - 10, height: frame.height - 10))
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.stringValue = "New Sticky"
        textField.target = self
        textField.action = #selector(textFieldClicked)
        stickyContentView.addSubview(textField)
        
        if let mainScreen = NSScreen.main {
            setFrame(frame, display: true)
            setFrameOrigin(NSPoint(x: frame.origin.x, y: mainScreen.frame.height - frame.origin.y - frame.height))
            print("Adjusted frame for main screen: \(frame)")
        }
        
        makeKeyAndOrderFront(nil)
        setIsVisible(true)
        orderFrontRegardless()
        print("StickyNoteWindow made key and ordered front with frame: \(frame), isVisible: \(isVisible)")
    }

    @objc func textFieldClicked() {
        print("Text field clicked")
        textField.isEditable = true
        makeFirstResponder(textField)
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        print("Mouse down at: \(event.locationInWindow)")
        textField.isEditable = false
        controller?.didBeginDragging(self)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        print("Mouse dragged to: \(event.locationInWindow)")
        controller?.didDrag(self)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print("Mouse up at: \(event.locationInWindow)")
        controller?.didEndDragging(self)
    }

    func highlightForPinning(_ highlight: Bool) {
        stickyContentView.layer?.backgroundColor = highlight ?
            NSColor.green.withAlphaComponent(0.8).cgColor :
            NSColor.yellow.withAlphaComponent(0.8).cgColor
    }

    func animateAndClose(to position: NSPoint) {
        print("Animating sticky note to position: \(position)")
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 0
            self.animator().setFrame(
                NSRect(
                    x: position.x,
                    y: position.y,
                    width: 20,
                    height: 20
                ),
                display: true
            )
        } completionHandler: {
            print("Closing sticky note window")
            self.close()
        }
    }
}
