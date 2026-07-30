import Foundation

final class UploadService {

    func uploadSalesFile(
        fileURL: URL
    ) async throws {

        let boundary = UUID().uuidString

        guard let uploadURL = URL(
            string:
            Environment.baseURL
            + "/uploads/sales"
        ) else {

            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: uploadURL
        )

        request.httpMethod = "POST"

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        APIClient.shared.authorize(&request)

        var data = Data()

        let filename = fileURL.lastPathComponent

        let fileData = try Data(
            contentsOf: fileURL
        )

        data.append(
            "--\(boundary)\r\n".data(
                using: .utf8
            )!
        )

        data.append(
            """
            Content-Disposition: form-data; name="file"; filename="\(filename)"
            \r\n
            """.data(using: .utf8)!
        )

        data.append(
            """
            Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
            \r\n\r\n
            """.data(using: .utf8)!
        )

        data.append(fileData)

        data.append(
            "\r\n".data(using: .utf8)!
        )

        data.append(
            "--\(boundary)--\r\n".data(
                using: .utf8
            )!
        )

        let (responseData, response) = try await URLSession.shared.upload(
            for: request,
            from: data
        )

        guard let httpResponse = response as? HTTPURLResponse else {

            throw NetworkError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            if let error = try? JSONDecoder().decode(
                UploadServerErrorDTO.self,
                from: responseData
            ) {
                throw NetworkError.serverMessage(error.detail)
            }
            throw NetworkError.serverError
        }
    }

    func runPipeline() async throws {

        let response = try await APIClient.shared.post(
            endpoint: Endpoints.runPipeline,
            responseType: PipelineRunResponseDTO.self
        )
        guard response.status == "SUCCESS",
              response.data.executed else {
            throw NetworkError.serverMessage(
                response.data.message
            )
        }
    }
}

private struct UploadServerErrorDTO: Decodable {
    let detail: String
}

private struct PipelineRunResponseDTO: Decodable {
    let status: String
    let data: PipelineRunDataDTO
}

private struct PipelineRunDataDTO: Decodable {
    let executed: Bool
    let message: String
}
