//
//  AppDelegate.swift
//  StickyOverlay
//
//  Created by Alberto Quintana on 6/3/25.
//

import Cocoa

// Custom view class for color circles
class ColorCircleView: NSView {
    var colorIndex: Int = 0
    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        if isSelected {
            layer?.borderWidth = 3
            layer?.borderColor = NSColor.white.cgColor
        } else {
            layer?.borderWidth = 0
            layer?.borderColor = nil
        }
    }
}

@objc class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    var statusItem: NSStatusItem!
    var pinTrayWindow: PinTrayWindow!
    private var inputMenu: NSMenu!
    private var textField: NSTextField!
    private var stickyNotes: [StickyNoteWindow] = []
    private var colorCircles: [ColorCircleView] = []

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
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 90)) // Increased height for better spacing
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Text field with better visibility
        textField = NSTextField(frame: NSRect(x: 5, y: 45, width: 190, height: 25)) // Moved down for more space
        textField.placeholderString = "New Sticky Note"
        textField.isBordered = true // Add border for visibility
        textField.backgroundColor = NSColor.textBackgroundColor
        textField.focusRingType = .exterior // Add focus ring
        textField.delegate = self
        view.addSubview(textField)
        
        // Label for text field
        let textLabel = NSTextField(frame: NSRect(x: 5, y: 70, width: 190, height: 15)) // Moved up
        textLabel.stringValue = "Enter note text:"
        textLabel.isEditable = false
        textLabel.isBordered = false
        textLabel.backgroundColor = .clear
        textLabel.textColor = NSColor.labelColor
        textLabel.font = NSFont.systemFont(ofSize: 11)
        view.addSubview(textLabel)
        
        // Color selection circles with gesture recognizers
        let colors: [NSColor] = [
            NSColor.systemOrange.withAlphaComponent(0.9), // Orange
            NSColor.systemGreen.withAlphaComponent(0.9),  // Green
            NSColor.systemTeal.withAlphaComponent(0.9),   // Baby Blue
            NSColor.systemPink.withAlphaComponent(0.9)    // Pastel Pink
        ]
        
        // Label for color selection
        let colorLabel = NSTextField(frame: NSRect(x: 5, y: 25, width: 190, height: 15)) // Moved up
        colorLabel.stringValue = "Select color:"
        colorLabel.isEditable = false
        colorLabel.isBordered = false
        colorLabel.backgroundColor = .clear
        colorLabel.textColor = NSColor.labelColor
        colorLabel.font = NSFont.systemFont(ofSize: 11)
        view.addSubview(colorLabel)
        
        // Clear previous color circles
        colorCircles.removeAll()
        
        // Get the currently selected color index
        let selectedColorIndex = UserDefaults.standard.integer(forKey: "SelectedStickyColor")
        
        for (index, color) in colors.enumerated() {
            let circle = ColorCircleView(frame: NSRect(x: 10 + (index * 45), y: 5, width: 30, height: 30)) // Made circles larger
            circle.wantsLayer = true
            circle.layer?.backgroundColor = color.cgColor
            circle.layer?.cornerRadius = 15 // Increased corner radius
            circle.colorIndex = index
            
            // Set the selected state based on the saved preference
            circle.isSelected = (index == selectedColorIndex)
            
            // Set accessibility properties using the proper methods
            circle.setAccessibilityElement(true)
            circle.setAccessibilityLabel("Select \(color.description)")
            
            // Use click gesture recognizer instead of press
            let gestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(colorCircleTapped(_:)))
            circle.addGestureRecognizer(gestureRecognizer)
            view.addSubview(circle)
            
            // Store reference to color circle
            colorCircles.append(circle)
        }
        
        menuItem.view = view
        inputMenu.addItem(menuItem)
        
        // Get screen dimensions for fallback positioning
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
        let screenCenter = NSPoint(x: screenFrame.midX, y: screenFrame.midY)
        
        // Position menu directly below status bar item with safe fallbacks
        var menuOrigin = NSPoint(x: screenCenter.x - view.frame.width / 2, y: screenCenter.y)
        
        // Try to position below the status item if possible
        if let button = statusItem.button {
            if let buttonWindow = button.window {
                let buttonFrameInScreen = buttonWindow.convertToScreen(button.frame)
                menuOrigin = NSPoint(
                    x: buttonFrameInScreen.origin.x - (view.frame.width - buttonFrameInScreen.width) / 2,
                    y: buttonFrameInScreen.origin.y - view.frame.height
                )
            } else {
                // Fallback if window is nil but we have the button
                // Use the menu bar height as a reference point
                let menuBarHeight: CGFloat = 22 // Standard menu bar height
                menuOrigin = NSPoint(
                    x: NSStatusBar.system.thickness * 0.5 - view.frame.width * 0.5,
                    y: screenFrame.maxY - menuBarHeight - view.frame.height
                )
            }
        }
        
        // Ensure the menu stays on screen
        let adjustedX = max(screenFrame.minX + 5, min(screenFrame.maxX - view.frame.width - 5, menuOrigin.x))
        let adjustedY = max(screenFrame.minY + 5, min(screenFrame.maxY - 5, menuOrigin.y))
        
        // Show the menu at the calculated position
        inputMenu.popUp(positioning: nil, at: NSPoint(x: adjustedX, y: adjustedY), in: nil)
        
        // Focus the text field after a short delay to ensure the menu is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.textField?.becomeFirstResponder()
        }
    }

    @objc private func colorCircleTapped(_ gesture: NSGestureRecognizer) {
        if let circle = gesture.view as? ColorCircleView {
            let selectedColorIndex = circle.colorIndex
            
            // Update selection state for all circles
            for colorCircle in colorCircles {
                colorCircle.isSelected = (colorCircle.colorIndex == selectedColorIndex)
            }
            
            // Save the selected color
            UserDefaults.standard.set(selectedColorIndex, forKey: "SelectedStickyColor")
        }
    }

    private func createStickyNoteFromInput() {
        let text = textField.stringValue.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty {
            addNewStickyNote(withText: text)
        }
        textField.stringValue = ""
    }

    private func addNewStickyNote(withText text: String) {
        let selectedColorIndex = UserDefaults.standard.integer(forKey: "SelectedStickyColor")
        let colors = [NSColor.systemOrange, NSColor.systemGreen, NSColor.systemTeal, NSColor.systemPink]
        let color = colors[min(selectedColorIndex, colors.count - 1)].withAlphaComponent(0.9)
        let stickyNote = StickyNoteWindow(text: text, pinTrayWindow: pinTrayWindow, onPin: { [weak self] stickyNote in
            self?.pinStickyNote(stickyNote)
        }, initialColor: color)
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
                      let text = noteData["text"] as? String,
                      let colorData = noteData["color"] as? [CGFloat] else { continue }
                let frame = NSRect(
                    x: frameDict["x"] ?? 0,
                    y: frameDict["y"] ?? 0,
                    width: frameDict["width"] ?? 200,
                    height: frameDict["height"] ?? 150
                )
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                if colorData.count >= 4 {
                    red = colorData[0]; green = colorData[1]; blue = colorData[2]; alpha = colorData[3]
                }
                let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
                let stickyNote = StickyNoteWindow(text: text, pinTrayWindow: pinTrayWindow, onPin: { [weak self] stickyNote in
                    self?.pinStickyNote(stickyNote)
                }, initialColor: color)
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
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            note.stickyColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [
                "frame": [
                    "x": frame.origin.x,
                    "y": frame.origin.y,
                    "width": frame.size.width,
                    "height": frame.size.height
                ],
                "text": note.textField.stringValue,
                "color": [red, green, blue, alpha]
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
