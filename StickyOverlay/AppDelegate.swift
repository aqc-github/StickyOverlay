import Cocoa

@objc class AppDelegate: NSObject, NSApplicationDelegate {

    var overlayWindow: NSWindow!
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("applicationDidFinishLaunching called")

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        print("Screen frame: \(screenFrame)")
        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        print("Overlay window created: \(overlayWindow)")
        print("Initial frame after creation: \(overlayWindow.frame)")
        
        overlayWindow.level = NSWindow.Level(rawValue: -500)
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear // Temporary red background to test visibility
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.setFrame(screenFrame, display: true)
        print("Frame after setFrame: \(overlayWindow.frame)")
        
        let contentViewController = StickyOverlayViewController()
        overlayWindow.contentViewController = contentViewController
        print("Frame after setting contentViewController: \(overlayWindow.frame)")
        
        overlayWindow.makeKeyAndOrderFront(nil)
        overlayWindow.orderFrontRegardless()
        print("Overlay window ordered front: \(overlayWindow.frame)")
        
        // Explicitly set the frame one more time to ensure it sticks
        overlayWindow.setFrame(screenFrame, display: true)
        print("Final frame after explicit setFrame: \(overlayWindow.frame)")
        
        // Add the menu bar tray
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "Pin Tray")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("applicationWillTerminate called")
    }
}

