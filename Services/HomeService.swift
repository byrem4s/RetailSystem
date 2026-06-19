import Foundation

final class HomeService {

    func fetchHomeData() async throws -> HomeDTO {

        return try await APIClient.shared.fetch(

            endpoint: "/system/health",

            responseType: HomeDTO.self
        )
    }

    func fetchWarnings() async throws
    -> [WarningModel] {

    return try await APIClient.shared.fetch(

        endpoint: "/system/warnings",

        responseType: [WarningModel].self
    )

    }

    func fetchExports()
        async throws -> [ExportSnapshotModel] {

            return try await APIClient.shared.fetch(

                endpoint:
                "/exports/history",

                responseType:
                [ExportSnapshotModel].self
            )
        }

}