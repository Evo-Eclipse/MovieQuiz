import UIKit

final class ResultAlertPresenter {
    // Слабая ссылка на UIViewController, чтобы не создать циклическую
    private weak var viewController: UIViewController?

    // Инициализатор с передачей контроллера
    init(viewController: UIViewController?) {
        self.viewController = viewController
    }

    func showAlert(model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(
            title: model.buttonText,
            style: .default
        ) { _ in
            // по нажатию на кнопку выполняется замыкание
            model.completion?()
        }
        
        alert.addAction(action)
        
        viewController?.present(alert, animated: true)
    }
}

