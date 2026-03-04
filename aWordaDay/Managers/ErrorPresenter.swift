//
//  ErrorPresenter.swift
//  aWordaDay
//
//  Unified error presentation for the app.
//

import SwiftUI

@Observable
final class ErrorPresenter: ErrorPresenterProtocol {
    static let shared = ErrorPresenter()

    var currentError: AppError?
    var showError: Bool = false

    private init() {}

    func present(_ error: Error, context: String = "") {
        let appError = AppError(
            title: L10n.System.somethingWentWrong,
            message: error.localizedDescription,
            context: context
        )

        DispatchQueue.main.async { [weak self] in
            self?.currentError = appError
            self?.showError = true
        }

        // Also log to analytics
        Task.detached(priority: .utility) {
            FirebaseAnalyticsManager.shared.logError(error, context: context)
        }
    }

    func presentMessage(_ title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.currentError = AppError(title: title, message: message, context: "")
            self?.showError = true
        }
    }

    func dismiss() {
        showError = false
        currentError = nil
    }
}

struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let context: String
}

// MARK: - View Modifier for Error Alerts
struct ErrorAlertModifier: ViewModifier {
    @Bindable var presenter: ErrorPresenter

    func body(content: Content) -> some View {
        content
            .alert(
                presenter.currentError?.title ?? L10n.System.error,
                isPresented: $presenter.showError,
                presenting: presenter.currentError
            ) { _ in
                Button(L10n.Common.ok) {
                    presenter.dismiss()
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    func withErrorAlert(_ presenter: ErrorPresenter = .shared) -> some View {
        modifier(ErrorAlertModifier(presenter: presenter))
    }
}
