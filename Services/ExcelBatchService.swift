import Foundation

final class ExcelBatchService {

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 180
        return URLSession(configuration: configuration)
    }()

    func fetchBatches() async throws -> [ExcelBatchDTO] {
        try await APIClient.shared.fetch(
            endpoint: "/v2/excel-batches",
            responseType: [ExcelBatchDTO].self
        )
    }

    func createBatch(
        _ request: ExcelBatchCreateRequestDTO
    ) async throws -> ExcelBatchDTO {
        try await APIClient.shared.post(
            endpoint: "/v2/excel-batches",
            body: request,
            responseType: ExcelBatchDTO.self
        )
    }

    func uploadSales(
        batchID: Int,
        fileURL: URL,
        branchCode: String?
    ) async throws -> ExcelUploadDTO {
        try await upload(
            endpoint: "/v2/excel-batches/\(batchID)/sales",
            fileURL: fileURL,
            fields: branchCode.map { ["branch_code": $0] } ?? [:]
        )
    }

    func uploadStock(
        batchID: Int,
        fileURL: URL
    ) async throws -> ExcelUploadDTO {
        try await upload(
            endpoint: "/v2/excel-batches/\(batchID)/stock",
            fileURL: fileURL,
            fields: [:]
        )
    }

    func analyze(batchID: Int) async throws -> ExcelBatchAnalysisDTO {
        try await APIClient.shared.post(
            endpoint: "/v2/excel-batches/\(batchID)/analyze",
            responseType: ExcelBatchAnalysisDTO.self
        )
    }

    func distribute(
        batchID: Int
    ) async throws -> ExcelBatchDistributionDTO {
        try await APIClient.shared.post(
            endpoint: "/v2/excel-batches/\(batchID)/distribute",
            responseType: ExcelBatchDistributionDTO.self
        )
    }

    func fetchRecommendations(
        batchID: Int
    ) async throws -> F8RecommendationListDTO {
        try await APIClient.shared.fetch(
            endpoint: "/v2/excel-batches/\(batchID)/recommendations",
            responseType: F8RecommendationListDTO.self
        )
    }

    func updateRecommendation(
        batchID: Int,
        recommendationID: Int,
        quantity: Int
    ) async throws -> F8RecommendationListDTO {
        try await APIClient.shared.executePatch(
            endpoint: (
                "/v2/excel-batches/\(batchID)/recommendations/"
                + "\(recommendationID)"
            ),
            body: F8RecommendationUpdateDTO(quantity: quantity),
            responseType: F8RecommendationListDTO.self
        )
    }

    func deleteRecommendation(
        batchID: Int,
        recommendationID: Int
    ) async throws -> F8RecommendationListDTO {
        try await APIClient.shared.delete(
            endpoint: (
                "/v2/excel-batches/\(batchID)/recommendations/"
                + "\(recommendationID)"
            ),
            responseType: F8RecommendationListDTO.self
        )
    }

    func downloadF8(batchID: Int) async throws -> URL {
        try await downloadFile(
            endpoint: "/v2/excel-batches/\(batchID)/f8.xlsx",
            filename: "F8_lote_\(batchID).xlsx"
        )
    }

    func downloadTemplate(_ template: ExcelTemplateKind) async throws -> URL {
        try await downloadFile(
            endpoint: (
                "/v2/excel-batches/templates/"
                + template.endpointKey
            ),
            filename: template.filename
        )
    }

    private func downloadFile(
        endpoint: String,
        filename: String
    ) async throws -> URL {
        let url = try APIClient.shared.makeURL(
            endpoint: endpoint
        )
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        APIClient.shared.authorize(&request)
        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try data.write(to: destination, options: .atomic)
        return destination
    }

    private func upload(
        endpoint: String,
        fileURL: URL,
        fields: [String: String]
    ) async throws -> ExcelUploadDTO {
        let boundary = UUID().uuidString
        let url = try APIClient.shared.makeURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        APIClient.shared.authorize(&request)

        var body = Data()
        for (name, value) in fields {
            body.appendMultipartField(
                name: name,
                value: value,
                boundary: boundary
            )
        }
        body.appendMultipartFile(
            name: "file",
            filename: fileURL.lastPathComponent,
            mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            data: try Data(contentsOf: fileURL),
            boundary: boundary
        )
        body.append("--\(boundary)--\r\n".utf8Data)

        let (data, response) = try await session.upload(
            for: request,
            from: body
        )
        try validate(data: data, response: response)
        do {
            return try JSONDecoder().decode(ExcelUploadDTO.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    private func validate(
        data: Data,
        response: URLResponse
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 401 {
                NotificationCenter.default.post(
                    name: .sessionUnauthorized,
                    object: nil
                )
            }
            throw NetworkError.serverMessage(
                serverMessage(from: data)
            )
        }
    }

    private func serverMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let dictionary = object as? [String: Any]
        else {
            return "El servidor no pudo procesar el archivo."
        }
        if let detail = dictionary["detail"] as? String {
            return detail
        }
        if let detail = dictionary["detail"] as? [String: Any],
           let message = detail["message"] as? String {
            return message
        }
        return "El servidor no pudo procesar el archivo."
    }
}

private extension String {
    var utf8Data: Data {
        data(using: .utf8) ?? Data()
    }
}

private extension Data {
    mutating func appendMultipartField(
        name: String,
        value: String,
        boundary: String
    ) {
        append("--\(boundary)\r\n".utf8Data)
        append(
            "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
                .utf8Data
        )
        append("\(value)\r\n".utf8Data)
    }

    mutating func appendMultipartFile(
        name: String,
        filename: String,
        mimeType: String,
        data: Data,
        boundary: String
    ) {
        append("--\(boundary)\r\n".utf8Data)
        append(
            (
                "Content-Disposition: form-data; name=\"\(name)\"; "
                + "filename=\"\(filename)\"\r\n"
            ).utf8Data
        )
        append("Content-Type: \(mimeType)\r\n\r\n".utf8Data)
        append(data)
        append("\r\n".utf8Data)
    }
}
