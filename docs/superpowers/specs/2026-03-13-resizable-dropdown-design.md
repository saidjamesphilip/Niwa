# Resizable Dropdown — Design Spec

## Problem

Niwa's dropdown has a fixed 600pt max height for the tasks/notes scroll area. Users with many tasks or long notes can't see enough content at once without scrolling.

## Solution

Add a vertical-only drag handle at the bottom of the dropdown. Users drag down to reveal more content, drag up to shrink. Double-click to reset to default. Size persists across sessions via UserDefaults.

## Constraints

- **Direction:** Vertical only — width stays fixed at 320pt
- **Min content height:** 200pt (enough for 3-4 tasks)
- **Max content height:** Dynamically calculated as `(NSScreen.main?.visibleFrame.height ?? 900) - 300` (300pt accounts for menu bar + hero + tabs + health pills + XP chart + toolbar + handle). Capped at 900pt absolute max. On a 13" MacBook Air (~900pt screen), this yields ~600pt — safe by default. Falls back to 900pt if no screen is available.
- **Default content height:** 600pt (current behavior)
- **Persistence:** UserDefaults stores the absolute height value
- **Reset:** Double-click the drag handle resets to 600pt default

## Window resize mechanism

The dropdown uses `MenuBarExtra` with `.menuBarExtraStyle(.window)`. This window auto-sizes to fit its SwiftUI content. When the inner `maxHeight` changes via the drag gesture, SwiftUI recalculates the layout, and the MenuBarExtra panel grows/shrinks accordingly. No direct NSWindow manipulation is needed — the resize works entirely through SwiftUI frame changes.

**Risk:** If macOS imposes an upper bound on MenuBarExtra panel height, the content may clip. This should be verified during implementation on a 13" display.

## Components

### ResizeDragHandle (new view)

A small bar (8pt tall) with a centered grip indicator (40pt wide, 3pt tall, rounded). Sits below the bottom toolbar as the very last element in the outer VStack.

**Appearance:**
- Default: `DesignTokens.Colors.textMuted` at 30% opacity grip line on transparent background
- Hover: `DesignTokens.Colors.secondary` grip line, faint secondary-tinted background
- Cursor: `ns-resize` (vertical resize)

**Gestures:**
- `DragGesture` on vertical axis — updates content height in real time (no animation during drag)
- Double-tap gesture — resets to default 600pt with `DesignTokens.Animation.viewTransition`

**Accessibility:**
- `accessibilityLabel("Resize handle")`
- `accessibilityRole(.adjustable)` with increment/decrement actions (+/- 50pt steps)

**Visibility:** Hidden when `showSettings` or `showSounds` is true (these views don't use the scroll area).

### Height state flow

1. `DropdownRootView` owns `@State var contentMaxHeight: CGFloat` initialized from UserDefaults (default 600)
2. `ResizeDragHandle` receives a `Binding<CGFloat>` and clamps drag to `200...dynamicMax` range
3. `ContentTabView` receives `contentMaxHeight` as a parameter — call site changes from `ContentTabView()` to `ContentTabView(contentMaxHeight: contentMaxHeight)`
4. `ContentTabView` passes `contentMaxHeight` to both `TaskListView` and `NotesListView`
5. Both list views use `contentMaxHeight` instead of hardcoded `.frame(maxHeight: 600)` (TaskListView:147, NotesListView:120)
6. On drag end, the new height is saved to UserDefaults

### Layout in DropdownRootView

```
VStack(spacing: 0) {
    if showSettings { settingsHeader; InlineSettingsView(...) }
    else if showSounds { soundsHeader; SoundsView(...) }
    else { mainContent }          // ← contentMaxHeight flows into here

    Divider
    bottomToolbar

    if !showSettings && !showSounds {
        ResizeDragHandle(height: $contentMaxHeight)
    }
}
```

### UserDefaults key

`niwa.dropdown.contentMaxHeight` — stores absolute `CGFloat` value, defaults to 600 if absent.

## Files to modify

| File | Change |
|------|--------|
| `NiwaApp/Views/DropdownRootView.swift` | Add `contentMaxHeight` state, place `ResizeDragHandle` after toolbar (conditionally), update `ContentTabView()` call to pass height |
| `NiwaApp/Views/ContentTabView.swift` | Add `contentMaxHeight: CGFloat` parameter, pass to `TaskListView` and `NotesListView` |
| `NiwaApp/Views/TaskListView.swift` | Add `contentMaxHeight: CGFloat` parameter, replace hardcoded `maxHeight: 600` (line 147) |
| `NiwaApp/Views/NotesListView.swift` | Add `contentMaxHeight: CGFloat` parameter, replace hardcoded `maxHeight: 600` (line 120) |
| `NiwaApp/Views/Components/ResizeDragHandle.swift` | New file — drag handle with grip indicator, drag + double-tap gestures, hover state, accessibility |

## Interaction details

- **Drag down:** Content area grows, revealing more tasks/notes
- **Drag up:** Content area shrinks, minimum 200pt
- **Double-click handle:** Snaps back to 600pt default with `DesignTokens.Animation.viewTransition`
- **Hover handle:** Grip line highlights sage green (`DesignTokens.Colors.secondary`), faint background tint
- **App relaunch:** Opens at last-used height from UserDefaults

## Edge cases

- **Screen too short:** Max is dynamically calculated from `NSScreen.main?.visibleFrame.height`. If screen is very small, the dynamic max may be less than the stored UserDefaults value — clamp to the smaller of stored value and dynamic max on load.
- **No tasks/notes:** Empty state views render fine at any height — they center vertically
- **Settings/Sounds view:** Resize handle is hidden; these views have their own fixed layout
- **First launch:** No UserDefaults value → defaults to 600pt (current behavior, no change)
- **External display changes:** If user moves between displays, the dynamic max is recalculated on next dropdown open via `onAppear`

## Out of scope

- Horizontal resize
- Per-tab height (tasks vs notes have the same height)
- Minimum window size enforcement at the NSWindow level
