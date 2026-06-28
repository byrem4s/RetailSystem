import Foundation

final class ReportsService {

    private let reportsEndpoint = "/reports"

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

    func downloadReport(
        _ report: ReportDTO
    ) async throws -> URL {

        let url = try APIClient.shared.makeURL(
            endpoint: report.downloadURL
        )

        let request = URLRequest(
            url: url
        )

        let (
            temporaryURL,
            response
        ) = try await URLSession.shared.download(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError
        }

        let fileManager = FileManager.default

        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let destinationURL = documentsURL.appendingPathComponent(
            report.fileName
        )

        if fileManager.fileExists(
            atPath: destinationURL.path
        ) {

            try fileManager.removeItem(
                at: destinationURL
            )
        }

        try fileManager.moveItem(
            at: temporaryURL,
            to: destinationURL
        )

        return destinationURL
    }

    private func buildReportsEndpoint(
        executionID: Int?,
        reportType: String?,
        status: String?,
        date: String?,
        search: String?
    ) -> String {

        var components = URLComponents()

        components.path = reportsEndpoint

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

        return components.string ?? reportsEndpoint
    }
}