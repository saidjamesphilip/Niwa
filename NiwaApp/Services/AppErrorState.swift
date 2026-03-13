import Foundation
import Observation

@MainActor
@Observable
final class AppErrorState {
    var bannerMessage: String?

    func showError(_ message: String) {
        bannerMessage = message
    }

    func dismiss() {
        bannerMessage = nil
    }
}
