# CLAUDE.md - DAPComposer

## Project Context
- **Language/Tooling**: Swift 6+, Xcode 26+
- **Target Platforms**: macOS 14.0+
- **UI Framework**: Pure SwiftUI (Strictly no UIKit or Storyboards unless requested)
- **Dependency Management**: Swift Package Manager (SPM) only (No CocoaPods/Carthage)
- **Concurrency**: Swift Concurrency (async/await, Actors)

## Critical AI Guardrails
1. **Never modify `.pbxproj` files directly**: Create/delete files on disk, but do not touch the Xcode project structure file. I will handle file indexing inside Xcode.
2. **One type per file**: Every struct, class, enum, or protocol must live in its own dedicated Swift file.
3. **Strict line limits**: Keep Swift views under 200 lines and functions under 30 lines. Suggest refactoring rather than writing monolithic files.

## Architecture Guidelines
- **Pattern**: MVVM using modern Swift Concurrency and the `@Observable` macro.
- **State Management**: Prefer local state (`@State`) for view-scoped data and `@Environment` for shared dependencies.
- **Data Models**: Use immutable `struct` types conforming to `Codable` and `Sendable` where applicable.
- **Navigation**: Leverage native `NavigationStack` and `NavigationPath` patterns. Do not use legacy hosting controllers.

## Technical Commands
#- **Build**: `xcodebuild -scheme [YourSchemeName] -destination 'platform=macOS' build`
#- **Test**: `xcodebuild -scheme [YourSchemeName] -destination 'platform=macOS' test`
#- **Lint/Format**: `swiftlint lint` / `swiftformat .`

## Code Style & Conventions
- **Swift 6 Concurrency**: Enforce structured concurrency (`async/await`, `Task`). Avoid legacy completion handlers.
- **Previews**: Every SwiftUI view must include a `#Preview` container using static mock/preview data. No live network calls inside previews.
- **SF Symbols**: Utilize native SF Symbols via `Image(systemName:)` with exact string keys.
- **Naming**: PascalCase for types (structs, classes, enums), camelCase for variables/functions.
- **UI Values**: Do not hardcode magic numbers for padding or colors. Use established design tokens if present in the project (e.g., `Color.themeAccent`).
- Minimize comments as they can make a file hard to read.
