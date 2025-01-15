import UIKit

final class MovieQuizPresenter {

    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0

    weak var viewController: MovieQuizViewController?
    var currentQuestion: QuizQuestion?

    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }

    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }

    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }

    func yesButtonClicked() {
        guard let currentQuestion = currentQuestion else { return }
        viewController?.showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    func noButtonClicked() {
        guard let currentQuestion = currentQuestion else { return }
        viewController?.showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }

    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.imageData) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

}
