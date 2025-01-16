import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {

    private weak var viewController: MovieQuizViewController?
    private var currentQuestion: QuizQuestion?

    private var questionFactory: QuestionFactoryProtocol?
    private var statisticService: StatisticServiceProtocol?

    let questionsAmount: Int = 10

    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0

    private var isInteractionAllowed: Bool = false

    init(
        viewController: MovieQuizViewController,
        statisticService: StatisticServiceProtocol = StatisticService()
    ) {
        self.viewController = viewController
        self.statisticService = statisticService

        // Создаём фабрику вопросов и «включаем» её
        questionFactory = QuestionFactory(
            moviesLoader: MoviesLoader(), delegate: self)
        viewController.showLoadingIndicator()
        questionFactory?.loadData()
    }

    // MARK: - Public Methods / QuestionFactoryDelegate

    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }

        currentQuestion = question
        let viewModel = convert(model: question)

        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }

        isInteractionAllowed = true
    }

    // MARK: - Public Methods / Utility

    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.imageData) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }

    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }

    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }

    // MARK: - Methods / Button Logic

    func yesButtonClicked() {
        didAnswer(isYes: true)
    }

    func noButtonClicked() {
        didAnswer(isYes: false)
    }

    private func didAnswer(isYes: Bool) {
        guard isInteractionAllowed else { return }
        guard let currentQuestion = currentQuestion else { return }

        let isCorrect = (currentQuestion.correctAnswer == isYes)

        didAnswer(isCorrectAnswer: isCorrect)
        showAnswerResult(isCorrect: isCorrect)

        isInteractionAllowed = false
    }

    func didAnswer(isCorrectAnswer: Bool) {
        correctAnswers += isCorrectAnswer ? 1 : 0
    }

    // MARK: - Methods / Quiz Logic

    func showAnswerResult(isCorrect: Bool) {
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
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
        viewController?.show(quiz: viewModel)
    }
}
