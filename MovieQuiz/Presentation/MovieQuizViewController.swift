import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {

    // MARK: - IB Outlets

    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    
    // MARK: - Private Properties
    
    private let dateFormatter = DateFormatter()
    private let questionsAmount: Int = 10
    
    private let statisticService: StatisticServiceProtocol = StatisticService()

    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0
    
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var resultAlertPresenter: ResultAlertPresenter?

    private var isButtonEnabled: Bool = false
    
    private enum Constants {
        static let borderWidth: CGFloat = 8
        static let answerDelay: TimeInterval = 1.0
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionFactory = QuestionFactory(delegate: self)
        resultAlertPresenter = ResultAlertPresenter(viewController: self)
        
        imageView.layer.masksToBounds = true // Разрешение на рисование рамки
        showCurrentQuestion()
        
        dateFormatter.dateFormat = "dd.MM.yy hh:mm"
    }
    
    // MARK: - Public Methods / QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }

        currentQuestion = question
        let viewModel = convert(model: question)

        DispatchQueue.main.async { [weak self] in
            self?.displayQuestion(quiz: viewModel)
        }
        
        isButtonEnabled = true
    }
    
    // MARK: - IB Actions

    @IBAction private func noButtonClicked(_ sender: UIButton) {
        if isButtonEnabled {
            guard let currentQuestion = currentQuestion else { return }
            showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
            isButtonEnabled = false
        }
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        if isButtonEnabled {
            guard let currentQuestion = currentQuestion else { return }
            showAnswerResult(isCorrect: currentQuestion.correctAnswer)
            isButtonEnabled = false
        }
    }
    
    // MARK: - Private Methods / Utility

    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    private func resetBorder() {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
    }
    
    // MARK: Private Methods / Display

    private func displayQuestion(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        resetBorder()
    }
    
    private func displayResults(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            // Действие по нажатию на кнопку
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        
        // Показываем алерт через ResultAlertPresenter
        resultAlertPresenter?.showAlert(model: alertModel)
    }
    
    // MARK: Private Methods / Logic

    private func showCurrentQuestion() {
        guard currentQuestionIndex >= 0, currentQuestionIndex < questionsAmount else {
            print("currentQuestionIndex is out of bounds: `\(currentQuestionIndex)` with maximum `\(questionsAmount)`")
            return
        }
        
        questionFactory?.requestNextQuestion()
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.borderWidth = Constants.borderWidth
        imageView.layer.borderColor = (isCorrect ? UIColor.ypGreen : UIColor.ypRed).cgColor
        correctAnswers += isCorrect ? 1 : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            // Сохраняем данные о текущем раунде в статистике
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            // Достаём необходимые данные из статистики
            let bestGame = statisticService.bestGame
            let gamesCount = statisticService.gamesCount
            let totalAccuracy = statisticService.totalAccuracy

            let bestGameDate = dateFormatter.string(from: bestGame.date)
            
            let finals: String = """
            Ваш результат: \(correctAnswers)/\(questionsAmount)
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
        } else {
            currentQuestionIndex += 1
            showCurrentQuestion()
        }
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

