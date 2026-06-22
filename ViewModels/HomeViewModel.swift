import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var homeData: HomeDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = HomeService()

    var userName: String {
        homeData?.user.name ?? "Equipo"
    }

    var userBranch: String {
        homeData?.user.branch ?? "Todas las sucursales"
    }

    var recentActivity: [HomeRecentActivityDTO] {
        homeData?.recentActivity ?? []
    }

    func loadData() async {

        isLoading = true
        errorMessage = nil

        do {

            homeData = try await service.fetchHomeData()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}