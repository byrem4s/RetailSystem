import Foundation

@MainActor
final class NotificationPreferencesViewModel: ObservableObject {
    @Published private(set) var preferences: [NotificationPreferenceDTO] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service = NotificationService()

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            preferences = try await service.fetchPreferences()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func set(_ item: NotificationPreferenceDTO, enabled: Bool) async {
        guard let index = preferences.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        let previous = preferences[index].enabled
        preferences[index].enabled = enabled
        do {
            preferences[index] = try await service.updatePreference(
                type: item.notificationType,
                enabled: enabled
            )
        } catch {
            preferences[index].enabled = previous
            errorMessage = error.localizedDescription
        }
    }
}
