import UIKit

// MARK: - Models

private struct QuizQuestion {
    let image: String
    let text: String
    let correctAnswer: Bool
}

private struct QuizStepViewModel {
    let image: UIImage
    let question: String
    let questionNumber: String
}

private struct QuizResultsViewModel {
    let title: String
    let text: String
    let buttonText: String
}

// MARK: - Constants

private enum Constants {
    static let borderWidth: CGFloat = 8
    static let answerDelay: TimeInterval = 1.0
}

final class MovieQuizViewController: UIViewController {

    // MARK: - IB Outlets

    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    
    // MARK: - Private Properties

    private let questions: [QuizQuestion] = [
        QuizQuestion(
            image: "The Godfather",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Dark Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Kill Bill",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Avengers",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Deadpool",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Green Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Old",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "The Ice Age Adventures of Buck Wild",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Tesla",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Vivarium",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false)
    ]
    
    private let dateFormatter = DateFormatter()
    
    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0
    private var isButtonEnabled: Bool = false
    
    private enum GameStats {
        static var rounds: Int = 0
        static var record: (score: Int, date: String) = (-1, "")
        static var totalScore: Int = 0
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.masksToBounds = true // Разрешение на рисование рамки
        showCurrentQuestion()
        
        dateFormatter.dateFormat = "dd.MM.yy hh:mm"
    }
    
    // MARK: - IB Actions

    @IBAction private func noButtonClicked(_ sender: UIButton) {
        if isButtonEnabled {
            showAnswerResult(isCorrect: !questions[currentQuestionIndex].correctAnswer)
            isButtonEnabled = false
        }
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        if isButtonEnabled {
            showAnswerResult(isCorrect: questions[currentQuestionIndex].correctAnswer)
            isButtonEnabled = false
        }
    }
    
    // MARK: - Private Methods / Utility

    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questions.count)"
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
        let alert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { _ in
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            let firstQuestion = self.questions[self.currentQuestionIndex]
            let viewModel = self.convert(model: firstQuestion)
            self.displayQuestion(quiz: viewModel)
        }
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Private Methods / Logic

    private func showCurrentQuestion() {
        guard currentQuestionIndex >= 0, currentQuestionIndex < questions.count else {
            print("currentQuestionIndex is out of bounds: `\(currentQuestionIndex)` with maximum `\(questions.count)`")
            return
        }
        let nextQuestion = questions[currentQuestionIndex]
        let viewModel = convert(model: nextQuestion)
        
        displayQuestion(quiz: viewModel)
        isButtonEnabled = true
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.borderWidth = Constants.borderWidth
        imageView.layer.borderColor = (isCorrect ? UIColor.ypGreen : UIColor.ypRed).cgColor
        correctAnswers += isCorrect ? 1 : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
        }
    }
    
    private func updateGameStats() {
        if correctAnswers > GameStats.record.score {
            GameStats.record.score = correctAnswers
            GameStats.record.date = dateFormatter.string(from: Date())
        }
        GameStats.rounds += 1
        GameStats.totalScore += correctAnswers
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questions.count - 1 {
            updateGameStats()
            
            let totalQuestionsPlayed = GameStats.rounds * questions.count
            let averageScore = totalQuestionsPlayed == 0 ? 0 : (Double(GameStats.totalScore) / Double(totalQuestionsPlayed)) * 100
            
            let finals: String = """
            Ваш результат: \(correctAnswers)/\(questions.count)
            Количество сыгранных квизов: \(GameStats.rounds)
            Рекорд: \(GameStats.record.score)/\(questions.count) (\(GameStats.record.date))
            Средняя точность: \(String(format: "%.2f", averageScore))%
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

