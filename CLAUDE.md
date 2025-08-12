# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EyeSee is an iOS application built with Swift/SwiftUI that allows users to experience the world through the eyes of different animals by applying visual filters based on scientific research about animal vision.

The app is currently in the MVP development phase focusing on:
1. Core UI components with a Neo-Brutalism design language
2. Basic camera functionality
3. Filter framework implementation
4. Animal vision simulation filters

## Architecture & Structure

- **Language**: Swift 5.9+
- **Frameworks**: SwiftUI, SwiftData, Metal (for high-performance filters), AVFoundation, Photos
- **Platform**: iOS 17+

### Key Files & Directories

- `EyeSee/EyeSeeApp.swift` - Main app entry point with SwiftData container setup
- `EyeSee/Views/ContentView.swift` - Main camera view with Neo-Brutalist UI components
- `EyeSee/ViewModels/CameraViewModel.swift` - Camera view state management and business logic
- `EyeSee/Services/CameraService.swift` - Low-level camera capture and session management
- `EyeSee/Services/PhotoLibraryService.swift` - Photo saving and library access
- `EyeSee/Models/Item.swift` - Sample SwiftData model
- `EyeSee/Assets.xcassets` - App icons and image assets
- `.superdesign/design_iterations/` - UI design files (HTML/CSS mockups)
- `.cursor/rules/` - Cursor AI coding rules including design guidelines

## Development Commands

This is a standard Xcode project. Development is done through Xcode IDE rather than command-line build tools.

For running and testing:
1. Open `EyeSee.xcodeproj` in Xcode
2. Select the appropriate simulator or device
3. Build and run using Xcode's standard workflow (Cmd+R)

## Current Development Status

The project has a working camera view with basic controls and photo capture functionality. The next steps are to implement the filter framework and animal vision simulations.

Key areas being worked on:
- UI component refinement based on Neo-Brutalism design
- Camera functionality implementation
- Filter framework development
- Animal vision simulation filters

## Design Guidelines

The project follows a Neo-Brutalism design language as defined in:
- `.superdesign/design_iterations/neo_brutalism_style_guide_1.html`
- `.superdesign/design_iterations/neo_brutalism_style_guide_1.md`

All UI implementations should follow these design principles with bold colors, thick black borders, and playful interactions.

## Architecture Requirements

Following the MVVM-SwiftUI best practices defined in `.cursor/rules/mvvm-swiftui-best-practices.mdc`:

### Models (`EyeSee/Models/`)
- Pure data structures, no business logic
- Use `@Model` macro for SwiftData
- No direct references to SwiftUI or Combine

### ViewModels (`EyeSee/ViewModels/`)
- Handle business logic and state management
- Use `@Observable` macro (iOS17+/macOS14+)
- Use `@Published` properties for state management
- Use Combine for reactive data flow
- No direct references to SwiftUI Views

### Views (`EyeSee/Views/`)
- Pure UI presentation, no business logic
- Use SwiftUI for all UI components
- Use `@State` and `@Bindable` for state management
- Componentized and reusable

### Services (`EyeSee/Services/`)
- Handle platform-specific functionality (camera, photo library)
- Encapsulate complex operations
- Publish state changes via Combine or async/await
- No direct references to ViewModels or Views

## Camera Architecture

The camera system uses a sophisticated real-time filtering architecture:

1. **CameraService** - Manages AVCaptureSession and provides video frame data via `PreviewViewDelegate`
2. **CameraViewModel** - Implements `PreviewViewDelegate` to receive real-time video frames and coordinates filter application
3. **PreviewView** - Custom UIView that displays camera preview and renders filtered overlays using CALayer
4. **AnimalVisionFilterService** - Applies animal vision filters using CoreImage color matrices

Key data flow:
- CameraService captures video frames and passes them to ViewModel via delegate
- ViewModel applies filters using AnimalVisionFilterService
- Filtered images are rendered as overlays on the preview layer
- All processing happens on background threads with UI updates on main thread

When adding new features:
1. Create new SwiftUI views in the `EyeSee/Views/` directory following the feature-based structure
2. Create corresponding ViewModels in `EyeSee/ViewModels/`
3. Create data models in `EyeSee/Models/` if needed
4. Create services in `EyeSee/Services/` for platform interactions
5. Follow the MVVM patterns for state management and data flow
6. Use SwiftData models for persistent data
7. Implement image processing filters using Metal for performance when needed