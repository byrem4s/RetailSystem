import SwiftUI

struct AlertsView: View {

    @StateObject private var vm = AlertsViewModel()
    @State private var selectedFilter = "Todas"

    private let filters = [
        "Todas",
        "Críticas",
        "Altas",
        "Medias"
    ]

    private var filteredAlerts: [AlertDTO] {

        switch selectedFilter {

        case "Críticas":
            return vm.criticalAlerts

        case "Altas":
            return vm.highAlerts

        case "Medias":
            return vm.mediumAlerts

        default:
            return vm.alerts
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
                .padding(.bottom, 120)
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

        HStack {

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

            Spacer()

            Button {

            } label: {

                ZStack(alignment: .topTrailing) {

                    Circle()
                        .fill(Color.white)
                        .frame(width: 46, height: 46)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)

                    if vm.totalCount > 0 {

                        Text("\(vm.totalCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColors.red)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
            }
        }
    }

    private var summarySection: some View {

        HStack(spacing: 10) {

            summaryCard(
                title: "Críticas",
                value: "\(vm.criticalCount)",
                color: AppColors.red,
                icon: "exclamationmark.triangle.fill"
            )

            summaryCard(
                title: "Altas",
                value: "\(vm.highCount)",
                color: AppColors.orange,
                icon: "flame.fill"
            )

            summaryCard(
                title: "Medias",
                value: "\(vm.mediumCount)",
                color: AppColors.blue,
                icon: "clock.fill"
            )

            summaryCard(
                title: "Total",
                value: "\(vm.totalCount)",
                color: AppColors.green,
                icon: "checkmark.circle.fill"
            )
        }
    }

    private var filtersSection: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(spacing: 10) {

                ForEach(filters, id: \.self) { filter in

                    Button {

                        selectedFilter = filter

                    } label: {

                        Text(filter)
                            .font(
                                .system(
                                    size: 13,
                                    weight: .medium
                                )
                            )
                            .foregroundColor(
                                selectedFilter == filter
                                ? .white
                                : AppColors.primaryText
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedFilter == filter
                                ? AppColors.blue
                                : Color.white
                            )
                            .cornerRadius(14)
                    }
                }
            }
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

            } else if selectedFilter == "Todas" {

                alertGroup(
                    title: "Alertas críticas",
                    count: vm.criticalAlerts.count,
                    color: AppColors.red,
                    items: vm.criticalAlerts
                )

                alertGroup(
                    title: "Alertas altas",
                    count: vm.highAlerts.count,
                    color: AppColors.orange,
                    items: vm.highAlerts
                )

                alertGroup(
                    title: "Alertas medias",
                    count: vm.mediumAlerts.count,
                    color: AppColors.blue,
                    items: vm.mediumAlerts
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

        switch selectedFilter {

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

        switch selectedFilter {

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

    private func summaryCard(
        title: String,
        value: String,
        color: Color,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundColor(color)
            }

            Text(value)
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
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