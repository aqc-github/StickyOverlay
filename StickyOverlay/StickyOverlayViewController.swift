//
//  StickyOverlayViewController.swift
//  StickyOverlay
//
//  Created by Alberto Quintana on 6/3/25.
//

import Cocoa

class StickyOverlayViewController: NSViewController {
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 1280, height: 800)
        let sticky = StickyNoteView(frame: NSRect(x: screenSize.width / 2 - 100, y: screenSize.height / 2 - 75, width: 200, height: 150))
        view.addSubview(sticky)
    }
}
