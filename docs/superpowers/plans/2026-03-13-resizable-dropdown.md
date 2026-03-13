# Resizable Dropdown Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a vertical drag handle at the bottom of the dropdown so users can resize the content area to see more tasks/notes.

**Architecture:** A `ResizeDragHandle` view at the bottom of the dropdown drives a `contentMaxHeight` binding owned by `DropdownRootView`. This height flows through `ContentTabView` to `TaskListView` and `NotesListView`, replacing their hardcoded `maxHeight: 600`. The height persists in UserDefaults across sessions.

**Tech Stack:** SwiftUI, AppKit (NSScreen), UserDefaults, XcodeGen

**Spec:** `docs/superpowers/specs/2026-03-13-resizable-dropdown-design.md`

---

## File Structure

| File | Responsibility | Action |
|------|---------------|--------|
| `NiwaApp/Views/Components/ResizeDragHandle.swift` | Drag handle view with grip indicator, drag gesture, double-tap reset, hover state, accessibility | Create |
| `NiwaApp/Views/DropdownRootView.swift` | Owns `contentMaxHeight` state, places handle, passes height to ContentTabView | Modify |
| `NiwaApp/Views/ContentTabView.swift` | Accepts `contentMaxHeight`, passes to list views | Modify |
| `NiwaApp/Views/TaskListView.swift` | Uses dynamic `contentMaxHeight` instead of hardcoded 600 | Modify |
| `NiwaApp/Views/NotesListView.swift` | Uses dynamic `contentMaxHeight` instead of hardcoded 600 | Modify |

---

## Chunk 1: Implementation

### Task 1: Create ResizeDragHandle component

**Files:**
- Create: `NiwaApp/Views/Components/ResizeDragHandle.swift`

- [ ] **Step 1: Create the ResizeDragHandle view**

```swift
import SwiftUI
import AppKit

struct ResizeDragHandle: View {
    @Binding var height: CGFloat
    let minHeight: CGFloat = 200
    let defaultHeight: CGFloat = 600

    static let userDefaultsKey = "niwa.dropdown.contentMaxHeight"

    @State private var isHovered = false
    @State private var dragStartHeight: CGFloat?

    private var maxHeight: CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
        return min(screenHeight - 300, 900)
    }

    var body: some View {
        Rectangle()
            .fill(isHovered ? DesignTokens.Colors.secondary.opacity(0.08) : Color.clear)
            .frame(height: 8)
            .overlay {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        isHovered
                            ? DesignTokens.Colors.secondary.opacity(0.6)
                            : DesignTokens.Colors.textMuted.opacity(0.3)
                    )
                    .frame(width: 40, height: 3)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartHeight == nil {
                            dragStartHeight = height
                        }
                        let newHeight = (dragStartHeight ?? height) + value.translation.height
                        height = min(max(newHeight, minHeight), maxHeight)
                    }
                    .onEnded { _ in
                        dragStartHeight = nil
                        UserDefaults.standard.set(Double(height), forKey: ResizeDragHandle.userDefaultsKey)
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    height = defaultHeight
                }
                UserDefaults.standard.set(Double(defaultHeight), forKey: ResizeDragHandle.userDefaultsKey)
            }
            .accessibilityLabel("Resize handle")
            .accessibilityAdjustableAction { direction in
                let step: CGFloat = 50
                switch direction {
                case .increment:
                    height = min(height + step, maxHeight)
                case .decrement:
                    height = max(height - step, minHeight)
                @unknown default:
                    break
                }
                UserDefaults.standard.set(Double(height), forKey: ResizeDragHandle.userDefaultsKey)
            }
    }
}
```

- [ ] **Step 2: Regenerate Xcode project**

Run: `cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodegen generate`
Expected: `Project generated`

- [ ] **Step 3: Build to verify the new file compiles**

Run: `cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add NiwaApp/Views/Components/ResizeDragHandle.swift
git commit -m "feat: add ResizeDragHandle component with drag, double-tap reset, and accessibility"
```

---

### Task 2: Wire height through ContentTabView and list views

**Files:**
- Modify: `NiwaApp/Views/ContentTabView.swift:8` — add `contentMaxHeight` property
- Modify: `NiwaApp/Views/ContentTabView.swift:52-53` — pass height to list views
- Modify: `NiwaApp/Views/TaskListView.swift:4` — add `contentMaxHeight` property
- Modify: `NiwaApp/Views/TaskListView.swift:147` — replace hardcoded `maxHeight: 600`
- Modify: `NiwaApp/Views/NotesListView.swift:4` — add `contentMaxHeight` property
- Modify: `NiwaApp/Views/NotesListView.swift:120` — replace hardcoded `maxHeight: 600`

- [ ] **Step 1: Add `contentMaxHeight` to ContentTabView**

In `NiwaApp/Views/ContentTabView.swift`, add a property after line 9 (`@EnvironmentObject var noteManager: NoteManager`):

```swift
var contentMaxHeight: CGFloat = 600
```

Then update the tab content (around line 50-55) from:

```swift
case .tasks:
    TaskListView()
case .notes:
    NotesListView()
```

to:

```swift
case .tasks:
    TaskListView(contentMaxHeight: contentMaxHeight)
case .notes:
    NotesListView(contentMaxHeight: contentMaxHeight)
```

- [ ] **Step 2: Add `contentMaxHeight` to TaskListView**

In `NiwaApp/Views/TaskListView.swift`, add a property after line 4 (`struct TaskListView: View {`), before `@EnvironmentObject`:

```swift
var contentMaxHeight: CGFloat = 600
```

Then replace line 147:

```swift
// Old:
.frame(maxHeight: 600)

// New:
.frame(maxHeight: contentMaxHeight)
```

- [ ] **Step 3: Add `contentMaxHeight` to NotesListView**

In `NiwaApp/Views/NotesListView.swift`, add a property after line 4 (`struct NotesListView: View {`), before `@EnvironmentObject`:

```swift
var contentMaxHeight: CGFloat = 600
```

Then replace line 120:

```swift
// Old:
.frame(maxHeight: 600)

// New:
.frame(maxHeight: contentMaxHeight)
```

- [ ] **Step 4: Build to verify everything compiles**

Run: `cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

Note: Existing call sites that use `TaskListView()`, `NotesListView()`, and `ContentTabView()` without parameters will still compile because all new properties have default values of 600 (matching current behavior).

- [ ] **Step 5: Commit**

```bash
git add NiwaApp/Views/ContentTabView.swift NiwaApp/Views/TaskListView.swift NiwaApp/Views/NotesListView.swift
git commit -m "feat: add contentMaxHeight parameter to ContentTabView, TaskListView, NotesListView"
```

---

### Task 3: Wire everything together in DropdownRootView

**Files:**
- Modify: `NiwaApp/Views/DropdownRootView.swift:21` — add `contentMaxHeight` state
- Modify: `NiwaApp/Views/DropdownRootView.swift:48` — pass height to ContentTabView
- Modify: `NiwaApp/Views/DropdownRootView.swift:54` — add ResizeDragHandle after toolbar

- [ ] **Step 1: Add state property to DropdownRootView**

In `NiwaApp/Views/DropdownRootView.swift`, add after line 21 (`@State private var resetStatusMessage = ""`):

```swift
@State private var contentMaxHeight: CGFloat = CGFloat(
    UserDefaults.standard.object(forKey: ResizeDragHandle.userDefaultsKey) as? Double ?? 600
)
```

- [ ] **Step 2: Pass height to ContentTabView**

Change line 146 (`ContentTabView()`) in the `mainContent` computed property to:

```swift
ContentTabView(contentMaxHeight: contentMaxHeight)
```

- [ ] **Step 3: Add ResizeDragHandle after bottomToolbar**

In the `body` computed property, after `bottomToolbar` (line 54) and before the closing `}` of the VStack (line 55), add:

```swift
if !showSettings && !showSounds {
    ResizeDragHandle(height: $contentMaxHeight)
}
```

- [ ] **Step 4: Clamp height on appear (for screen size changes)**

In the existing `.onAppear` block (line 81-84), add after `checkFirstLaunchAndGreeting()`:

```swift
let screenMax = min((NSScreen.main?.visibleFrame.height ?? 900) - 300, 900)
if contentMaxHeight > screenMax {
    contentMaxHeight = screenMax
    UserDefaults.standard.set(Double(screenMax), forKey: ResizeDragHandle.userDefaultsKey)
}
```

- [ ] **Step 5: Build and verify**

Run: `cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add NiwaApp/Views/DropdownRootView.swift
git commit -m "feat: wire ResizeDragHandle into DropdownRootView with persisted height"
```

---

### Task 4: Manual QA and verification

- [ ] **Step 1: Run the app**

Run: `cd "/Users/james/Claude Projects/Niwa/Niwa" && open build/Build/Products/Debug/Niwa.app` (or build and run from Xcode)

- [ ] **Step 2: Verify these behaviors**

1. **Drag handle visible** — A subtle grip line appears at the very bottom of the dropdown (below the toolbar icons)
2. **Drag down** — Dragging the handle down makes the tasks/notes area taller, showing more items
3. **Drag up** — Dragging up shrinks it back, minimum ~200pt
4. **Double-click** — Double-clicking the handle resets to the default size
5. **Persistence** — Close and reopen the dropdown — the size you set should be preserved
6. **Settings/Sounds** — When settings or sounds are shown, the drag handle disappears
7. **Hover** — Hovering over the handle highlights the grip line in sage green

- [ ] **Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: QA adjustments for resizable dropdown"
```
