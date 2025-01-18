import XCTest

final class MovieQuizUITests: XCTestCase {

    let waitTime: UInt32 = 5
    let blinkTime: UInt32 = 2
    let questionsAmount: UInt = 10

    var app: XCUIApplication?

    override func setUpWithError() throws {
        app = XCUIApplication()

        guard let app = app else { return }
        app.launch()

        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    func testYesButton() {
        guard let app = self.app else { return }
        sleep(waitTime)

        let indexLabel = app.staticTexts["Index"]

        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation

        app.buttons["Yes"].tap()
        sleep(blinkTime)

        let lastPoster = app.images["Poster"]
        let lastPosterData = lastPoster.screenshot().pngRepresentation

        XCTAssertNotEqual(firstPosterData, lastPosterData)
        XCTAssertEqual(indexLabel.label, "2/10")
    }

    func testNoButton() {
        guard let app = self.app else { return }
        sleep(waitTime)

        let indexLabel = app.staticTexts["Index"]

        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation

        app.buttons["No"].tap()
        sleep(blinkTime)

        let lastPoster = app.images["Poster"]
        let lastPosterData = lastPoster.screenshot().pngRepresentation

        XCTAssertNotEqual(firstPosterData, lastPosterData)
        XCTAssertEqual(indexLabel.label, "2/10")
    }

    func testGameResult() {
        guard let app = self.app else { return }
        sleep(waitTime)

        let actions = [
            { app.buttons["Yes"].tap() },
            { app.buttons["No"].tap() },
        ]

        for _ in (0..<questionsAmount) {
            actions.randomElement()?()
            sleep(blinkTime)
        }

        let alert = app.alerts["Result Alert"]

        XCTAssertTrue(alert.exists)
        XCTAssertEqual(alert.label, "Этот раунд окончен!")
        XCTAssertEqual(alert.buttons.firstMatch.label, "Сыграть ещё раз")
    }

    func testNewGame() {
        guard let app = self.app else { return }
        sleep(waitTime)

        let actions = [
            { app.buttons["Yes"].tap() },
            { app.buttons["No"].tap() },
        ]

        for _ in (0..<questionsAmount) {
            actions.randomElement()?()
            sleep(blinkTime)
        }

        let alert = app.alerts["Result Alert"]

        alert.buttons.firstMatch.tap()
        sleep(waitTime)

        let lastIndexLabel = app.staticTexts["Index"]

        XCTAssertFalse(alert.exists)
        XCTAssertEqual(lastIndexLabel.label, "1/10")
    }
}
