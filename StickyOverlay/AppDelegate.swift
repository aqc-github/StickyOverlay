import Cocoa

@objc class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var stickyController: StickyOverlayViewController!
    var controllerWindow: NSWindow!
    var pinTrayWindow: PinTrayWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("applicationDidFinishLaunching called")

        // Create the menu bar tray
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "Pin Tray")
        }

        // Create the pin tray window
        pinTrayWindow = PinTrayWindow()
        
        // Create the controller to manage sticky notes
        stickyController = StickyOverlayViewController(statusItem: statusItem, pinTrayWindow: pinTrayWindow)
        
        // Create a hidden window for the controller
        controllerWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        controllerWindow.isOpaque = false
        controllerWindow.backgroundColor = .clear
        controllerWindow.setIsVisible(false)
        controllerWindow.contentViewController = stickyController
        controllerWindow.makeKeyAndOrderFront(nil)

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("applicationWillTerminate called")
    }
}
