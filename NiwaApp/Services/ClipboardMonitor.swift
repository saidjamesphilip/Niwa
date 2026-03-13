import AppKit
import SwiftData
import Observation

@MainActor
@Observable
final class ClipboardMonitor {
    private let modelContext: ModelContext
    private var lastChangeCount: Int
    private var pollTimer: Timer?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }

    func startMonitoring() {
        stopMonitoring()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let entry = ClipboardEntry(text: text)
        modelContext.insert(entry)
        trimEntries()
        try? modelContext.save()
    }

    private func trimEntries() {
        var descriptor = FetchDescriptor<ClipboardEntry>(
            sortBy: [SortDescriptor(\.copiedAt, order: .reverse)]
        )
        descriptor.fetchOffset = XPConstants.maxClipboardEntries
        if let excess = try? modelContext.fetch(descriptor) {
            for entry in excess {
                modelContext.delete(entry)
            }
        }
    }

    func reCopy(_ entry: ClipboardEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.text, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
    }

}
