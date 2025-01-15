import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {

    // MARK: - IB Outlets

    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    // MARK: - Private Properties

    private let dateFormatter = DateFormatter()

    private let statisticService: StatisticServiceProtocol = StatisticService()
    private let presenter = MovieQuizPresenter()

    private var correctAnswers: Int = 0

    private var questionFactory: QuestionFactoryProtocol?
    private var resultAlertPresenter: ResultAlertPresenter?
    private var currentQuestion: QuizQuestion?

    private var isButtonEnabled: Bool = false

    private enum Constants {
        static let borderWidth: CGFloat = 8
        static let answerDelay: TimeInterval = 1.0
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.viewController = self

        questionFactory = QuestionFactory(
            moviesLoader: MoviesLoader(), delegate: self)
        resultAlertPresenter = ResultAlertPresenter(viewController: self)

        imageView.layer.masksToBounds = true  // Разрешение на рисование рамки
        showLoadingIndicator()
        questionFactory?.loadData()

        dateFormatter.dateFormat = "dd.MM.yy hh:mm"
    }

    // MARK: - Public Methods / QuestionFactoryDelegate

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }

        currentQuestion = question
        let viewModel = presenter.convert(model: question)

        DispatchQueue.main.async { [weak self] in
            self?.displayQuestion(quiz: viewModel)
        }

        isButtonEnabled = true
    }

    // MARK: - IB Actions

    @IBAction private func noButtonClicked(_ sender: UIButton) {
        if isButtonEnabled {
            presenter.currentQuestion = currentQuestion
            presenter.noButtonClicked()
            isButtonEnabled = false
        }
    }

    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        if isButtonEnabled {
            presenter.currentQuestion = currentQuestion
            presenter.yesButtonClicked()
            isButtonEnabled = false
        }
    }

    // MARK: - Private Methods / Utility

    private func resetBorder() {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
    }

    func didLoadDataFromServer() {
        questionFactory?.requestNextQuestion()
        hideLoadingIndicator()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }

    // MARK: Private Methods / Display

    private func displayQuestion(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        resetBorder()
    }

    private func displayResults(quiz result: QuizResultsViewModel) {
        let model = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            // Действие по нажатию на кнопку
            guard let self = self else { return }

            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0

            self.questionFactory?.requestNextQuestion()
        }

        // Показываем алерт через ResultAlertPresenter
        resultAlertPresenter?.showAlert(model: model, type: .gameResult)
    }

    private func showLoadingIndicator() {
        activityIndicator.isHidden = false  // говорим, что индикатор загрузки не скрыт
        activityIndicator.startAnimating()  // включаем анимацию
    }

    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }

    private func showNetworkError(message: String) {
        hideLoadingIndicator()

        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз"
        ) { [weak self] in
            guard let self = self else { return }

            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0

            self.questionFactory?.requestNextQuestion()
        }

        resultAlertPresenter?.showAlert(model: model, type: .networkError)
    }

    // MARK: Private Methods / Logic

    private func showCurrentQuestion() {
        /*
        guard currentQuestionIndex >= 0, currentQuestionIndex < questionsAmount
        else {
            print(
                "currentQuestionIndex is out of bounds: `\(currentQuestionIndex)` with maximum `\(questionsAmount)`"
            )
            return
        }
        */
        questionFactory?.requestNextQuestion()
    }

    func showAnswerResult(isCorrect: Bool) {
        imageView.layer.borderWidth = Constants.borderWidth
        imageView.layer.borderColor =
            (isCorrect ? UIColor.ypGreen : UIColor.ypRed).cgColor
        correctAnswers += isCorrect ? 1 : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showNextQuestionOrResults()
        }
    }

    private func showNextQuestionOrResults() {
        guard self.presenter.isLastQuestion() else {
            self.presenter.switchToNextQuestion()
            showCurrentQuestion()
            return
        }

        // Сохраняем данные о текущем раунде в статистике
        statisticService.store(
            correct: correctAnswers, total: self.presenter.questionsAmount)

        // Достаём необходимые данные из статистики
        let bestGame = statisticService.bestGame
        let gamesCount = statisticService.gamesCount
        let totalAccuracy = statisticService.totalAccuracy

        let bestGameDate = dateFormatter.string(from: bestGame.date)

        let finals: String = """
            Ваш результат: \(correctAnswers)/\(self.presenter.questionsAmount)
            Количество сыгранных квизов: \(gamesCount)
            Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGameDate))
            Средняя точность: \(String(format: "%.2f", totalAccuracy))%
            """

        let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: finals,
            buttonText: "Сыграть ещё раз"
        )
        displayResults(quiz: viewModel)
    }
}

/*
 Mock-данные


 Картинка: The Godfather
 Настоящий рейтинг: 9,2
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: The Dark Knight
 Настоящий рейтинг: 9
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: Kill Bill
 Настоящий рейтинг: 8,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: The Avengers
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: Deadpool
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: The Green Knight
 Настоящий рейтинг: 6,6
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: Old
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ


 Картинка: The Ice Age Adventures of Buck Wild
 Настоящий рейтинг: 4,3
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ


 Картинка: Tesla
 Настоящий рейтинг: 5,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ


 Картинка: Vivarium
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
*/
