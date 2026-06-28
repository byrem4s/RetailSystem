import Foundation
import Combine

@MainActor
final class ReportAutomationViewModel: ObservableObject {

    @Published var config: ReportAutomationConfigDTO?
    @Published var runs: [ReportAutomationRunDTO] = []

    @Published var enabled = false
    @Published var frequency = "DAILY"
    @Published var selectedTime = Date()
    @Published var weekday = 0

    @Published var isLoading = false
    @Published var isRunningNow = false
    @Published var errorMessage: String?

    private let service = ReportAutomationService()

    let frequencyOptions = [
        "DAILY",
        "WEEKLY"
    ]

    var scheduleLabel: String {
        config?.scheduleLabel ?? "Sin programación"
    }

    var nextRunText: String {
        config?.nextRunAt ?? "No disponible"
    }

    func loadData() async {

        isLoading = true
        errorMessage = nil

        do {

            config = try await service.fetchConfig()
            runs = try await service.fetchRuns()

            syncLocalStateFromConfig()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func saveConfig() async {

        isLoading = true
        errorMessage = nil

        do {

            let components = Calendar.current.dateComponents(
                [
                    .hour,
                    .minute
                ],
                from: selectedTime
            )

            let payload = ReportAutomationConfigUpdateDTO(
                enabled: enabled,
                frequency: frequency,
                hour: components.hour ?? 8,
                minute: components.minute ?? 30,
                weekday: frequency == "WEEKLY" ? weekday : nil
            )

            config = try await service.updateConfig(
                payload: payload
            )

            syncLocalStateFromConfig()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func runNow() async {

        isRunningNow = true
        errorMessage = nil

        do {

            _ = try await service.runNow()

            config = try await service.fetchConfig()
            runs = try await service.fetchRuns()

            AppState.shared.refreshSystem()

        } catch {

            errorMessage = error.localizedDescription
        }

        isRunningNow = false
    }

    private func syncLocalStateFromConfig() {

        guard let config else {
            return
        }

        enabled = config.enabled
        frequency = config.frequency
        weekday = config.weekday ?? 0

        var components = DateComponents()
        components.hour = config.hour
        components.minute = config.minute

        if let date = Calendar.current.date(
            from: components
        ) {

            selectedTime = date
        }
    }
}