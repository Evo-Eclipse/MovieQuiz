import XCTest

@testable import MovieQuiz

final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    func show(quiz step: MovieQuiz.QuizStepViewModel) {
        return
    }

    func show(quiz result: MovieQuiz.QuizResultsViewModel) {
        return
    }

    func highlightImageBorder(isCorrectAnswer: Bool) {
        return
    }

    func showLoadingIndicator() {
        return
    }

    func hideLoadingIndicator() {
        return
    }

    func showNetworkError(message: String) {
        return
    }
}

final class MovieQuizPresenterTests: XCTestCase {
    func testPresenterConvertModel() throws {
        // Given
        let viewControllerMock = MovieQuizViewControllerMock()
        let sut = MovieQuizPresenter(viewController: viewControllerMock)

        let data = Data()
        let question = QuizQuestion(
            imageData: data, text: "Hey, World!", correctAnswer: true)

        // When
        let viewModel = sut.convert(model: question)

        // Then
        XCTAssertNotNil(viewModel.image)
        XCTAssertEqual(viewModel.question, "Hey, World!")
        XCTAssertEqual(viewModel.questionNumber, "1/10")
    }
}
