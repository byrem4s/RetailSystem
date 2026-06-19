import Foundation


@MainActor
final class HomeViewModel:
ObservableObject {

    @Published var homeData:
    HomeDTO?

    @Published var warnings:
    [WarningModel] = []

    @Published var exports:
    [ExportSnapshotModel] = []

    @Published var isLoading =
    false

    @Published var errorMessage:
    String?

    private let service =
    HomeService()

    func loadData() async {

        isLoading = true

        errorMessage = nil

        do {

            let data =
            try await service.fetchHomeData()

            homeData = data

            warnings =
            try await service.fetchWarnings()

            exports =
            try await service.fetchExports()

        } catch {

            errorMessage =
            error.localizedDescription
        }

        isLoading = false
    }
}