import Foundation

struct AirportSuggestionPresenter {
    private(set) var isVisible = false

    mutating func updateForInput(
        isEnabled: Bool,
        isDisabled: Bool,
        hasFocus: Bool,
        suggestionCount: Int
    ) {
        guard isEnabled, !isDisabled else {
            isVisible = false
            return
        }

        guard suggestionCount > 0 else {
            isVisible = false
            return
        }

        // Keep the panel visible on temporary focus loss so row clicks can complete.
        if hasFocus {
            isVisible = true
        }
    }

    mutating func dismiss() {
        isVisible = false
    }
}
