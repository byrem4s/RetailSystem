import Foundation
import Combine

@MainActor
final class ActivityViewModel: ObservableObject {

    @Published var response: ActivityResponseDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = ActivityService()

    var summary: ActivitySummaryDTO? {
        response?.summary
    }

    var activities: [ActivityDTO] {
        response?.activities ?? []
    }

    var totalCount: Int {
        summary?.total ?? 0
    }

    var completedCount: Int {
        summary?.completed ?? 0
    }

    var failedCount: Int {
        summary?.failed ?? 0
    }

    var warningCount: Int {
        summary?.warnings ?? 0
    }

    var pipelineCount: Int {
        summary?.pipelineEvents ?? 0
    }

    var f8Count: Int {
        summary?.f8Events ?? 0
    }

    var reportCount: Int {
        summary?.reportEvents ?? 0
    }

    var pipelineActivities: [ActivityDTO] {
        activities.filter {
            $0.eventType.uppercased().hasPrefix("PIPELINE_")
        }
    }

    var f8Activities: [ActivityDTO] {
        activities.filter {
            $0.eventType.uppercased().hasPrefix("F8_")
        }
    }

    var reportActivities: [ActivityDTO] {
        activities.filter {
            $0.eventType.uppercased() == "REPORTS_GENERATED"
        }
    }

    var errorActivities: [ActivityDTO] {
        activities.filter {
            $0.status.uppercased() == "FAILED"
            || $0.severity.uppercased() == "ERROR"
            || $0.severity.uppercased() == "WARNING"
        }
    }

    func loadData() async {

        isLoading = true
        errorMessage = nil

        do {

            response = try await service.fetchActivity(
                executionID: AppState.shared.selectedExecutionID
            )

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}