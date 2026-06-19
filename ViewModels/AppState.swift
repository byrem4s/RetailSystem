import Foundation

@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    @Published var refreshID = UUID()

    private init() {}

    func refreshSystem() {

        refreshID = UUID()
    }

    func refresh() {

        refreshID = UUID()
    }
}