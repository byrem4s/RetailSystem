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

        let (_, response) = try await URLSession.shared.upload(
            for: request,
            from: data
        )

        guard let httpResponse = response as? HTTPURLResponse else {

            throw NetworkError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {

            throw NetworkError.serverError
        }
    }

    func runPipeline() async throws {

        guard let url = URL(
            string:
            Environment.baseURL
            + Endpoints.runPipeline
        ) else {

            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "POST"

        let (_, response) =
        try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse =
                response as? HTTPURLResponse

        else {

            throw NetworkError.invalidResponse
        }

        guard 200...299 ~=
                httpResponse.statusCode

        else {

            throw NetworkError.serverError
        }
    }
}