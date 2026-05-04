import XCTest

@MainActor
final class FuelNowUITests: XCTestCase {
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["FuelNow"].waitForExistence(timeout: 5))
    }
}
