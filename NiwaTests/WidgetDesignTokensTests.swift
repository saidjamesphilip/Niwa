import XCTest
import SwiftUI
@testable import Niwa

final class WidgetDesignTokensTests: XCTestCase {

    // MARK: - Token existence (catch accidental deletion)

    func testAllTokensExist() {
        // These are used across 4 widget views — if any are removed, widgets break
        _ = WidgetDesignTokens.primary
        _ = WidgetDesignTokens.secondary
        _ = WidgetDesignTokens.textPrimary
        _ = WidgetDesignTokens.textSecondary
        _ = WidgetDesignTokens.textMuted
        _ = WidgetDesignTokens.background
        _ = WidgetDesignTokens.xpTrack
    }

    // MARK: - Token distinctness

    func testPrimaryAndSecondary_areDifferent() {
        // Primary (terracotta) and secondary (sage) must be visually distinct
        XCTAssertNotEqual(
            WidgetDesignTokens.primary.description,
            WidgetDesignTokens.secondary.description
        )
    }

    func testTextHierarchy_hasDifferentLevels() {
        // textPrimary, textSecondary, textMuted should all be different
        let descriptions = [
            WidgetDesignTokens.textPrimary.description,
            WidgetDesignTokens.textSecondary.description,
            WidgetDesignTokens.textMuted.description,
        ]
        XCTAssertEqual(descriptions.count, Set(descriptions).count, "Text colors should be distinct")
    }
}
