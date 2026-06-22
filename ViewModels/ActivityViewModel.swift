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

    var movementsCount: Int {
        summary?.movements ?? 0
    }

    var completedCount: Int {
        summary?.completed ?? 0
    }

    var partialCount: Int {
        summary?.partial ?? 0
    }

    var withoutReplenishmentCount: Int {
        summary?.withoutReplenishment ?? 0
    }

    var movementActivities: [ActivityDTO] {
        activities.filter {
            $0.type.uppercased() == "MOVEMENT_COMPLETED"
        }
    }

    var decisionActivities: [ActivityDTO] {
        activities.filter {
            $0.type.uppercased() == "SYSTEM_DECISION"
            || $0.type.uppercased() == "WITHOUT_REPLENISHMENT"
        }
    }

    var resolvedActivities: [ActivityDTO] {
        activities.filter {
            $0.status.uppercased() == "COMPLETED"
            || $0.status.uppercased() == "PARTIAL"
        }
    }

    func loadData() async {

        isLoading = true
        errorMessage = nil

        do {

            response = try await service.fetchActivity()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}