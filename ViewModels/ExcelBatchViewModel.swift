import Foundation

@MainActor
final class ExcelBatchViewModel: ObservableObject {

    @Published private(set) var batches: [ExcelBatchDTO] = []
    @Published var selectedBatchID: Int?
    @Published var mode: ExcelBatchMode = .distributed
    @Published var periodFrom = Calendar.current.date(
        byAdding: .day,
        value: -6,
        to: Date()
    ) ?? Date()
    @Published var periodTo = Date()
    @Published var enforceSalesPeriod = false
    @Published var selectedBranchCode: String?
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    @Published var downloadedFileURL: URL?
    @Published var downloadedFileLabel: String?

    private let service = ExcelBatchService()

    var selectedBatch: ExcelBatchDTO? {
        guard let selectedBatchID else {
            return nil
        }
        return batches.first { $0.id == selectedBatchID }
    }

    func load() async {
        await perform {
            let values = try await service.fetchBatches()
            batches = values
            if !values.contains(where: { $0.id == selectedBatchID }) {
                selectedBatchID = values.first?.id
            }
            syncSelectedBranch()
        }
    }

    func createBatch() async {
        await perform {
            let batch = try await service.createBatch(
                ExcelBatchCreateRequestDTO(
                    mode: mode,
                    periodFrom: Self.apiDate(periodFrom),
                    periodTo: Self.apiDate(periodTo),
                    enforceSalesPeriod: enforceSalesPeriod,
                    expectedBranchCodes: nil
                )
            )
            batches.insert(batch, at: 0)
            selectedBatchID = batch.id
            noticeMessage = "Lote creado correctamente."
            syncSelectedBranch()
        }
    }

    func uploadSales(url: URL, role: UserRole?) async {
        guard let batch = selectedBatch else {
            errorMessage = "Seleccioná un lote."
            return
        }
        let succeeded = await withSecurityAccess(to: url) { accessibleURL in
            let branchCode = (
                role == .systemOwner || role == .companyAdmin
            ) && batch.mode == .distributed
                ? selectedBranchCode
                : nil
            _ = try await service.uploadSales(
                batchID: batch.id,
                fileURL: accessibleURL,
                branchCode: branchCode
            )
            noticeMessage = "Ventas cargadas y validadas."
        }
        if succeeded {
            await refreshSelectedBatch()
        }
    }

    func uploadStock(url: URL) async {
        guard let batch = selectedBatch else {
            errorMessage = "Seleccioná un lote."
            return
        }
        let succeeded = await withSecurityAccess(to: url) { accessibleURL in
            _ = try await service.uploadStock(
                batchID: batch.id,
                fileURL: accessibleURL
            )
            noticeMessage = "Stock consolidado cargado."
        }
        if succeeded {
            await refreshSelectedBatch()
        }
    }

    func analyze() async {
        guard let batch = selectedBatch else {
            errorMessage = "Seleccioná un lote."
            return
        }
        await perform {
            let result = try await service.analyze(batchID: batch.id)
            replace(result.batch)
            noticeMessage = (
                "Análisis \(result.algorithmVersion) completado. "
                + "F8 disponible."
            )
        }
    }

    func downloadF8() async {
        guard let batch = selectedBatch else {
            errorMessage = "Seleccioná un lote."
            return
        }
        await perform {
            downloadedFileURL = try await service.downloadF8(
                batchID: batch.id
            )
            downloadedFileLabel = "Compartir F8"
            noticeMessage = "F8 descargado."
        }
    }

    func distribute() async {
        guard let batch = selectedBatch else {
            errorMessage = "Seleccioná un período."
            return
        }
        await perform {
            let result = try await service.distribute(batchID: batch.id)
            replace(result.batch)
            noticeMessage = result.totalTransfers == 0
                ? "F8 distribuido. No había movimientos para crear."
                : (
                    "F8 distribuido: \(result.totalTransfers) movimientos "
                    + "enviados a las sucursales."
                )
        }
    }

    func downloadTemplate(_ template: ExcelTemplateKind) async {
        await perform {
            downloadedFileURL = try await service.downloadTemplate(template)
            downloadedFileLabel = "Compartir \(template.displayName.lowercased())"
            noticeMessage = "\(template.displayName) descargada."
        }
    }

    func select(_ batch: ExcelBatchDTO) {
        selectedBatchID = batch.id
        downloadedFileURL = nil
        downloadedFileLabel = nil
        noticeMessage = nil
        syncSelectedBranch()
    }

    private func refreshSelectedBatch() async {
        let previousID = selectedBatchID
        await load()
        selectedBatchID = previousID
        syncSelectedBranch()
    }

    private func syncSelectedBranch() {
        guard let batch = selectedBatch,
              batch.mode == .distributed else {
            selectedBranchCode = nil
            return
        }
        let options = batch.missingBranchCodes.isEmpty
            ? batch.expectedBranchCodes
            : batch.missingBranchCodes
        if !options.contains(selectedBranchCode ?? "") {
            selectedBranchCode = options.first
        }
    }

    private func replace(_ batch: ExcelBatchDTO) {
        if let index = batches.firstIndex(where: { $0.id == batch.id }) {
            batches[index] = batch
        } else {
            batches.insert(batch, at: 0)
        }
        selectedBatchID = batch.id
        syncSelectedBranch()
    }

    private func perform(_ operation: () async throws -> Void) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func withSecurityAccess(
        to url: URL,
        operation: (URL) async throws -> Void
    ) async -> Bool {
        isBusy = true
        errorMessage = nil
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
            isBusy = false
        }
        do {
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "\(UUID().uuidString)-\(url.lastPathComponent)"
                )
            try FileManager.default.copyItem(at: url, to: temporaryURL)
            defer {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
            try await operation(temporaryURL)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private static func apiDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
