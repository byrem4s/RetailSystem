import SwiftUI

struct ReplenishmentView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = ExcelBatchViewModel()

    @State private var branchCatalog: [BranchV2DTO] = []
    @State private var showingSalesPicker = false
    @State private var showingStockPicker = false
    @State private var showingDistributionConfirmation = false
    @State private var showingFilePreview = false
    @State private var showsAdminOverride = false

    private let branchService = UserManagementService()

    private var canManage: Bool {
        session.user?.role == .systemOwner
            || session.user?.role == .companyAdmin
    }

    private var ownBranchCode: String? {
        guard let branchID = session.user?.branchID else { return nil }
        return branchCatalog.first { $0.id == branchID }?.code
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ResponsiveScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        PageHeading(
                            eyebrow: canManage ? "Centro de control" : "Mi sucursal",
                            title: canManage
                                ? "Reposición"
                                : "Estadísticas solicitadas",
                            subtitle: canManage
                                ? (
                                    "Abrí un período, reuní ventas y stock, "
                                    + "revisá el F8 y decidí cuándo distribuirlo."
                                )
                                : (
                                    "Cargá acá el Excel de ventas de tu sucursal. "
                                    + "No necesitás enviar archivos por otro medio."
                                )
                        )

                        if let notice = viewModel.noticeMessage {
                            noticeBanner(notice)
                        }

                        if canManage {
                            createPeriodCard
                        }

                        periodsSection

                        if let batch = viewModel.selectedBatch {
                            selectedPeriod(batch)
                                .id(batch.id)
                        }
                    }
                }

                if viewModel.isBusy {
                    busyOverlay
                }
            }
            .navigationTitle("Reposición")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isBusy)
                    .accessibilityLabel("Actualizar")
                }
            }
            .task { await load() }
            .refreshable { await load() }
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
                    Task { await viewModel.uploadStock(url: url) }
                }
            }
            .sheet(isPresented: $showingFilePreview) {
                if let url = viewModel.downloadedFileURL {
                    FilePreview(url: url)
                        .ignoresSafeArea()
                }
            }
            .confirmationDialog(
                "¿Distribuir este F8?",
                isPresented: $showingDistributionConfirmation,
                titleVisibility: .visible
            ) {
                Button("Distribuir a las sucursales") {
                    Task { await viewModel.distribute() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text(
                    "Se crearán los movimientos y cada encargado verá "
                    + "únicamente lo que su sucursal debe preparar o recibir."
                )
            }
            .alert(
                "No se pudo completar",
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

    private var createPeriodCard: some View {
        AppCard(padding: AppSpacing.large) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    IconBadge(systemName: "calendar.badge.plus")
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text("Abrir un nuevo período")
                            .font(AppTypography.sectionTitle)
                        Text(
                            "Elegí cómo llegarán las ventas. El análisis y el "
                            + "F8 son iguales en ambos modos."
                        )
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                    }
                }

                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 240), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    modeOption(
                        mode: .distributed,
                        icon: "building.2",
                        title: "Por sucursal",
                        detail: (
                            "Cada sucursal carga su propio Excel de ventas. "
                            + "Después cargás el stock general y generás un F8."
                        )
                    )
                    modeOption(
                        mode: .centralized,
                        icon: "doc.on.doc",
                        title: "Consolidado",
                        detail: (
                            "Cargás un Excel con todas las ventas y otro con "
                            + "el stock general. El resultado es el mismo F8."
                        )
                    )
                }

                VStack(spacing: AppSpacing.medium) {
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
                }
                .font(.subheadline.weight(.medium))

                Toggle(
                    "Exigir que el Excel coincida con estas fechas",
                    isOn: $viewModel.enforceSalesPeriod
                )
                .font(.subheadline.weight(.semibold))
                .tint(AppColors.blue)

                if viewModel.enforceSalesPeriod {
                    Label(
                        "El archivo deberá incluir PERIODO_DESDE y "
                        + "PERIODO_HASTA. Se rechazará antes de cargar si "
                        + "alguna fila está fuera del período.",
                        systemImage: "checkmark.shield"
                    )
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                }

                Button {
                    Task { await viewModel.createBatch() }
                } label: {
                    Label("Abrir período", systemImage: "plus")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(
                    viewModel.isBusy
                        || viewModel.periodTo < viewModel.periodFrom
                )
            }
        }
    }

    private func modeOption(
        mode: ExcelBatchMode,
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                viewModel.mode = mode
            }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                IconBadge(
                    systemName: icon,
                    color: viewModel.mode == mode
                        ? AppColors.blue
                        : AppColors.secondaryText
                )
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Image(
                            systemName: viewModel.mode == mode
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundStyle(
                            viewModel.mode == mode
                                ? AppColors.blue
                                : AppColors.tertiaryText
                        )
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppSpacing.regular)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .background(
                viewModel.mode == mode
                    ? AppColors.selection
                    : AppColors.field
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppSpacing.controlRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppSpacing.controlRadius,
                    style: .continuous
                )
                .stroke(
                    viewModel.mode == mode
                        ? AppColors.blue.opacity(0.55)
                        : AppColors.subtleBorder,
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var periodsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text(canManage ? "Períodos" : "Solicitudes")
                    .font(AppTypography.sectionTitle)
                Spacer()
                Text("\(viewModel.batches.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.secondaryText)
            }

            if viewModel.batches.isEmpty {
                AppCard {
                    ContentUnavailableView(
                        canManage ? "Sin períodos" : "Sin solicitudes",
                        systemImage: "tray",
                        description: Text(
                            canManage
                                ? "Abrí el primer período para comenzar."
                                : "No hay estadísticas pendientes para tu sucursal."
                        )
                    )
                }
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 255), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(viewModel.batches) { batch in
                        periodButton(batch)
                    }
                }
            }
        }
    }

    private func periodButton(_ batch: ExcelBatchDTO) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                viewModel.select(batch)
            }
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack {
                    IconBadge(
                        systemName: batch.mode == .distributed
                            ? "building.2"
                            : "doc.on.doc",
                        color: color(for: batch)
                    )
                    Spacer()
                    StatusPill(
                        title: statusLabel(batch),
                        color: color(for: batch)
                    )
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(formattedPeriod(batch))
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.primaryText)
                    Text(batch.mode.displayName)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .padding(AppSpacing.regular)
            .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
            .background(
                viewModel.selectedBatchID == batch.id
                    ? AppColors.selection
                    : AppColors.card
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppSpacing.cardRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppSpacing.cardRadius,
                    style: .continuous
                )
                .stroke(
                    viewModel.selectedBatchID == batch.id
                        ? AppColors.blue.opacity(0.5)
                        : AppColors.subtleBorder,
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func selectedPeriod(_ batch: ExcelBatchDTO) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text(canManage ? "Circuito del período" : "Tu carga")
                    .font(AppTypography.sectionTitle)
                Spacer()
                StatusPill(
                    title: statusLabel(batch),
                    color: color(for: batch)
                )
            }

            AppCard(padding: AppSpacing.large) {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(formattedPeriod(batch))
                                .font(.title3.weight(.bold))
                            Text(batch.mode.displayName)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        Spacer()
                        if batch.enforceSalesPeriod {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(AppColors.green)
                                .accessibilityLabel("Período validado")
                        }
                    }

                    if canManage {
                        managerWorkflow(batch)
                    } else {
                        branchWorkflow(batch)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func managerWorkflow(_ batch: ExcelBatchDTO) -> some View {
        Divider()

        VStack(spacing: AppSpacing.regular) {
            workflowRow(
                number: 1,
                title: batch.mode == .distributed
                    ? "Ventas por sucursal"
                    : "Ventas consolidadas",
                detail: salesProgress(batch),
                complete: salesComplete(batch)
            )
            workflowRow(
                number: 2,
                title: "Stock de la empresa",
                detail: batch.hasStockSnapshot ? "Validado" : "Pendiente",
                complete: batch.hasStockSnapshot
            )
            workflowRow(
                number: 3,
                title: "Generar y revisar F8",
                detail: batch.completedAt == nil ? "Pendiente" : "Disponible",
                complete: batch.completedAt != nil
            )
            workflowRow(
                number: 4,
                title: "Distribuir tareas",
                detail: batch.distributedAt == nil
                    ? "Pendiente de tu decisión"
                    : "Distribuido",
                complete: batch.distributedAt != nil
            )
        }

        if batch.mode == .centralized && batch.distributedAt == nil {
            fileAction(
                title: hasCentralSales(batch)
                    ? "Reemplazar ventas consolidadas"
                    : "Cargar ventas consolidadas",
                icon: "arrow.up.doc",
                color: AppColors.blue
            ) {
                showingSalesPicker = true
            }
        }

        if batch.mode == .distributed && batch.distributedAt == nil {
            DisclosureGroup(
                isExpanded: $showsAdminOverride,
                content: {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text(
                            "Usalo sólo si una sucursal no puede cargar su "
                            + "archivo. La carga quedará registrada."
                        )
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)

                        if !branchOptions(batch).isEmpty {
                            Picker(
                                "Sucursal",
                                selection: $viewModel.selectedBranchCode
                            ) {
                                ForEach(branchOptions(batch), id: \.self) {
                                    Text($0).tag(String?.some($0))
                                }
                            }
                            .pickerStyle(.menu)

                            fileAction(
                                title: "Cargar por la sucursal",
                                icon: "person.badge.key",
                                color: AppColors.purple
                            ) {
                                showingSalesPicker = true
                            }
                        }
                    }
                    .padding(.top, AppSpacing.medium)
                },
                label: {
                    Label(
                        "Carga asistida por administrador",
                        systemImage: "wrench.and.screwdriver"
                    )
                    .font(.subheadline.weight(.semibold))
                }
            )
            .tint(AppColors.blue)
        }

        if batch.distributedAt == nil {
            fileAction(
                title: batch.hasStockSnapshot
                    ? "Reemplazar stock general"
                    : "Cargar stock general",
                icon: "shippingbox",
                color: AppColors.orange
            ) {
                showingStockPicker = true
            }
        }

        if batch.status == "READY" {
            Button {
                Task { await viewModel.analyze() }
            } label: {
                Label("Generar análisis y F8", systemImage: "sparkles")
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }

        if batch.completedAt != nil {
            HStack(spacing: AppSpacing.medium) {
                Button {
                    Task {
                        await viewModel.downloadF8()
                        if viewModel.downloadedFileURL != nil {
                            showingFilePreview = true
                        }
                    }
                } label: {
                    Label("Ver F8", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(SecondaryActionButtonStyle())

                if batch.distributedAt == nil {
                    Button {
                        showingDistributionConfirmation = true
                    } label: {
                        Label("Distribuir", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
            }
        }

        downloadedFileAction

        templatesMenu(canManage: true, mode: batch.mode)

        if let summary = batch.errorSummary,
           batch.status != "COMPLETED" {
            Label(summary, systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    @ViewBuilder
    private func branchWorkflow(_ batch: ExcelBatchDTO) -> some View {
        let uploaded = ownBranchCode.map {
            batch.uploadedBranchCodes.contains($0)
        } ?? false

        Divider()

        HStack(alignment: .top, spacing: AppSpacing.medium) {
            IconBadge(
                systemName: uploaded
                    ? "checkmark.circle.fill"
                    : "arrow.up.doc",
                color: uploaded ? AppColors.green : AppColors.blue
            )
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(
                    uploaded
                        ? "Archivo recibido"
                        : "Excel de ventas pendiente"
                )
                .font(AppTypography.cardTitle)
                Text(
                    uploaded
                        ? (
                            "Tu estadística fue validada. Podés reemplazarla "
                            + "mientras el F8 no haya sido distribuido."
                        )
                        : (
                            "Seleccioná el archivo de tu sucursal. Se validará "
                            + "antes de enviarlo al administrador."
                        )
                )
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
        }

        if batch.enforceSalesPeriod {
            Label(
                "Período exigido: \(formattedPeriod(batch)).",
                systemImage: "calendar.badge.checkmark"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColors.orange)
        }

        if batch.distributedAt == nil {
            Button {
                showingSalesPicker = true
            } label: {
                Label(
                    uploaded ? "Reemplazar archivo" : "Elegir Excel de ventas",
                    systemImage: "arrow.up.doc"
                )
            }
            .buttonStyle(PrimaryActionButtonStyle())
        } else {
            Label(
                "Este período ya fue distribuido y quedó cerrado.",
                systemImage: "lock.fill"
            )
            .font(.subheadline)
            .foregroundStyle(AppColors.secondaryText)
        }

        templatesMenu(canManage: false, mode: batch.mode)
        downloadedFileAction
    }

    private func workflowRow(
        number: Int,
        title: String,
        detail: String,
        complete: Bool
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(complete ? .white : AppColors.secondaryText)
                .frame(width: 28, height: 28)
                .background(
                    complete
                        ? AppColors.green
                        : AppColors.elevated
                )
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            Spacer()
            Image(
                systemName: complete
                    ? "checkmark.circle.fill"
                    : "circle.dotted"
            )
            .foregroundStyle(
                complete ? AppColors.green : AppColors.tertiaryText
            )
        }
    }

    private func fileAction(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 46)
                .background(color.opacity(0.10))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppSpacing.controlRadius,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private func templatesMenu(
        canManage: Bool,
        mode: ExcelBatchMode
    ) -> some View {
        Menu {
            if mode == .distributed || !canManage {
                Button {
                    Task { await viewModel.downloadTemplate(.branchSales) }
                } label: {
                    Label("Ventas por sucursal", systemImage: "building.2")
                }
            }
            if canManage && mode == .centralized {
                Button {
                    Task {
                        await viewModel.downloadTemplate(.centralizedSales)
                    }
                } label: {
                    Label("Ventas consolidadas", systemImage: "doc.on.doc")
                }
            }
            if canManage {
                Button {
                    Task { await viewModel.downloadTemplate(.stock) }
                } label: {
                    Label("Stock general", systemImage: "shippingbox")
                }
            }
        } label: {
            Label("Descargar plantilla", systemImage: "arrow.down.doc")
                .font(.subheadline.weight(.semibold))
        }
    }

    @ViewBuilder
    private var downloadedFileAction: some View {
        if let fileURL = viewModel.downloadedFileURL {
            ShareLink(item: fileURL) {
                Label(
                    viewModel.downloadedFileLabel ?? "Compartir archivo",
                    systemImage: "square.and.arrow.up"
                )
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func noticeBanner(_ message: String) -> some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppColors.green)
            .padding(AppSpacing.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.green.opacity(0.10))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppSpacing.controlRadius,
                    style: .continuous
                )
            )
    }

    private var busyOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
            ProgressView("Procesando archivo…")
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

    private func salesProgress(_ batch: ExcelBatchDTO) -> String {
        if batch.mode == .centralized {
            return hasCentralSales(batch) ? "Validado" : "Pendiente"
        }
        return (
            "\(batch.uploadedBranchCodes.count) de "
            + "\(batch.expectedBranchCodes.count) recibidas"
        )
    }

    private func salesComplete(_ batch: ExcelBatchDTO) -> Bool {
        batch.mode == .centralized
            ? hasCentralSales(batch)
            : batch.missingBranchCodes.isEmpty
    }

    private func hasCentralSales(_ batch: ExcelBatchDTO) -> Bool {
        batch.uploads.contains { $0.scopeKey == "SALES:ALL" }
    }

    private func branchOptions(_ batch: ExcelBatchDTO) -> [String] {
        batch.missingBranchCodes.isEmpty
            ? batch.expectedBranchCodes
            : batch.missingBranchCodes
    }

    private func statusLabel(_ batch: ExcelBatchDTO) -> String {
        if batch.distributedAt != nil { return "DISTRIBUIDO" }
        switch batch.status {
        case "DRAFT": return "EN CARGA"
        case "READY": return "LISTO"
        case "PROCESSING": return "PROCESANDO"
        case "COMPLETED": return "PARA REVISAR"
        case "FAILED": return "ERROR"
        default: return batch.status
        }
    }

    private func color(for batch: ExcelBatchDTO) -> Color {
        if batch.distributedAt != nil { return AppColors.green }
        switch batch.status {
        case "READY": return AppColors.blue
        case "COMPLETED": return AppColors.purple
        case "FAILED": return AppColors.red
        case "PROCESSING": return AppColors.blue
        default: return AppColors.orange
        }
    }

    private func formattedPeriod(_ batch: ExcelBatchDTO) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.locale = Locale(identifier: "es_AR")
        output.dateFormat = "d MMM"
        guard
            let from = input.date(from: batch.periodFrom),
            let to = input.date(from: batch.periodTo)
        else {
            return batch.periodLabel
        }
        return "\(output.string(from: from)) – \(output.string(from: to))"
    }

    private func load() async {
        await viewModel.load()
        if let values = try? await branchService.fetchBranches() {
            branchCatalog = values
        }
    }
}
