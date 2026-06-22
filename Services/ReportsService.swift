import Foundation

final class ReportsService {

    func fetchReports() async throws -> ReportsResponseDTO {

        try await APIClient.shared.fetch(
            endpoint: "/reports",
            responseType: ReportsResponseDTO.self
        )
    }

    func downloadReport(
        _ report: ReportDTO
    ) async throws -> URL {

        let remoteURL = try makeDownloadURL(
            from: report.downloadURL
        )

        let (
            temporaryURL,
            response
        ) = try await URLSession.shared.download(
            from: remoteURL
        )

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {

            throw URLError(.badServerResponse)
        }

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(report.fileName)

        if FileManager.default.fileExists(
            atPath: destinationURL.path
        ) {

            try FileManager.default.removeItem(
                at: destinationURL
            )
        }

        try FileManager.default.moveItem(
            at: temporaryURL,
            to: destinationURL
        )

        return destinationURL
    }

    private func makeDownloadURL(
        from downloadURL: String
    ) throws -> URL {

        if let absoluteURL = URL(
            string: downloadURL
        ),
           absoluteURL.scheme != nil {

            return absoluteURL
        }

        guard let baseURL = URL(
            string: Environment.baseURL
        ) else {

            throw URLError(.badURL)
        }

        guard let finalURL = URL(
            string: downloadURL,
            relativeTo: baseURL
        )?.absoluteURL else {

            throw URLError(.badURL)
        }

        return finalURL
    }
}