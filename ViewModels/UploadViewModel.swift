import Foundation
import Combine

@MainActor
final class UploadViewModel: ObservableObject {

    @Published var isUploading = false
    @Published var isRunningPipeline = false

    @Published var uploadSuccess = false
    @Published var errorMessage: String?
    @Published var pipelineExecuted = false

    private let service = UploadService()   

    func uploadFile(url: URL) async {

        isUploading = true
        errorMessage = nil
        uploadSuccess = false
        pipelineExecuted = false

        let hasAccess = url.startAccessingSecurityScopedResource()

        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }

            isUploading = false
        }

        do {

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)

            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }

            try FileManager.default.copyItem(
                at: url,
                to: tempURL
            )

            try await service.uploadSalesFile(
                fileURL: tempURL
            )

            uploadSuccess = true

        } catch {

            errorMessage = error.localizedDescription
        }
    }

    func runPipeline() async {

        isRunningPipeline = true
        errorMessage = nil
        pipelineExecuted = false

        defer {
            isRunningPipeline = false
        }

        do {

            try await service.runPipeline()

            pipelineExecuted = true

            AppState.shared.refreshSystem()

        } catch {

            errorMessage = error.localizedDescription
        }
    }
}