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
        
        // Create a hidden window for the controller (no need for key event handling)
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

        // Add a global event monitor for key events
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("Key down event received: \(event), modifiers: \(event.modifierFlags), characters: \(event.charactersIgnoringModifiers ?? "")")
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "n" {
                print("Cmd + N detected, adding new sticky note")
                self?.stickyController.addNewStickyNote()
                return nil // Consume the event
            }
            return event
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("applicationWillTerminate called")
    }
}
