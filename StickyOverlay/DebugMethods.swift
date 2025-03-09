//
//  DebugMethods.swift
//  StickyOverlay
//
//  Created for debugging purposes
//

import Foundation
import Cocoa

// This class provides static methods that can be called from the terminal using lldb
@objc(DebugHelper)
class DebugHelper: NSObject {
    
    // Helper function to get the delegate
    @objc static func getAppDelegate() -> AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }
    
    // Debug functions that can be called from lldb
    @objc static func debugShowHistoryWindow() {
        print("DEBUG: Calling debugShowHistoryWindow")
        if let delegate = getAppDelegate() {
            delegate.debugShowHistoryWindow()
            print("DEBUG: debugShowHistoryWindow called successfully")
        } else {
            print("DEBUG: Could not get AppDelegate")
        }
    }
    
    @objc static func debugCloseHistoryWindow() {
        print("DEBUG: Calling debugCloseHistoryWindow")
        if let delegate = getAppDelegate() {
            delegate.debugCloseHistoryWindow()
            print("DEBUG: debugCloseHistoryWindow called successfully")
        } else {
            print("DEBUG: Could not get AppDelegate")
        }
    }
    
    @objc static func debugMemoryStatus() {
        print("DEBUG: Calling debugMemoryStatus")
        if let delegate = getAppDelegate() {
            delegate.debugMemoryStatus()
            print("DEBUG: debugMemoryStatus called successfully")
        } else {
            print("DEBUG: Could not get AppDelegate")
        }
    }
    
    // Analyze the window delegate for memory issues
    @objc static func analyzeWindowDelegate() {
        print("DEBUG: Analyzing window delegate")
        if let delegate = getAppDelegate(), let window = delegate.value(forKey: "historyWindow") as? NSWindow {
            print("DEBUG: History window exists")
            print("DEBUG: Window delegate: \(String(describing: window.delegate))")
            print("DEBUG: Is delegate same as AppDelegate? \(window.delegate === delegate)")
            print("DEBUG: Window isReleasedWhenClosed: \(window.isReleasedWhenClosed)")
        } else {
            print("DEBUG: History window does not exist or could not access it")
        }
    }
    
    // Force garbage collection
    @objc static func forceMemoryCleanup() {
        print("DEBUG: Forcing memory cleanup")
        autoreleasepool {
            for _ in 0...10 {
                autoreleasepool {
                    // Trigger memory pressure
                    _ = [Int](repeating: 0, count: 1000)
                }
            }
        }
        print("DEBUG: Memory cleanup completed")
    }
    
    // Create and immediately close a history window
    @objc static func createAndCloseHistoryWindow() {
        print("DEBUG: Creating and immediately closing history window")
        if let delegate = getAppDelegate() {
            delegate.debugShowHistoryWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                delegate.debugCloseHistoryWindow()
                print("DEBUG: Create and close sequence completed")
            }
        } else {
            print("DEBUG: Could not get AppDelegate")
        }
    }
    
    // Analyze all retains/releases of the window
    @objc static func analyzeRetainCycles() {
        print("DEBUG: Analyzing retain cycles")
        if let delegate = getAppDelegate() {
            print("DEBUG: AppDelegate: \(delegate)")
            if let window = delegate.value(forKey: "historyWindow") as? NSWindow {
                print("DEBUG: Window: \(window)")
                print("DEBUG: Window retain count: (unknown in Swift)")
                print("DEBUG: Window delegate: \(String(describing: window.delegate))")
            } else {
                print("DEBUG: No history window exists")
            }
        } else {
            print("DEBUG: Could not get AppDelegate")
        }
    }
} 