import Cocoa

class PinTrayWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 60, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        setupWindow()
    }

    private func setupWindow() {
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        isOpaque = false
        backgroundColor = .clear
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 60, height: 60))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.7).cgColor
        contentView.layer?.cornerRadius = 15
        contentView.layer?.borderWidth = 2
        contentView.layer?.borderColor = NSColor.white.cgColor
        self.contentView = contentView
        
        let pinImage = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pin Tray")
        let imageView = NSImageView(frame: NSRect(x: 15, y: 15, width: 30, height: 30))
        imageView.image = pinImage
        imageView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(imageView)
        
        setIsVisible(false)
    }

    func positionBelowStatusItem(_ statusItem: NSStatusItem) {
        guard let button = statusItem.button,
              let buttonWindow = button.window else {
            return
        }
        let buttonFrameInScreen = buttonWindow.convertToScreen(button.frame)
        let trayFrame = NSRect(
            x: buttonFrameInScreen.origin.x - (frame.width - buttonFrameInScreen.width) / 2,
            y: buttonFrameInScreen.origin.y - frame.height - 5,
            width: frame.width,
            height: frame.height
        )
        setFrame(trayFrame, display: true)
    }
}
