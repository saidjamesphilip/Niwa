import Foundation
import SwiftData

enum ModelContainerSetup {
    static let allModelTypes: [any PersistentModel.Type] = [
        NiwaTask.self,
        NiwaNote.self,

        TimerSession.self,
        HealthEvent.self,
        XPEvent.self,
        UserProfile.self,
        MeetingReview.self,
    ]

    /// Creates a ModelContainer using the Application Support directory.
    /// When App Groups are configured (with a dev certificate), switch to the shared container URL.
    static func createContainer() throws -> ModelContainer {
        let schema = Schema(allModelTypes)

        // Use Application Support for local dev (no App Group needed)
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let niwaDir = appSupport.appendingPathComponent("Niwa", isDirectory: true)
        try FileManager.default.createDirectory(at: niwaDir, withIntermediateDirectories: true)

        let storeURL = niwaDir.appendingPathComponent("niwa.store")

        let config = ModelConfiguration(
            "Niwa",
            schema: schema,
            url: storeURL
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema migration failed — remove old store and recreate
            let fm = FileManager.default
            let storeFiles = try fm.contentsOfDirectory(at: niwaDir, includingPropertiesForKeys: nil)
            for file in storeFiles where file.lastPathComponent.hasPrefix("niwa.store") {
                try? fm.removeItem(at: file)
            }
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}
