import Foundation

final class StatisticService: StatisticServiceProtocol {
    private let storage: UserDefaults = .standard

    private enum Keys {
        enum Games {
            static let count = "statistic.games.count"
        }

        enum BestGame {
            static let correct = "statistic.best.correct"
            static let total = "statistic.best.total"
            static let date = "statistic.best.date"
        }

        enum Questions {
            static let correct = "statistic.questions.correct"
            static let total = "statistic.questions.total"
        }
    }

    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.Games.count)
        }
        set {
            storage.set(newValue, forKey: Keys.Games.count)
        }
    }

    var bestGame: GameResult {
        get {
            let correct = storage.integer(forKey: Keys.BestGame.correct)
            let total = storage.integer(forKey: Keys.BestGame.total)
            let date =
                storage.object(forKey: Keys.BestGame.date) as? Date
                ?? .distantPast
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: Keys.BestGame.correct)
            storage.set(newValue.total, forKey: Keys.BestGame.total)
            storage.set(newValue.date, forKey: Keys.BestGame.date)
        }
    }

    var totalAccuracy: Double {
        let correct = storage.double(forKey: Keys.Questions.correct)
        let total = storage.double(forKey: Keys.Questions.total)
        return total > 0 ? (correct / total) * 100 : 0
    }

    func store(correct count: Int, total amount: Int) {
        // Обновление общего количества правильных ответов и вопросов
        let previousCorrect = storage.integer(forKey: Keys.Questions.correct)
        let previousTotal = storage.integer(forKey: Keys.Questions.total)
        storage.set(previousCorrect + count, forKey: Keys.Questions.correct)
        storage.set(previousTotal + amount, forKey: Keys.Questions.total)

        // Обновление счётчика игр
        gamesCount += 1

        // Проверка и обновление bestGame
        let currentGameResult = GameResult(
            correct: count, total: amount, date: Date())
        if currentGameResult.isBetterThan(bestGame) {
            bestGame = currentGameResult
        }
    }
}
