import SwiftUI

struct ReportsView: View {
    @StateObject private var viewModel = ExcelBatchViewModel()
    @State private var filter: HistoryFilter = .all
    @State private var showingFilePreview = false
    @State private var intelligenceBatchID: Int?

    private enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "Todos"
        case distributed = "Distribuidos"
        case pending = "Sin distribuir"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ResponsiveScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        PageHeading(
                            eyebrow: "Consulta",
                            title: "Historial",
                            subtitle: (
                                "Revisá F8 generados anteriormente. "
                                + "La carga de archivos se realiza únicamente "
                                + "desde Reposición."
                            )
                        )

                        Picker("Filtro", selection: $filter) {
                            ForEach(HistoryFilter.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        historyContent
                    }
                }

                if viewModel.isBusy {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                    ProgressView("Preparando F8…")
                        .padding(AppSpacing.large)
                        .background(.regularMaterial)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppSpacing.cardRadius,
                                style: .continuous
                            )
                        )
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isBusy)
                    .accessibilityLabel("Actualizar historial")
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showingFilePreview) {
                if let url = viewModel.downloadedFileURL {
                    FilePreview(url: url)
                        .ignoresSafeArea()
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { intelligenceBatchID != nil },
                    set: { if !$0 { intelligenceBatchID = nil } }
                )
            ) {
                if let batchID = intelligenceBatchID {
                    BatchIntelligenceSheet(batchID: batchID, isGlobal: true)
                }
            }
            .alert(
                "No se pudo abrir el F8",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        if filteredBatches.isEmpty {
            AppCard {
                ContentUnavailableView(
                    "Sin resultados",
                    systemImage: "clock.arrow.circlepath",
                    description: Text(
                        "Los F8 aparecerán acá después de generar el análisis."
                    )
                )
            }
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 275), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(filteredBatches) { batch in
                    historyCard(batch)
                }
            }

            if let fileURL = viewModel.downloadedFileURL {
                AppCard {
                    HStack(spacing: AppSpacing.medium) {
                        IconBadge(
                            systemName: "doc.text.fill",
                            color: AppColors.green
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            Text("F8 preparado")
                                .font(AppTypography.cardTitle)
                            Text("Ya podés abrirlo o compartirlo.")
                                .font(.caption)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        Spacer()
                        ShareLink(item: fileURL) {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        }
    }

    private func historyCard(_ batch: ExcelBatchDTO) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.regular) {
                HStack {
                    IconBadge(
                        systemName: batch.distributedAt == nil
                            ? "doc.text.magnifyingglass"
                            : "checkmark.seal.fill",
                        color: batch.distributedAt == nil
                            ? AppColors.purple
                            : AppColors.green
                    )
                    Spacer()
                    StatusPill(
                        title: batch.distributedAt == nil
                            ? "SIN DISTRIBUIR"
                            : "DISTRIBUIDO",
                        color: batch.distributedAt == nil
                            ? AppColors.purple
                            : AppColors.green
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(period(batch))
                        .font(AppTypography.cardTitle)
                    Text(batch.mode.displayName)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Divider()

                HStack {
                    Label(
                        batch.enforceSalesPeriod
                            ? "Fechas validadas"
                            : "Sin control estricto",
                        systemImage: batch.enforceSalesPeriod
                            ? "checkmark.shield"
                            : "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    Spacer()
                }

                HStack(spacing: AppSpacing.medium) {
                    Button {
                        intelligenceBatchID = batch.id
                    } label: {
                        Label("Análisis", systemImage: "waveform.path.ecg")
                    }
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button {
                        viewModel.select(batch)
                        Task {
                            await viewModel.downloadF8()
                            if viewModel.downloadedFileURL != nil {
                                showingFilePreview = true
                            }
                        }
                    } label: {
                        Label("F8", systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
        }
    }

    private var filteredBatches: [ExcelBatchDTO] {
        let completed = viewModel.batches.filter { $0.completedAt != nil }
        switch filter {
        case .all:
            return completed
        case .distributed:
            return completed.filter { $0.distributedAt != nil }
        case .pending:
            return completed.filter { $0.distributedAt == nil }
        }
    }

    private func period(_ batch: ExcelBatchDTO) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.locale = Locale(identifier: "es_AR")
        output.dateFormat = "d MMM yyyy"
        guard
            let start = input.date(from: batch.periodFrom),
            let end = input.date(from: batch.periodTo)
        else {
            return batch.periodLabel
        }
        return "\(output.string(from: start)) – \(output.string(from: end))"
    }
}
