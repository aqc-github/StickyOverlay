//
//  main.swift
//  StickyOverlay
//
//  Created by Alberto Quintana on 6/3/25.
//

import Cocoa
import Foundation

// Set up exception handling to catch the crash
NSSetUncaughtExceptionHandler { exception in
    print("CRASH: Uncaught exception: \(exception)")
    print("Reason: \(exception.reason ?? "No reason")")
    print("Name: \(exception.name.rawValue)")
    print("Stack trace: \(exception.callStackSymbols.joined(separator: "\n"))")
}

// Debug function to enable GC logging
@_silgen_name("setenv")
func setenv(_ name: UnsafePointer<Int8>, _ value: UnsafePointer<Int8>, _ overwrite: Int32) -> Int32

// Enable memory sanitizer
_ = setenv("MallocStackLogging".cString(using: .ascii)!, "1".cString(using: .ascii)!, 1)

print("Starting StickyOverlay application")

let delegate = AppDelegate()
print("AppDelegate created")

NSApplication.shared.delegate = delegate
print("Delegate assigned to NSApplication")

// Register the debug functions to be callable from Terminal
let app = NSApplication.shared
print("Running NSApplicationMain")
exit(NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv))
