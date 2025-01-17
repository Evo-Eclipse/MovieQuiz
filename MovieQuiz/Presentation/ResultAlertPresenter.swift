import UIKit

final class ResultAlertPresenter {
    // Слабая ссылка на UIViewController, чтобы не создать циклическую
    private weak var viewController: UIViewController?

    // Инициализатор с передачей контроллера
    init(viewController: UIViewController?) {
        self.viewController = viewController
    }

    func showAlert(model: AlertModel, type: AlertType) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert
        )

        let action = UIAlertAction(
            title: model.buttonText,
            style: .default
        ) { _ in
            // По нажатию на кнопку выполняется замыкание
            model.completion?()
        }

        alert.addAction(action)

        // Устанавливаем Accessibility Identifier для алерта
        alert.view.accessibilityIdentifier = type.accessibilityIdentifier

        viewController?.present(alert, animated: true)
    }
}

// Локальный enum
enum AlertType {
    case gameResult
    case networkError

    var accessibilityIdentifier: String {
        return switch self {
        case .gameResult: "Result Alert"
        case .networkError: "Network Error Alert"
        }
    }
}
