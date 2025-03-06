# StickyOverlay

A lightweight, unobtrusive sticky notes app for macOS that lives in your menu bar.

![StickyOverlay Screenshot](screenshot.png)

## Features

- **Menu Bar Integration**: Access StickyOverlay from the menu bar with a simple click
- **Colorful Notes**: Choose from four pleasant colors for your sticky notes
- **Drag & Drop**: Move notes anywhere on your screen
- **Pin to Tray**: Easily remove notes by dragging them to the pin tray
- **Persistence**: Notes are automatically saved between app launches
- **Minimal UI**: Clean, distraction-free interface

## How to Use

### Creating Notes

1. Click the pin icon in the menu bar
2. Type your note text in the text field
3. Select a color for your note (orange, green, teal, or pink)
4. Press Enter to create the note

### Managing Notes

- **Move**: Click and drag notes anywhere on your screen
- **Remove**: Drag a note toward the menu bar pin icon, and drop it on the pin tray that appears

## Installation

### Requirements

- macOS 11.0 (Big Sur) or later
- Xcode 12.0 or later (for building from source)

### Download

Download the latest release from the [Releases](https://github.com/yourusername/StickyOverlay/releases) page.

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/StickyOverlay.git
   ```

2. Open the project in Xcode:
   ```
   cd StickyOverlay
   open StickyOverlay.xcodeproj
   ```

3. Build and run the project (⌘+R)

## Technical Details

StickyOverlay is built using Swift and AppKit, with a focus on lightweight performance and native macOS integration. Key components include:

- **AppDelegate**: Manages the menu bar item and sticky note creation
- **StickyNoteWindow**: Custom window implementation for sticky notes
- **PinTrayWindow**: Specialized window for the pin tray functionality
- **ColorCircleView**: Custom view for color selection

Notes are persisted using UserDefaults for simplicity, making this app perfect for quick reminders and thoughts without the overhead of a full note-taking application.

## Customization

You can customize the app by modifying the source code:

- Change the default colors in `AppDelegate.swift`
- Adjust the size and appearance of sticky notes in `StickyNoteWindow.swift`
- Modify the pin tray appearance in `PinTrayWindow.swift`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the classic sticky notes functionality from earlier operating systems
- Built with Swift and AppKit for native macOS integration 