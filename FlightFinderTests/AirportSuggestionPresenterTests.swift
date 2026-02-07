import Testing
@testable import FlightFinder

struct AirportSuggestionPresenterTests {
    @Test("panel remains visible on focus loss until explicit dismiss")
    func remainsVisibleOnFocusLoss() {
        var presenter = AirportSuggestionPresenter()
        presenter.updateForInput(isEnabled: true, isDisabled: false, hasFocus: true, suggestionCount: 4)
        #expect(presenter.isVisible)

        presenter.updateForInput(isEnabled: true, isDisabled: false, hasFocus: false, suggestionCount: 4)
        #expect(presenter.isVisible)
    }

    @Test("panel hides when there are no suggestions")
    func hidesWhenNoSuggestions() {
        var presenter = AirportSuggestionPresenter()
        presenter.updateForInput(isEnabled: true, isDisabled: false, hasFocus: true, suggestionCount: 2)
        #expect(presenter.isVisible)

        presenter.updateForInput(isEnabled: true, isDisabled: false, hasFocus: true, suggestionCount: 0)
        #expect(!presenter.isVisible)
    }

    @Test("explicit dismiss closes panel")
    func explicitDismiss() {
        var presenter = AirportSuggestionPresenter()
        presenter.updateForInput(isEnabled: true, isDisabled: false, hasFocus: true, suggestionCount: 2)
        #expect(presenter.isVisible)

        presenter.dismiss()
        #expect(!presenter.isVisible)
    }
}
