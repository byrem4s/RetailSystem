import SwiftUI

struct ReplenishmentView: View {

    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = ExcelBatchViewModel()
    @State private var showingSalesPicker = false
    @State private var showingStockPicker = false

    private var canManage: Bool {
        session.user?.role == .systemOwner
        || session.user?.role == .companyAdmin
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        introduction
                        if canManage {
                            createBatchCard
                        }
                        batchList
                        if let batch = viewModel.selectedBatch {
                            batchDetail(batch)
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 110)
                }

                if viewModel.isBusy {
                    Color.black.opacity(0.20)
                        .ignoresSafeArea()
                    ProgressView("Procesando…")
                        .padding(22)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .background(AppColors.background)
            .navigationTitle("Reposición")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isBusy)
                }
            }
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $showingSalesPicker) {
                DocumentPicker { url in
                    showingSalesPicker = false
                    Task {
                        await viewModel.uploadSales(
                            url: url,
                            role: session.user?.role
                        )
                    }
                }
            }
            .sheet(isPresented: $showingStockPicker) {
                DocumentPicker { url in
                    showingStockPicker = false
                    Task {
                        await viewModel.uploadStock(url: url)
                    }
                }
            }
            .alert(
                "No se pudo completar",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: {
                        if !$0 {
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reposición por Excel")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.primaryText)
            Text(
                canManage
                ? "Creá el período, reuní las ventas y el stock, y generá el F8."
                : "Cargá las ventas de tu sucursal en el lote abierto."
            )
            .font(.system(size: 14))
            .foregroundColor(AppColors.secondaryText)

            if let notice = viewModel.noticeMessage {
                Label(notice, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.green)
                    .padding(.top, 6)
            }
        }
    }

    private var createBatchCard: some View {
        RoundedContainer {
            VStack(alignment: .leading, spacing: 14) {
                Label("Nuevo período", systemImage: "calendar.badge.plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Picker("Modo", selection: $viewModel.mode) {
                    ForEach(ExcelBatchMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                DatePicker(
                    "Desde",
                    selection: $viewModel.periodFrom,
                    displayedComponents: .date
                )
                DatePicker(
                    "Hasta",
                    selection: $viewModel.periodTo,
                    in: viewModel.periodFrom...,
                    displayedComponents: .date
                )

                Text(
                    viewModel.mode == .distributed
                    ? (
                        "Se esperará una venta por cada sucursal activa. "
                        + "Cada encargado verá solamente este lote."
                    )
                    : (
                        "El administrador cargará un único archivo de ventas "
                        + "con todas las sucursales."
                    )
                )
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)

                Button {
                    Task { await viewModel.createBatch() }
                } label: {
                    Label("Crear lote", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AppColors.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(
                    viewModel.isBusy
                    || viewModel.periodTo < viewModel.periodFrom
                )
            }
            .padding()
        }
    }

    private var batchList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Períodos")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            if viewModel.batches.isEmpty {
                RoundedContainer {
                    Text("No hay lotes disponibles.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            } else {
                ForEach(viewModel.batches) { batch in
                    Button {
                        viewModel.select(batch)
                    } label: {
                        HStack(spacing: 12) {
                            Image(
                                systemName: batch.mode == .distributed
                                ? "building.2.crop.circle"
                                : "doc.on.doc"
                            )
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(batch.periodLabel)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                Text(batch.mode.displayName)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.secondaryText)
                            }

                            Spacer()
                            statusBadge(batch.status)
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(14)
                        .background(
                            viewModel.selectedBatchID == batch.id
                            ? AppColors.blue.opacity(0.10)
                            : AppColors.card
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func batchDetail(_ batch: ExcelBatchDTO) -> some View {
        RoundedContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Lote seleccionado")
                            .font(.system(size: 18, weight: .bold))
                        Text(batch.periodLabel)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    Spacer()
                    statusBadge(batch.status)
                }

                Divider()

                Menu {
                    Button {
                        Task {
                            await viewModel.downloadTemplate(.branchSales)
                        }
                    } label: {
                        Label(
                            "Ventas por sucursal",
                            systemImage: "building.2"
                        )
                    }
                    if canManage {
                        Button {
                            Task {
                                await viewModel.downloadTemplate(
                                    .centralizedSales
                                )
                            }
                        } label: {
                            Label(
                                "Ventas consolidadas",
                                systemImage: "doc.on.doc"
                            )
                        }
                        Button {
                            Task {
                                await viewModel.downloadTemplate(.stock)
                            }
                        } label: {
                            Label(
                                "Stock de la empresa",
                                systemImage: "shippingbox"
                            )
                        }
                    }
                } label: {
                    actionLabel(
                        "Descargar plantilla",
                        icon: "arrow.down.doc",
                        color: AppColors.blue
                    )
                }

                if batch.mode == .distributed {
                    progressRow(
                        title: "Ventas recibidas",
                        value: (
                            "\(batch.uploadedBranchCodes.count)"
                            + "/\(batch.expectedBranchCodes.count)"
                        ),
                        complete: batch.missingBranchCodes.isEmpty
                    )
                    if !batch.missingBranchCodes.isEmpty {
                        Text(
                            "Faltan: "
                            + batch.missingBranchCodes.joined(separator: ", ")
                        )
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                    }
                } else {
                    progressRow(
                        title: "Ventas consolidadas",
                        value: hasCentralSales(batch) ? "Cargadas" : "Pendientes",
                        complete: hasCentralSales(batch)
                    )
                }

                progressRow(
                    title: "Foto de stock",
                    value: batch.hasStockSnapshot ? "Cargada" : "Pendiente",
                    complete: batch.hasStockSnapshot
                )

                if canManage && batch.mode == .distributed {
                    Picker(
                        "Sucursal a cargar",
                        selection: $viewModel.selectedBranchCode
                    ) {
                        ForEach(branchOptions(batch), id: \.self) { code in
                            Text(code).tag(String?.some(code))
                        }
                    }
                }

                Button {
                    showingSalesPicker = true
                } label: {
                    actionLabel(
                        "Cargar ventas",
                        icon: "arrow.up.doc",
                        color: AppColors.blue
                    )
                }
                .disabled(
                    viewModel.isBusy
                    || (
                        canManage
                        && batch.mode == .distributed
                        && viewModel.selectedBranchCode == nil
                    )
                )

                if canManage {
                    Button {
                        showingStockPicker = true
                    } label: {
                        actionLabel(
                            "Cargar stock consolidado",
                            icon: "shippingbox",
                            color: AppColors.orange
                        )
                    }

                    Button {
                        Task { await viewModel.analyze() }
                    } label: {
                        actionLabel(
                            "Generar análisis y F8",
                            icon: "sparkles",
                            color: AppColors.green
                        )
                    }
                    .disabled(batch.status != "READY")

                    if batch.status == "COMPLETED" {
                        Button {
                            Task { await viewModel.downloadF8() }
                        } label: {
                            actionLabel(
                                "Descargar F8",
                                icon: "arrow.down.doc",
                                color: AppColors.blue
                            )
                        }
                    }
                }

                if let fileURL = viewModel.downloadedFileURL {
                    ShareLink(item: fileURL) {
                        Label(
                            viewModel.downloadedFileLabel
                                ?? "Compartir archivo",
                            systemImage: "square.and.arrow.up"
                        )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.blue)
                    }
                }

                if let summary = batch.errorSummary,
                   batch.status != "COMPLETED" {
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .foregroundColor(AppColors.primaryText)
            .padding()
        }
    }

    private func progressRow(
        title: String,
        value: String,
        complete: Bool
    ) -> some View {
        HStack {
            Image(systemName: complete ? "checkmark.circle.fill" : "clock")
                .foregroundColor(complete ? AppColors.green : AppColors.orange)
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)
        }
    }

    private func actionLabel(
        _ title: String,
        icon: String,
        color: Color
    ) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 43)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private func statusBadge(_ status: String) -> some View {
        Text(statusLabel(status))
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(statusColor(status))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(statusColor(status).opacity(0.12))
            .clipShape(Capsule())
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "DRAFT": return "EN CARGA"
        case "READY": return "LISTO"
        case "PROCESSING": return "PROCESANDO"
        case "COMPLETED": return "COMPLETADO"
        case "FAILED": return "ERROR"
        default: return status
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "READY", "COMPLETED":
            return AppColors.green
        case "FAILED":
            return AppColors.red
        case "PROCESSING":
            return AppColors.blue
        default:
            return AppColors.orange
        }
    }

    private func hasCentralSales(_ batch: ExcelBatchDTO) -> Bool {
        batch.uploads.contains { $0.scopeKey == "SALES:ALL" }
    }

    private func branchOptions(_ batch: ExcelBatchDTO) -> [String] {
        batch.missingBranchCodes.isEmpty
            ? batch.expectedBranchCodes
            : batch.missingBranchCodes
    }
}
