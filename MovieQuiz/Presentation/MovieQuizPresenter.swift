import UIKit

final class MovieQuizPresenter {

    weak var viewController: MovieQuizViewController?
    var currentQuestion: QuizQuestion?

    var questionFactory: QuestionFactoryProtocol?
    var statisticService: StatisticServiceProtocol?

    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    var correctAnswers: Int = 0

    private var isButtonEnabled: Bool = false

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
        didAnswer(isYes: true)
    }

    func noButtonClicked() {
        didAnswer(isYes: false)
    }

    private func didAnswer(isYes: Bool) {
        guard isButtonEnabled else { return }
        guard let currentQuestion = currentQuestion else { return }

        viewController?.showAnswerResult(
            isCorrect: currentQuestion.correctAnswer ? isYes : !isYes)
        isButtonEnabled = false
    }

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }

        currentQuestion = question
        let viewModel = convert(model: question)

        DispatchQueue.main.async { [weak self] in
            self?.viewController?.displayQuestion(quiz: viewModel)
        }

        isButtonEnabled = true
    }

    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.imageData) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

    func showNextQuestionOrResults() {
        guard isLastQuestion() else {
            switchToNextQuestion()
            questionFactory?.requestNextQuestion()
            return
        }

        // Сохраняем данные о текущем раунде в статистике
        statisticService?.store(
            correct: correctAnswers, total: self.questionsAmount)

        // Достаём необходимые данные из статистики
        guard
            let bestGame = statisticService?.bestGame,
            let gamesCount = statisticService?.gamesCount,
            let totalAccuracy = statisticService?.totalAccuracy
        else {
            return
        }

        let bestGameDate = Date().dateTimeString

        let finals: String = """
            Ваш результат: \(correctAnswers)/\(self.questionsAmount)
            Количество сыгранных квизов: \(gamesCount)
            Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGameDate))
            Средняя точность: \(String(format: "%.2f", totalAccuracy))%
            """

        let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: finals,
            buttonText: "Сыграть ещё раз"
        )
        viewController?.displayResults(quiz: viewModel)
    }

}
