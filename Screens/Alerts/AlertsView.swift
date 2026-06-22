import SwiftUI

struct AlertsView: View {

    @StateObject private var vm = AlertsViewModel()

    @State private var selectedTypeFilter = "Total"
    @State private var selectedBranchFilter = "Todas"

    private let typeFilters = [
        "Total",
        "Críticas",
        "Altas",
        "Medias"
    ]

    private var filteredAlerts: [AlertDTO] {

        vm.alerts.filter { item in

            matchesTypeFilter(item)
            && matchesBranchFilter(item)
        }
    }

    private var filteredCriticalAlerts: [AlertDTO] {

        filteredAlerts.filter {
            $0.priority.uppercased() == "CRITICAL"
        }
    }

    private var filteredHighAlerts: [AlertDTO] {

        filteredAlerts.filter {
            $0.priority.uppercased() == "HIGH"
        }
    }

    private var filteredMediumAlerts: [AlertDTO] {

        filteredAlerts.filter {
            $0.priority.uppercased() == "MEDIUM"
        }
    }

    var body: some View {

        ZStack {

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    headerSection

                    summarySection

                    filtersSection

                    alertsContentSection
                }
                .padding(.top, 28)
                .padding(18)
                .padding(.bottom, 105)
            }

            if vm.isLoading {

                Color.black.opacity(0.20)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.4)
            }
        }
        .background(AppColors.background)
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { _ in vm.errorMessage = nil }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task {
            await vm.loadAlerts()
        }
        .onReceive(AppState.shared.$refreshID) { _ in
            Task {
                await vm.loadAlerts()
            }
        }
    }

    private var headerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Alertas")
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )

            Text("Riesgos y oportunidades detectadas")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
        }
    }

    private var summarySection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Resumen de alertas")
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 12) {

                HStack(spacing: 12) {

                    alertSummaryCard(
                        title: "Críticas",
                        value: "\(vm.criticalCount)",
                        color: AppColors.red,
                        icon: "exclamationmark.triangle.fill"
                    )

                    alertSummaryCard(
                        title: "Altas",
                        value: "\(vm.highCount)",
                        color: AppColors.orange,
                        icon: "flame.fill"
                    )
                }

                HStack(spacing: 12) {

                    alertSummaryCard(
                        title: "Medias",
                        value: "\(vm.mediumCount)",
                        color: AppColors.blue,
                        icon: "clock.fill"
                    )

                    alertSummaryCard(
                        title: "Total",
                        value: "\(vm.totalCount)",
                        color: AppColors.green,
                        icon: "checkmark.circle.fill"
                    )
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(26)
        }
    }

    private func alertSummaryCard(
        title: String,
        value: String,
        color: Color,
        icon: String
    ) -> some View {

        HStack(spacing: 14) {

            ZStack {

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(value)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(20)
    }

    private var filtersSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Filtros")
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 12) {

                filterMenu(
                    title: "Tipo de alerta",
                    value: selectedTypeFilter,
                    options: typeFilters
                ) { selected in

                    selectedTypeFilter = selected
                }

                filterMenu(
                    title: "Sucursal",
                    value: selectedBranchFilter,
                    options: vm.branchOptions
                ) { selected in

                    selectedBranchFilter = selected
                }
            }
        }
    }

    private func filterMenu(
        title: String,
        value: String,
        options: [String],
        onSelect: @escaping (String) -> Void
    ) -> some View {

        Menu {

            ForEach(options, id: \.self) { option in

                Button {

                    onSelect(option)

                } label: {

                    HStack {

                        Text(option)

                        if option == value {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

        } label: {

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)

                HStack(spacing: 8) {

                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(18)
        }
    }

    private var alertsContentSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            if vm.alerts.isEmpty {

                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Sin alertas activas",
                    message: "No hay riesgos operativos detectados."
                )

            } else if filteredAlerts.isEmpty {

                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Sin resultados",
                    message: "No hay alertas para los filtros seleccionados."
                )

            } else if selectedTypeFilter == "Total" {

                alertGroup(
                    title: "Alertas críticas",
                    count: filteredCriticalAlerts.count,
                    color: AppColors.red,
                    items: filteredCriticalAlerts
                )

                alertGroup(
                    title: "Alertas altas",
                    count: filteredHighAlerts.count,
                    color: AppColors.orange,
                    items: filteredHighAlerts
                )

                alertGroup(
                    title: "Alertas medias",
                    count: filteredMediumAlerts.count,
                    color: AppColors.blue,
                    items: filteredMediumAlerts
                )

            } else {

                alertGroup(
                    title: sectionTitleForSelectedFilter,
                    count: filteredAlerts.count,
                    color: sectionColorForSelectedFilter,
                    items: filteredAlerts
                )
            }
        }
    }

    private var sectionTitleForSelectedFilter: String {

        switch selectedTypeFilter {

        case "Críticas":
            return "Alertas críticas"

        case "Altas":
            return "Alertas altas"

        case "Medias":
            return "Alertas medias"

        default:
            return "Alertas"
        }
    }

    private var sectionColorForSelectedFilter: Color {

        switch selectedTypeFilter {

        case "Críticas":
            return AppColors.red

        case "Altas":
            return AppColors.orange

        case "Medias":
            return AppColors.blue

        default:
            return AppColors.green
        }
    }

    private func alertGroup(
        title: String,
        count: Int,
        color: Color,
        items: [AlertDTO]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            sectionTitle(
                title: title,
                count: count,
                color: color
            )

            if items.isEmpty {

                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Sin \(title.lowercased())",
                    message: "No hay casos para esta categoría."
                )

            } else {

                VStack(spacing: 14) {

                    ForEach(items) { item in

                        alertCard(item)
                    }
                }
            }
        }
    }

    private func alertCard(
        _ item: AlertDTO
    ) -> some View {

        let color = priorityColor(item.priority)

        return VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(
                alignment: .top,
                spacing: 14
            ) {

                ZStack {

                    RoundedRectangle(cornerRadius: 18)
                        .fill(color.opacity(0.12))
                        .frame(width: 62, height: 62)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(item.type.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(color)

                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)

                    HStack(spacing: 6) {

                        Image(systemName: "building.2")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)

                        Text(item.branch)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }

                Spacer()

                VStack(
                    alignment: .trailing,
                    spacing: 8
                ) {

                    Text(item.createdAt)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)

                    Text(riskText(item))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.10))
                        .cornerRadius(12)
                }
            }

            Divider()

            HStack(spacing: 0) {

                metricBlock(
                    title: "Vendió",
                    value: "\(item.sold) u.",
                    subtitle: "en \(item.soldPeriodDays) días",
                    color: AppColors.primaryText
                )

                metricDivider

                metricBlock(
                    title: "Stock actual",
                    value: "\(item.stock) u.",
                    subtitle: nil,
                    color: color
                )

                metricDivider

                metricBlock(
                    title: "Velocidad",
                    value: "\(formatVelocity(item.averageVelocity)) u/día",
                    subtitle: nil,
                    color: AppColors.primaryText
                )

                metricDivider

                metricBlock(
                    title: "Necesidad",
                    value: "\(item.needed) u.",
                    subtitle: nil,
                    color: color
                )
            }

            Divider()

            Text(item.reason)
                .font(.system(size: 13))
                .foregroundColor(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {

                Button {

                } label: {

                    HStack(spacing: 8) {

                        Image(systemName: "eye")

                        Text("Ver detalle")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.18))
                    )
                    .cornerRadius(14)
                }

                Button {

                } label: {

                    HStack(spacing: 8) {

                        Text("Tomar acción")

                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(color)
                    .cornerRadius(14)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.10))
        )
    }

    private var metricDivider: some View {

        Rectangle()
            .fill(Color.gray.opacity(0.16))
            .frame(width: 1, height: 44)
    }

    private func metricBlock(
        title: String,
        value: String,
        subtitle: String?,
        color: Color
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(AppColors.secondaryText)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)

            if let subtitle {

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(
        title: String,
        count: Int,
        color: Color
    ) -> some View {

        HStack(spacing: 10) {

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(
                    .system(
                        size: 20,
                        weight: .bold
                    )
                )

            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(Capsule())
        }
    }

    private func matchesTypeFilter(
        _ item: AlertDTO
    ) -> Bool {

        let priority = item.priority.uppercased()

        switch selectedTypeFilter {

        case "Críticas":
            return priority == "CRITICAL"

        case "Altas":
            return priority == "HIGH"

        case "Medias":
            return priority == "MEDIUM"

        default:
            return true
        }
    }

    private func matchesBranchFilter(
        _ item: AlertDTO
    ) -> Bool {

        if selectedBranchFilter == "Todas" {
            return true
        }

        return item.branch == selectedBranchFilter
    }

    private func priorityColor(
        _ priority: String
    ) -> Color {

        let value = priority.uppercased()

        if value == "CRITICAL" {
            return AppColors.red
        }

        if value == "HIGH" {
            return AppColors.orange
        }

        return AppColors.blue
    }

    private func riskText(
        _ item: AlertDTO
    ) -> String {

        if item.riskDays > 0 {
            return "Riesgo: \(item.riskDays) días"
        }

        return priorityLabel(item.priority)
    }

    private func priorityLabel(
        _ priority: String
    ) -> String {

        let value = priority.uppercased()

        if value == "CRITICAL" {
            return "Crítico"
        }

        if value == "HIGH" {
            return "Alto"
        }

        if value == "MEDIUM" {
            return "Medio"
        }

        return priority
    }

    private func formatVelocity(
        _ value: Double
    ) -> String {

        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }

        return String(
            format: "%.1f",
            value
        )
    }
}

struct AlertsView_Previews: PreviewProvider {

    static var previews: some View {
        AlertsView()
    }
}