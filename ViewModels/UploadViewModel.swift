import Foundation
import Combine

@MainActor
final class UploadViewModel: ObservableObject {

    @Published var isUploading = false

    @Published var uploadSuccess = false

    @Published var errorMessage: String?
    @Published var pipelineExecuted = false

    private let service = UploadService()

    func uploadFile(
        url: URL
    ) async {

        isUploading = true

        uploadSuccess = false

        errorMessage = nil

        do {

            try await service.uploadSalesFile(
                fileURL: url
            )

            uploadSuccess = true

            try await service.runPipeline()

            pipelineExecuted = true

            AppState.shared.refresh()

        } catch {

            errorMessage = error.localizedDescription
        }

        isUploading = false
    }
}