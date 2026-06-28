import Foundation

final class ReportsService {

    func fetchReports(
        executionID: Int? = nil,
        reportType: String? = nil,
        status: String? = nil,
        date: String? = nil,
        search: String? = nil
    ) async throws -> ReportsResponseDTO {

        let endpoint = buildReportsEndpoint(
            executionID: executionID,
            reportType: reportType,
            status: status,
            date: date,
            search: search
        )

        return try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: ReportsResponseDTO.self
        )
    }

    private func buildReportsEndpoint(
        executionID: Int?,
        reportType: String?,
        status: String?,
        date: String?,
        search: String?
    ) -> String {

        var components = URLComponents()

        components.path = Endpoints.reports

        var queryItems: [URLQueryItem] = []

        if let executionID {

            queryItems.append(
                URLQueryItem(
                    name: "execution_id",
                    value: "\(executionID)"
                )
            )
        }

        if let reportType,
           !reportType.isEmpty {

            queryItems.append(
                URLQueryItem(
                    name: "type",
                    value: reportType
                )
            )
        }

        if let status,
           !status.isEmpty {

            queryItems.append(
                URLQueryItem(
                    name: "status",
                    value: status
                )
            )
        }

        if let date,
           !date.isEmpty {

            queryItems.append(
                URLQueryItem(
                    name: "date",
                    value: date
                )
            )
        }

        if let search,
           !search.isEmpty {

            queryItems.append(
                URLQueryItem(
                    name: "search",
                    value: search
                )
            )
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        return components.string ?? Endpoints.reports
    }
}