import Charts
import SwiftUI

struct BatchIntelligenceSheet: View {
    let batchID: Int
    let isGlobal: Bool

    @StateObject private var viewModel = IntelligenceViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ResponsiveScrollView {
                IntelligenceDashboardSection(
                    viewModel: viewModel,
                    isGlobal: isGlobal
                )
            }
            .navigationTitle("Análisis del período")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task { await viewModel.load(batchID: batchID) }
        }
    }
}

struct IntelligenceDashboardSection: View {
    @ObservedObject var viewModel: IntelligenceViewModel
    let isGlobal: Bool

    @State private var selectedAlert: ProductAlertDTO?
    @State private var showsAllAlerts = false
    @State private var showsAllBranches = false
    @State private var selectedBranch: BranchHealthDTO?
    @State private var selectedProductMetric: ProductMetricFilter?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(isGlobal ? "Salud de la empresa" : "Salud de tu sucursal")
                        .font(AppTypography.sectionTitle)
                    if let batch = viewModel.dashboard?.batch {
                        Text("Último análisis · \(period(batch))")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                Spacer()
                if let dashboard = viewModel.dashboard,
                   dashboard.batch != nil {
                    StatusPill(
                        title: healthLabel(dashboard.metrics.healthStatus),
                        color: healthColor(dashboard.metrics.healthStatus)
                    )
                }
            }

            content
        }
        .sheet(item: $selectedAlert) { alert in
            ProductAlertDetailView(alert: alert)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showsAllAlerts) {
            if let alerts = viewModel.dashboard?.alerts {
                AlertListView(alerts: alerts, selectedAlert: $selectedAlert)
            }
        }
        .sheet(isPresented: $showsAllBranches) {
            if let branches = viewModel.dashboard?.branches {
                BranchHealthListView(
                    branches: branches,
                    selectedBranch: $selectedBranch
                )
            }
        }
        .sheet(item: $selectedBranch) { branch in
            BranchF8DetailView(
                branch: branch,
                products: viewModel.dashboard?.products.filter {
                    $0.branchCode == branch.branchCode
                } ?? [],
                alerts: viewModel.dashboard?.alerts.filter {
                    $0.branchCode == branch.branchCode
                } ?? [],
                selectedAlert: $selectedAlert
            )
        }
        .sheet(item: $selectedProductMetric) { filter in
            F8ProductListView(
                title: filter.title,
                products: products(for: filter),
                alerts: viewModel.dashboard?.alerts ?? [],
                selectedAlert: $selectedAlert
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.dashboard == nil {
            AppCard {
                ProgressView("Calculando indicadores…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.large)
            }
        } else if let message = viewModel.errorMessage,
                  viewModel.dashboard == nil {
            AppCard {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.red)
            }
        } else if let dashboard = viewModel.dashboard,
                  dashboard.batch != nil {
            healthOverview(dashboard)
            metricsGrid(dashboard.metrics)
            if dashboard.trend.count > 1 {
                trendCard(dashboard.trend)
            }
            if isGlobal && !dashboard.branches.isEmpty {
                branchSection(dashboard.branches)
            }
            alertsSection(dashboard.alerts)
        } else {
            AppCard {
                ContentUnavailableView(
                    "Todavía no hay un F8 analizado",
                    systemImage: "waveform.path.ecg",
                    description: Text(
                        isGlobal
                            ? "La salud, las alertas y las tendencias aparecerán al generar el primer análisis."
                            : "Tu información aparecerá cuando un administrador distribuya el primer F8."
                    )
                )
            }
        }
    }

    private func healthOverview(_ dashboard: IntelligenceDashboardDTO) -> some View {
        let metrics = dashboard.metrics
        let color = healthColor(metrics.healthStatus)
        return AppCard(padding: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [color.opacity(0.92), color.opacity(0.64)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 170, height: 170)
                    .offset(x: 230, y: -60)

                HStack(alignment: .center, spacing: AppSpacing.large) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.22), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: CGFloat(metrics.healthScore) / 100)
                            .stroke(
                                .white,
                                style: StrokeStyle(
                                    lineWidth: 10,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                        Text("\(metrics.healthScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 104, height: 104)

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Índice de reposición")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(healthExplanation(metrics))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.84))
                            .fixedSize(horizontal: false, vertical: true)
                        if let delta = dashboard.trendDelta {
                            Label(
                                trendText(delta),
                                systemImage: trendIcon(delta)
                            )
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        }
                    }
                }
                .padding(AppSpacing.large)
            }
            .frame(minHeight: 180)
            .clipped()
        }
    }

    private func metricsGrid(_ metrics: IntelligenceMetricsDTO) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 145), spacing: 12)],
            spacing: 12
        ) {
            intelligenceMetric(
                "Sin resolver",
                value: "\(metrics.unresolvedUnits)",
                icon: "exclamationmark.triangle.fill",
                color: metrics.unresolvedUnits > 0 ? AppColors.red : AppColors.green,
                action: { selectedProductMetric = .unresolved }
            )
            intelligenceMetric(
                "Asignadas",
                value: "\(metrics.allocatedUnits)",
                icon: "arrow.left.arrow.right",
                color: AppColors.blue,
                action: { selectedProductMetric = .allocated }
            )
            intelligenceMetric(
                "Reposición parcial",
                value: "\(metrics.partialProducts)",
                icon: "circle.lefthalf.filled",
                color: AppColors.orange,
                action: { selectedProductMetric = .partial }
            )
            intelligenceMetric(
                "Conflictos outlet",
                value: "\(metrics.outletConflicts)",
                icon: "tag.slash.fill",
                color: AppColors.purple,
                action: { selectedProductMetric = .outlet }
            )
        }
    }

    private func intelligenceMetric(
        _ title: String,
        value: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AppCard {
                HStack(spacing: AppSpacing.medium) {
                    IconBadge(systemName: icon, color: color, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value)
                            .font(.title2.bold())
                            .foregroundStyle(AppColors.primaryText)
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.tertiaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func products(for filter: ProductMetricFilter) -> [F8ProductDTO] {
        guard let dashboard = viewModel.dashboard else { return [] }
        switch filter {
        case .unresolved:
            return dashboard.products.filter { $0.residualQuantity > 0 }
        case .allocated:
            return dashboard.products.filter { $0.allocatedQuantity > 0 }
        case .partial:
            return dashboard.products.filter {
                $0.fulfillmentStatus == "PARTIAL"
            }
        case .outlet:
            let keys = Set(
                dashboard.alerts
                    .filter {
                        $0.reasonCode == "OUTLET_POLICY"
                            || $0.reasonCode == "OUTLET_IN_LINE_STORE"
                    }
                    .map { "\($0.branchCode)|\($0.sku)|\($0.size)" }
            )
            return dashboard.products.filter {
                keys.contains("\($0.branchCode)|\($0.sku)|\($0.size)")
            }
        }
    }

    private func trendCard(_ points: [IntelligenceTrendPointDTO]) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Evolución por período")
                    .font(AppTypography.cardTitle)
                Chart(points) { point in
                    AreaMark(
                        x: .value("Período", shortDate(point.periodTo)),
                        y: .value("Salud", point.healthScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.blue.opacity(0.24), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Período", shortDate(point.periodTo)),
                        y: .value("Salud", point.healthScore)
                    )
                    .foregroundStyle(AppColors.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    PointMark(
                        x: .value("Período", shortDate(point.periodTo)),
                        y: .value("Salud", point.healthScore)
                    )
                    .foregroundStyle(AppColors.blue)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100])
                }
                .frame(height: 180)
            }
        }
    }

    private func branchSection(_ branches: [BranchHealthDTO]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Sucursales que requieren atención")
                    .font(AppTypography.sectionTitle)
                Spacer()
                if branches.count > 5 {
                    Button("Ver todas") { showsAllBranches = true }
                        .font(.subheadline.weight(.semibold))
                }
            }
            ForEach(branches.prefix(5)) { branch in
                BranchHealthRow(branch: branch) {
                    selectedBranch = branch
                }
            }
        }
    }

    private func alertsSection(_ alerts: [ProductAlertDTO]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Productos sin resolver")
                    .font(AppTypography.sectionTitle)
                Spacer()
                if alerts.count > 5 {
                    Button("Ver todos") { showsAllAlerts = true }
                        .font(.subheadline.weight(.semibold))
                }
            }
            if alerts.isEmpty {
                AppCard {
                    Label(
                        "No quedaron productos con alertas en este período.",
                        systemImage: "checkmark.seal.fill"
                    )
                    .foregroundStyle(AppColors.green)
                }
            } else {
                ForEach(alerts.prefix(5)) { alert in
                    ProductAlertRow(alert: alert) {
                        selectedAlert = alert
                    }
                }
            }
        }
    }

    private func healthExplanation(_ metrics: IntelligenceMetricsDTO) -> String {
        if metrics.unresolvedUnits == 0 {
            return "El F8 puede cubrir todas las unidades detectadas."
        }
        return (
            "El F8 cubre \(metrics.allocatedUnits) de \(metrics.neededUnits) "
            + "unidades; quedan \(metrics.unresolvedUnits) por resolver."
        )
    }

    private func period(_ batch: IntelligenceBatchDTO) -> String {
        "\(shortDate(batch.periodFrom)) – \(shortDate(batch.periodTo))"
    }

    private func shortDate(_ value: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.locale = Locale(identifier: "es_AR")
        output.dateFormat = "d MMM"
        guard let date = input.date(from: value) else { return value }
        return output.string(from: date)
    }
}

private struct BranchHealthRow: View {
    let branch: BranchHealthDTO
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppCard {
            HStack(spacing: AppSpacing.medium) {
                ZStack {
                    Circle()
                        .stroke(healthColor(branch.healthStatus).opacity(0.18), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(branch.healthScore) / 100)
                        .stroke(
                            healthColor(branch.healthStatus),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(branch.healthScore)")
                        .font(.caption.bold())
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(branch.branchName)
                            .font(AppTypography.cardTitle)
                        if branch.isOutlet {
                            StatusPill(title: "OUTLET", color: AppColors.purple)
                        }
                    }
                    Text(
                        "\(branch.unresolvedUnits) unidades sin resolver · "
                        + "\(branch.needs) variantes"
                    )
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                }
                Spacer()
                if let delta = branch.trendDelta {
                    Label(
                        delta == 0 ? "0" : "\(delta > 0 ? "+" : "")\(delta)",
                        systemImage: trendIcon(delta)
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(delta >= 0 ? AppColors.green : AppColors.red)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel(trendText(delta))
                }
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
        }
        .buttonStyle(.plain)
    }
}

private struct ProductAlertRow: View {
    let alert: ProductAlertDTO
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppCard {
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    IconBadge(
                        systemName: alertIcon(alert),
                        color: severityColor(alert.severity),
                        size: 40
                    )
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(alert.description?.isEmpty == false
                                ? alert.description ?? alert.sku
                                : alert.sku)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2)
                            Spacer()
                            Text("T. \(alert.size)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        Text(alert.branchName)
                            .font(.caption)
                            .foregroundStyle(AppColors.blue)
                        Text(alert.reason)
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                            .lineLimit(2)
                        if alert.residualQuantity > 0 {
                            Text("Faltan \(alert.residualQuantity) de \(alert.neededQuantity) unidades")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(severityColor(alert.severity))
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProductAlertDetailView: View {
    let alert: ProductAlertDTO
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            StatusPill(
                                title: severityLabel(alert.severity),
                                color: severityColor(alert.severity)
                            )
                            Text(alert.description?.isEmpty == false
                                ? alert.description ?? alert.sku
                                : alert.sku)
                                .font(AppTypography.pageTitle)
                            Text("SKU \(alert.sku) · Talle \(alert.size) · \(alert.branchName)")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }

                    detailSection(
                        "Qué ocurrió",
                        icon: "exclamationmark.triangle.fill",
                        color: severityColor(alert.severity),
                        text: alert.reason
                    )
                    detailSection(
                        "Recomendación",
                        icon: "lightbulb.fill",
                        color: AppColors.blue,
                        text: alert.recommendation
                    )

                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            Text("Evidencia usada")
                                .font(AppTypography.cardTitle)
                            ForEach(alert.evidence, id: \.self) { item in
                                Label(item, systemImage: "checkmark.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                        }
                    }
                }
                .padding(AppSpacing.regular)
            }
            .background(AppColors.background)
            .navigationTitle("Detalle del producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func detailSection(
        _ title: String,
        icon: String,
        color: Color,
        text: String
    ) -> some View {
        AppCard {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                IconBadge(systemName: icon, color: color)
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(title).font(AppTypography.cardTitle)
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct AlertListView: View {
    let alerts: [ProductAlertDTO]
    @Binding var selectedAlert: ProductAlertDTO?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    ForEach(alerts) { alert in
                        ProductAlertRow(alert: alert) {
                            dismiss()
                            selectedAlert = alert
                        }
                    }
                }
                .padding(AppSpacing.regular)
            }
            .background(AppColors.background)
            .navigationTitle("Alertas de productos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

private struct BranchHealthListView: View {
    let branches: [BranchHealthDTO]
    @Binding var selectedBranch: BranchHealthDTO?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    ForEach(branches) { branch in
                        BranchHealthRow(branch: branch) {
                            dismiss()
                            selectedBranch = branch
                        }
                    }
                }
                .padding(AppSpacing.regular)
            }
            .background(AppColors.background)
            .navigationTitle("Salud por sucursal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

private struct BranchF8DetailView: View {
    let branch: BranchHealthDTO
    let products: [F8ProductDTO]
    let alerts: [ProductAlertDTO]
    @Binding var selectedAlert: ProductAlertDTO?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text(branch.branchName)
                                .font(AppTypography.pageTitle)
                            LabeledContent("Salud", value: "\(branch.healthScore)/100")
                            LabeledContent(
                                "Unidades sin resolver",
                                value: "\(branch.unresolvedUnits)"
                            )
                            LabeledContent("Variantes", value: "\(branch.needs)")
                        }
                    }
                    Text("Productos del F8")
                        .font(AppTypography.sectionTitle)
                    if products.isEmpty {
                        AppCard {
                            Label(
                                "La sucursal no tiene productos en este F8.",
                                systemImage: "checkmark.circle.fill"
                            )
                            .foregroundStyle(AppColors.green)
                        }
                    } else {
                        ForEach(products) { product in
                            AppCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(product.description ?? product.sku)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        StatusPill(
                                            title: product.fulfillmentStatus,
                                            color: product.residualQuantity == 0
                                                ? AppColors.green
                                                : AppColors.orange
                                        )
                                    }
                                    Text("SKU \(product.sku) · Talle \(product.size)")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondaryText)
                                    Text(
                                        "Necesita \(product.neededQuantity) · "
                                        + "asignado \(product.allocatedQuantity) · "
                                        + "faltan \(product.residualQuantity)"
                                    )
                                    .font(.caption.weight(.semibold))
                                    if !product.origins.isEmpty {
                                        Text("Origen: \(product.origins.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.secondaryText)
                                    }
                                    if let alert = alerts.first(where: {
                                        $0.sku == product.sku && $0.size == product.size
                                    }) {
                                        Button("Ver explicación y recomendación") {
                                            dismiss()
                                            selectedAlert = alert
                                        }
                                        .font(.caption.weight(.semibold))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.regular)
            }
            .background(AppColors.background)
            .navigationTitle("Detalle de sucursal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

private enum ProductMetricFilter: String, Identifiable {
    case unresolved
    case allocated
    case partial
    case outlet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unresolved: return "Productos sin resolver"
        case .allocated: return "Productos asignados"
        case .partial: return "Reposiciones parciales"
        case .outlet: return "Conflictos outlet"
        }
    }
}

private struct F8ProductListView: View {
    let title: String
    let products: [F8ProductDTO]
    let alerts: [ProductAlertDTO]
    @Binding var selectedAlert: ProductAlertDTO?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    if products.isEmpty {
                        ContentUnavailableView(
                            "No hay productos",
                            systemImage: "checkmark.circle",
                            description: Text(
                                "Este indicador no tiene productos en el F8 actual."
                            )
                        )
                    } else {
                        ForEach(products) { product in
                            AppCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(product.description ?? product.sku)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("T. \(product.size)")
                                            .font(.caption.weight(.semibold))
                                    }
                                    Text(product.branchName)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.blue)
                                    Text(
                                        "SKU \(product.sku) · necesita "
                                        + "\(product.neededQuantity) · asignado "
                                        + "\(product.allocatedQuantity) · faltan "
                                        + "\(product.residualQuantity)"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(AppColors.secondaryText)
                                    if let alert = alert(for: product) {
                                        Button("Ver motivo y recomendación") {
                                            dismiss()
                                            selectedAlert = alert
                                        }
                                        .font(.caption.weight(.semibold))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.regular)
            }
            .background(AppColors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func alert(for product: F8ProductDTO) -> ProductAlertDTO? {
        alerts.first {
            $0.branchCode == product.branchCode
                && $0.sku == product.sku
                && $0.size == product.size
        }
    }
}

private func healthColor(_ status: String) -> Color {
    switch status {
    case "HEALTHY": return AppColors.green
    case "ATTENTION": return AppColors.orange
    case "CRITICAL": return AppColors.red
    default: return AppColors.blue
    }
}

private func healthLabel(_ status: String) -> String {
    switch status {
    case "HEALTHY": return "SALUDABLE"
    case "ATTENTION": return "ATENCIÓN"
    case "CRITICAL": return "CRÍTICA"
    default: return "SIN DATOS"
    }
}

private func severityColor(_ severity: String) -> Color {
    switch severity {
    case "CRITICAL": return AppColors.red
    case "WARNING": return AppColors.orange
    default: return AppColors.blue
    }
}

private func severityLabel(_ severity: String) -> String {
    switch severity {
    case "CRITICAL": return "CRÍTICA"
    case "WARNING": return "REQUIERE ATENCIÓN"
    default: return "INFORMATIVA"
    }
}

private func alertIcon(_ alert: ProductAlertDTO) -> String {
    alert.reasonCode == "OUTLET_POLICY"
        || alert.reasonCode == "OUTLET_IN_LINE_STORE"
        ? "tag.slash.fill"
        : "exclamationmark.triangle.fill"
}

private func trendIcon(_ delta: Int) -> String {
    if delta > 0 { return "arrow.up.right" }
    if delta < 0 { return "arrow.down.right" }
    return "arrow.right"
}

private func trendText(_ delta: Int) -> String {
    if delta > 0 { return "Mejoró \(delta) puntos vs. el período anterior" }
    if delta < 0 { return "Bajó \(abs(delta)) puntos vs. el período anterior" }
    return "Sin cambios vs. el período anterior"
}
