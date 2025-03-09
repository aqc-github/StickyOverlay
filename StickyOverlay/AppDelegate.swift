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
    
    // Replace history window properties with a single controller
    private var historyViewController: HistoryViewController?
    
    // Logging system
    private let isLoggingEnabled = true
    private func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if isLoggingEnabled {
            let fileName = (file as NSString).lastPathComponent
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss.SSS"
            let timestamp = dateFormatter.string(from: Date())
            print("[\(timestamp)] [\(fileName):\(line)] \(function): \(message)")
        }
    }
    
    // Debug functions that can be called from terminal
    @objc func debugCloseHistoryWindow() {
        log("Manual debug call to close history window")
        historyViewController?.closeWindow()
    }
    
    @objc func debugShowHistoryWindow() {
        log("Manual debug call to show history window")
        showHistory()
    }
    
    @objc func debugMemoryStatus() {
        log("Checking memory status")
        log("historyViewController: \(historyViewController != nil ? "exists" : "nil")")
        
        if let controller = historyViewController {
            log("History view controller exists")
            log("Window exists: \(controller.hasWindow() ? "yes" : "no")")
            log("Window is visible: \(controller.isWindowVisible() ? "yes" : "no")")
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        log("Application did finish launching")
        
        // Register debug selectors to be accessible from the terminal
        let shared = NSApplication.shared
        shared.perform(#selector(NSApplication.registerServicesMenuSendTypes(_:returnTypes:)), with: nil, with: nil)
        
        // Hide the app from the dock to make it a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Create the menu bar tray
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Sticky Notes")
            button.action = #selector(showInputMenu)
            button.target = self
        }

        // Initialize the pin tray window
        pinTrayWindow = PinTrayWindow()

        // Load existing sticky notes from UserDefaults
        loadStickyNotes()

        NSApplication.shared.activate(ignoringOtherApps: true)
        
        log("Application setup complete")
    }

    @objc private func showInputMenu() {
        let menu = NSMenu()
        
        // Add note creation interface directly in the menu
        let createNoteItem = NSMenuItem()
        let createNoteView = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 120)) // Increased width and height
        createNoteView.wantsLayer = true
        createNoteView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Label for text field
        let textLabel = NSTextField(frame: NSRect(x: 12, y: 90, width: 216, height: 16))
        textLabel.stringValue = "Enter note text:"
        textLabel.isEditable = false
        textLabel.isBordered = false
        textLabel.backgroundColor = .clear
        textLabel.textColor = NSColor.labelColor
        textLabel.font = NSFont.systemFont(ofSize: 12)
        createNoteView.addSubview(textLabel)
        
        // Text field with better visibility
        textField = NSTextField(frame: NSRect(x: 12, y: 60, width: 216, height: 25))
        textField.placeholderString = "New Sticky Note"
        textField.isBordered = true
        textField.backgroundColor = NSColor.textBackgroundColor
        textField.focusRingType = .exterior
        textField.delegate = self
        createNoteView.addSubview(textField)
        
        // Label for color selection
        let colorLabel = NSTextField(frame: NSRect(x: 12, y: 35, width: 100, height: 16))
        colorLabel.stringValue = "Select color:"
        colorLabel.isEditable = false
        colorLabel.isBordered = false
        colorLabel.backgroundColor = .clear
        colorLabel.textColor = NSColor.labelColor
        colorLabel.font = NSFont.systemFont(ofSize: 12)
        createNoteView.addSubview(colorLabel)
        
        // Clear previous color circles
        colorCircles.removeAll()
        
        // Get the currently selected color index
        let selectedColorIndex = UserDefaults.standard.integer(forKey: "SelectedStickyColor")
        
        // Color selection circles with gesture recognizers
        let colors: [NSColor] = [
            NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.8, alpha: 0.9), // Pastel Pink
            NSColor(calibratedRed: 0.8, green: 0.9, blue: 1.0, alpha: 0.9), // Pastel Blue
            NSColor(calibratedRed: 0.9, green: 1.0, blue: 0.8, alpha: 0.9), // Pastel Green
            NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.7, alpha: 0.9)  // Pastel Yellow
        ]
        
        for (index, color) in colors.enumerated() {
            let circle = ColorCircleView(frame: NSRect(x: 12 + (index * 36), y: 12, width: 24, height: 24))
            circle.wantsLayer = true
            circle.layer?.backgroundColor = color.cgColor
            circle.layer?.cornerRadius = 12
            circle.colorIndex = index
            
            // Set the selected state based on the saved preference
            circle.isSelected = (index == selectedColorIndex)
            
            // Set accessibility properties
            circle.setAccessibilityElement(true)
            circle.setAccessibilityLabel("Select \(color.description)")
            
            let gestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(colorCircleTapped(_:)))
            circle.addGestureRecognizer(gestureRecognizer)
            createNoteView.addSubview(circle)
            
            // Store reference to color circle
            colorCircles.append(circle)
        }
        
        // Create button
        let createButton = NSButton(frame: NSRect(x: 156, y: 12, width: 72, height: 24))
        createButton.title = "Create"
        createButton.bezelStyle = .rounded
        createButton.target = self
        createButton.action = #selector(createNoteFromMenu)
        createNoteView.addSubview(createButton)
        
        createNoteItem.view = createNoteView
        menu.addItem(createNoteItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // See history option
        let historyItem = NSMenuItem(title: "See History", action: #selector(showHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // Clear all option
        let clearAllItem = NSMenuItem(title: "Clear All", action: #selector(confirmClearAll), keyEquivalent: "c")
        clearAllItem.target = self
        menu.addItem(clearAllItem)
        
        // Add quit option
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        // Focus the text field after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.textField?.becomeFirstResponder()
        }
    }
    
    @objc private func createNoteFromMenu() {
        createStickyNoteFromInput()
        statusItem.menu?.cancelTracking()
    }

    @objc private func showHistory() {
        log("showHistory called")
        
        // All UI updates should happen on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("Self was deallocated in showHistory async block")
                return
            }
            
            self.log("Inside main thread block of showHistory")
            
            // Load pinned notes from UserDefaults
            let pinnedNotes = UserDefaults.standard.array(forKey: "PinnedNotes") as? [[String: Any]] ?? []
            self.log("Loaded \(pinnedNotes.count) pinned notes from UserDefaults")
            
            if pinnedNotes.isEmpty {
                self.log("No pinned notes, showing alert")
                // Show alert if no pinned notes
                let alert = NSAlert()
                alert.messageText = "No Pinned Notes"
                alert.informativeText = "You don't have any pinned notes in your history."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }
            
            // If history controller doesn't exist, create it
            if self.historyViewController == nil {
                self.log("Creating new history view controller")
                self.historyViewController = HistoryViewController(appDelegate: self)
            }
            
            // Display history window with notes
            self.log("Showing history window and updating content")
            self.historyViewController?.showWindow(with: pinnedNotes)
        }
    }
    
    // Method to restore a note from history
    @objc func restoreNoteFromHistory(_ index: Int) {
        log("restoreNoteFromHistory called with index: \(index)")
        
        let pinnedNotes = UserDefaults.standard.array(forKey: "PinnedNotes") as? [[String: Any]] ?? []
        guard index < pinnedNotes.count else {
            log("Invalid index: \(index) for pinned notes count: \(pinnedNotes.count)")
            return
        }
        
        let noteData = pinnedNotes[index]
        guard let text = noteData["text"] as? String,
              let colorData = noteData["color"] as? [CGFloat] else {
            log("Invalid note data at index \(index)")
            return
        }
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if colorData.count >= 4 {
            red = colorData[0]; green = colorData[1]; blue = colorData[2]; alpha = colorData[3]
        }
        let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
        
        // Create a new sticky note with the restored data
        addNewStickyNote(withText: text, withColor: color)
        
        // Ask if the user wants to keep the note in history
        let alert = NSAlert()
        alert.messageText = "Keep in History?"
        alert.informativeText = "Do you want to keep this note in your history?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Keep")
        alert.addButton(withTitle: "Remove")
        
        if alert.runModal() == .alertSecondButtonReturn {
            // Remove from history if user chose "Remove"
            removeNoteFromHistory(at: index)
        }
    }
    
    // Method to delete a note from history
    @objc func deleteNoteFromHistory(_ index: Int) {
        log("deleteNoteFromHistory called with index: \(index)")
        removeNoteFromHistory(at: index)
    }
    
    private func removeNoteFromHistory(at index: Int) {
        log("removeNoteFromHistory called with index: \(index)")
        
        // Ensure this runs on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.removeNoteFromHistory(at: index)
            }
            return
        }
        
        var pinnedNotes = UserDefaults.standard.array(forKey: "PinnedNotes") as? [[String: Any]] ?? []
        guard index < pinnedNotes.count else {
            log("Invalid index: \(index) for pinned notes count: \(pinnedNotes.count)")
            return
        }
        
        pinnedNotes.remove(at: index)
        UserDefaults.standard.set(pinnedNotes, forKey: "PinnedNotes")
        
        // Update the history window if open
        historyViewController?.updateContent(with: pinnedNotes)
    }

    @objc private func confirmClearAll() {
        let alert = NSAlert()
        alert.messageText = "Clear All Notes"
        alert.informativeText = "Are you sure you want to delete all sticky notes? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear All")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            clearAllNotes()
        }
    }

    private func clearAllNotes() {
        log("clearAllNotes called")
        
        // Remove all sticky notes
        log("Removing \(stickyNotes.count) active sticky notes")
        for note in stickyNotes {
            note.orderOut(nil)
        }
        stickyNotes.removeAll()
        
        // Clear UserDefaults
        log("Clearing UserDefaults")
        UserDefaults.standard.removeObject(forKey: "StickyNotes")
        UserDefaults.standard.removeObject(forKey: "PinnedNotes")
        
        // If history window is open, close it
        if historyViewController != nil && historyViewController!.isWindowVisible() {
            log("History window is open, closing it")
            historyViewController?.closeWindow()
        }
        
        log("All notes cleared")
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
            let selectedColorIndex = UserDefaults.standard.integer(forKey: "SelectedStickyColor")
            let colors = [
                NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.8, alpha: 0.9), // Pastel Pink
                NSColor(calibratedRed: 0.8, green: 0.9, blue: 1.0, alpha: 0.9), // Pastel Blue
                NSColor(calibratedRed: 0.9, green: 1.0, blue: 0.8, alpha: 0.9), // Pastel Green
                NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.7, alpha: 0.9)  // Pastel Yellow
            ]
            let color = colors[min(selectedColorIndex, colors.count - 1)]
            addNewStickyNote(withText: text, withColor: color)
        }
        textField.stringValue = ""
    }

    private func addNewStickyNote(withText text: String, withColor color: NSColor? = nil) {
        let selectedColorIndex = UserDefaults.standard.integer(forKey: "SelectedStickyColor")
        let colors = [
            NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.8, alpha: 0.9), // Pastel Pink
            NSColor(calibratedRed: 0.8, green: 0.9, blue: 1.0, alpha: 0.9), // Pastel Blue
            NSColor(calibratedRed: 0.9, green: 1.0, blue: 0.8, alpha: 0.9), // Pastel Green
            NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.7, alpha: 0.9)  // Pastel Yellow
        ]
        let noteColor = color ?? colors[min(selectedColorIndex, colors.count - 1)]
        
        let stickyNote = StickyNoteWindow(text: text, pinTrayWindow: pinTrayWindow, onPin: { [weak self] stickyNote in
            self?.pinStickyNote(stickyNote)
        }, initialColor: noteColor)
        
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
        log("pinStickyNote called")
        
        if let index = stickyNotes.firstIndex(of: stickyNote) {
            // Check if we're pinning or trashing
            let mode = pinTrayWindow.getMode()
            
            if mode == .pin {
                log("Pinning note with mode: pin")
                // Save the pinned note to UserDefaults
                let text = stickyNote.textField.stringValue
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                stickyNote.stickyColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                let pinnedNote: [String: Any] = [
                    "text": text,
                    "color": [red, green, blue, alpha],
                    "date": Date().timeIntervalSince1970 // Save as timestamp for better serialization
                ]
                
                var pinnedNotes = UserDefaults.standard.array(forKey: "PinnedNotes") as? [[String: Any]] ?? []
                pinnedNotes.append(pinnedNote)
                UserDefaults.standard.set(pinnedNotes, forKey: "PinnedNotes")
                
                log("Sticky note pinned to history")
                
                // Update history window if it's visible
                historyViewController?.updateContent(with: pinnedNotes)
            } else {
                log("Trashing note with mode: trash")
                // Just remove the note without saving to history
                print("Sticky note trashed (not recoverable)")
            }
            
            // Remove the note from the active notes
            stickyNotes.remove(at: index)
            saveStickyNotes()
            log("New active sticky note count: \(stickyNotes.count)")
        } else {
            log("ERROR: Note not found in stickyNotes array")
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
        textField = nil
        colorCircles.removeAll()
    }
}

// MARK: - NSTextFieldDelegate
extension AppDelegate: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            createStickyNoteFromInput()
            statusItem.menu?.cancelTracking()
            return true
        }
        return false
    }
}

// Add a new specialized view controller to handle history window
class HistoryViewController: NSObject {
    private weak var appDelegate: AppDelegate?
    private var windowController: NSWindowController?
    private var isClosing = false
    
    // Public methods to access window state
    func hasWindow() -> Bool {
        return windowController?.window != nil
    }
    
    func isWindowVisible() -> Bool {
        return windowController?.window?.isVisible == true
    }
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        super.init()
    }
    
    func showWindow(with pinnedNotes: [[String: Any]]) {
        // If already showing, just update content
        if let controller = windowController, controller.window?.isVisible == true {
            updateContent(with: pinnedNotes)
            return
        }
        
        // Close any existing window
        if windowController != nil {
            closeWindow()
            
            // Wait for window to fully close before creating a new one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.createNewWindow(with: pinnedNotes)
            }
            return
        }
        
        createNewWindow(with: pinnedNotes)
    }
    
    private func createNewWindow(with pinnedNotes: [[String: Any]]) {
        print("Creating new history window")
        
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pinned Notes History"
        window.center()
        window.isReleasedWhenClosed = true
        
        // Create scroll view
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        window.contentView = scrollView
        
        // Create window controller (this retains the window)
        let controller = NSWindowController(window: window)
        windowController = controller
        
        // Set delegate
        window.delegate = self
        
        // Create notes content
        createContentForWindow(window, with: pinnedNotes)
        
        // Show window
        controller.showWindow(nil)
    }
    
    func updateContent(with pinnedNotes: [[String: Any]]) {
        guard let controller = windowController, 
              let window = controller.window,
              window.isVisible, 
              !isClosing else {
            return
        }
        
        // Update window content
        createContentForWindow(window, with: pinnedNotes)
    }
    
    private func createContentForWindow(_ window: NSWindow, with pinnedNotes: [[String: Any]]) {
        // Ensure this runs on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.createContentForWindow(window, with: pinnedNotes)
            }
            return
        }
        
        guard let scrollView = window.contentView as? NSScrollView else {
            return
        }
        
        // Create new content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: max(CGFloat(pinnedNotes.count * 110), 50)))
        
        // Date formatter for displaying dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for (index, noteData) in pinnedNotes.enumerated() {
            guard let text = noteData["text"] as? String,
                  let colorData = noteData["color"] as? [CGFloat] else {
                continue
            }
            
            let noteView = NSView(frame: NSRect(x: 10, y: contentView.frame.height - CGFloat((index + 1) * 100), width: 260, height: 90))
            noteView.wantsLayer = true
            
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            if colorData.count >= 4 {
                red = colorData[0]; green = colorData[1]; blue = colorData[2]; alpha = colorData[3]
            }
            let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
            
            noteView.layer?.backgroundColor = color.cgColor
            noteView.layer?.cornerRadius = 8
            
            // Add date label
            let dateLabel = NSTextField(frame: NSRect(x: 10, y: 70, width: 240, height: 16))
            dateLabel.isEditable = false
            dateLabel.isBordered = false
            dateLabel.backgroundColor = .clear
            dateLabel.textColor = NSColor.darkGray
            dateLabel.font = NSFont.systemFont(ofSize: 10, weight: .light)
            
            // Get the date from timestamp or use current date as fallback
            var dateString = "Unknown date"
            if let timestamp = noteData["date"] as? TimeInterval {
                let date = Date(timeIntervalSince1970: timestamp)
                dateString = dateFormatter.string(from: date)
            } else if let date = noteData["date"] as? Date {
                // For backward compatibility with older saved notes
                dateString = dateFormatter.string(from: date)
            }
            dateLabel.stringValue = dateString
            
            noteView.addSubview(dateLabel)
            
            // Note text
            let textField = NSTextField(frame: NSRect(x: 10, y: 10, width: 240, height: 55))
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.stringValue = text
            textField.lineBreakMode = .byWordWrapping
            textField.cell?.wraps = true
            textField.cell?.isScrollable = false
            
            noteView.addSubview(textField)
            
            // Add restore button
            let restoreButton = NSButton(frame: NSRect(x: 220, y: 65, width: 30, height: 20))
            restoreButton.title = "+"
            restoreButton.bezelStyle = .roundRect
            restoreButton.tag = index
            
            // Target-action is safe here because window controller retains the window
            // which retains contentView which retains buttons, and self is retained
            // by the window as its delegate
            restoreButton.target = self
            restoreButton.action = #selector(restoreButtonClicked(_:))
            
            restoreButton.toolTip = "Restore note"
            noteView.addSubview(restoreButton)
            
            // Add delete button
            let deleteButton = NSButton(frame: NSRect(x: 190, y: 65, width: 30, height: 20))
            deleteButton.title = "×"
            deleteButton.bezelStyle = .roundRect
            deleteButton.tag = index
            
            deleteButton.target = self
            deleteButton.action = #selector(deleteButtonClicked(_:))
            
            deleteButton.toolTip = "Delete from history"
            noteView.addSubview(deleteButton)
            
            contentView.addSubview(noteView)
        }
        
        // Set document view
        scrollView.documentView = contentView
    }
    
    // Selector wrapper methods that are not part of closure captures
    @objc private func restoreButtonClicked(_ sender: NSButton) {
        guard !isClosing else { return }
        appDelegate?.restoreNoteFromHistory(sender.tag)
    }
    
    @objc private func deleteButtonClicked(_ sender: NSButton) {
        guard !isClosing else { return }
        appDelegate?.deleteNoteFromHistory(sender.tag)
    }
    
    func closeWindow() {
        guard !isClosing else { return }
        isClosing = true
        
        // This properly closes the window and releases the window controller
        windowController?.close()
        
        // Explicitly break the reference
        windowController = nil
        
        // Reset closing state after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isClosing = false
        }
    }
}

// Add NSWindowDelegate conformance to the HistoryViewController
extension HistoryViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        print("Window will close")
        
        // Mark we're in the closing process
        isClosing = true
    }
    
    func windowDidClose(_ notification: Notification) {
        print("Window did close")
        
        // Explicitly clear window controller reference
        windowController = nil
    }
}
