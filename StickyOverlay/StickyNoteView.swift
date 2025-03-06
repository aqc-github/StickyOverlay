import Cocoa

class StickyNoteView: NSView {
    private var initialLocation: NSPoint?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        print("Setting up StickyNoteView")
        wantsLayer = true
        layer?.backgroundColor = NSColor.yellow.withAlphaComponent(0.8).cgColor
        layer?.cornerRadius = 5
        layer?.shadowOpacity = 0.3
        layer?.shadowRadius = 3
        layer?.shadowOffset = NSSize(width: 0, height: -2)

        let textField = NSTextField(frame: NSRect(x: 5, y: 5, width: frame.width - 10, height: frame.height - 10))
        textField.isEditable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.stringValue = "New Sticky"
        addSubview(textField)
    }

    override var acceptsFirstResponder: Bool { return true }

    override func mouseDown(with event: NSEvent) {
        initialLocation = event.locationInWindow
        window?.ignoresMouseEvents = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initial = initialLocation else { return }
        let currentLocation = event.locationInWindow
        let newOrigin = NSPoint(
            x: frame.origin.x + (currentLocation.x - initial.x),
            y: frame.origin.y + (currentLocation.y - initial.y)
        )
        self.frame.origin = newOrigin
    }

    override func mouseUp(with event: NSEvent) {
        window?.ignoresMouseEvents = true
    }
}
