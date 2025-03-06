import Cocoa

class StickyNoteWindow: NSWindow {
    private(set) var textField: NSTextField!
    private let pinTrayWindow: PinTrayWindow
    private let onPin: (StickyNoteWindow) -> Void
    private var isDragging: Bool = false
    private var isClosing: Bool = false
    internal let stickyColor: NSColor // Changed to internal for AppDelegate access

    init(text: String, pinTrayWindow: PinTrayWindow, onPin: @escaping (StickyNoteWindow) -> Void, initialColor: NSColor) {
        self.pinTrayWindow = pinTrayWindow
        self.onPin = onPin
        self.stickyColor = initialColor
        let initialFrame = NSRect(x: 0, y: 0, width: 200, height: 150)
        super.init(contentRect: initialFrame, styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        setupWindow(with: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow(with text: String) {
        isMovableByWindowBackground = true
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        isOpaque = false
        super.backgroundColor = stickyColor.withAlphaComponent(0.9) // Set superclass backgroundColor

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 150))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = stickyColor.cgColor
        contentView.layer?.cornerRadius = 12 // Increased corner radius for more rounded appearance
        contentView.layer?.shadowOpacity = 0.3
        contentView.layer?.shadowRadius = 3
        contentView.layer?.shadowOffset = NSSize(width: 0, height: -2)
        self.contentView = contentView

        textField = NSTextField(frame: NSRect(x: 10, y: 10, width: 180, height: 130)) // Adjusted for better margins
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.stringValue = text
        textField.alignment = .left
        textField.lineBreakMode = .byWordWrapping
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        contentView.addSubview(textField)

        makeKeyAndOrderFront(nil)
        setIsVisible(true)
        orderFrontRegardless()
    }

    override func mouseDown(with event: NSEvent) {
        if isClosing { return }
        super.mouseDown(with: event)
        isDragging = true
        checkProximityToPinIcon()
    }

    override func mouseDragged(with event: NSEvent) {
        if isClosing { return }
        super.mouseDragged(with: event)
        checkProximityToPinIcon()
        highlightForPinning(isOverTray())
    }

    override func mouseUp(with event: NSEvent) {
        if isClosing { return }
        super.mouseUp(with: event)
        isDragging = false
        if isOverTray() {
            pinStickyNote()
        }
        pinTrayWindow.setIsVisible(false)
        print("Mouse up, isOverTray: \(isOverTray()), tray frame: \(pinTrayWindow.frame), window frame: \(frame)")
    }

    private func checkProximityToPinIcon() {
        guard isDragging else {
            pinTrayWindow.setIsVisible(false)
            return
        }
        
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
           let statusItem = appDelegate.statusItem {
            guard let button = statusItem.button,
                  let buttonWindow = button.window else {
                pinTrayWindow.setIsVisible(false)
                print("Failed to get button or buttonWindow")
                return
            }
            
            let buttonFrameInScreen = buttonWindow.convertToScreen(button.frame)
            let windowFrameInScreen = frame
            
            let proximityRect = NSRect(
                x: buttonFrameInScreen.origin.x - 100,
                y: buttonFrameInScreen.origin.y - 100,
                width: buttonFrameInScreen.width + 200,
                height: buttonFrameInScreen.height + 100
            )
            
            let isInProximity = NSIntersectsRect(windowFrameInScreen, proximityRect)
            pinTrayWindow.setIsVisible(isInProximity)
            if isInProximity {
                pinTrayWindow.positionBelowStatusItem(statusItem)
                print("Proximity detected, tray shown at: \(pinTrayWindow.frame)")
            } else {
                print("No proximity, tray hidden")
            }
        } else {
            pinTrayWindow.setIsVisible(false)
            print("AppDelegate or statusItem not found")
        }
    }

    private func isOverTray() -> Bool {
        let windowFrameInScreen = frame
        let trayFrameInScreen = pinTrayWindow.frame
        let intersects = NSIntersectsRect(windowFrameInScreen, trayFrameInScreen)
        print("Checking overlap - Window frame: \(windowFrameInScreen), Tray frame: \(trayFrameInScreen), Intersects: \(intersects)")
        return intersects
    }

    private func highlightForPinning(_ highlight: Bool) {
        contentView?.layer?.opacity = highlight ? 0.2 : 0.5
    }

    private func pinStickyNote() {
        isClosing = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 0
            self.animator().setFrame(
                NSRect(
                    x: pinTrayWindow.frame.origin.x,
                    y: pinTrayWindow.frame.origin.y,
                    width: 20,
                    height: 20
                ),
                display: true
            )
        } completionHandler: {
            self.orderOut(nil)
            self.onPin(self)
            print("Sticky note pinned and removed")
        }
    }
}
