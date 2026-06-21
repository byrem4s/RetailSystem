import SwiftUI

struct ActivityView: View {

    @StateObject private var vm = ActivityViewModel()
    @State private var selectedFilter = "Todas"

    private let filters = [
        "Todas",
        "Movimientos",
        "Decisiones",
        "Alertas resueltas"
    ]

    private var filteredActivities: [ActivityDTO] {

        switch selectedFilter {

        case "Movimientos":
            return vm.movementActivities

        case "Decisiones":
            return vm.decisionActivities

        case "Alertas resueltas":
            return vm.resolvedActivities

        default:
            return vm.activities
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

                    filtersSection

                    summarySection

                    activityListSection
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
            await vm.loadData()
        }
        .onReceive(AppState.shared.$refreshID) { _ in
            Task {
                await vm.loadData()
            }
        }
    }

    private var headerSection: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Activity")
                    .font(
                        .system(
                            size: 34,
                            weight: .bold
                        )
                    )

                Text("Seguimiento de movimientos y decisiones del sistema")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            HStack(spacing: 10) {

                headerIcon("magnifyingglass")

                headerIcon("slider.horizontal.3")
            }
        }
    }

    private func headerIcon(
        _ icon: String
    ) -> some View {

        Button {

        } label: {

            ZStack {

                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
        }
    }

    private var filtersSection: some View {

        HStack(spacing: 0) {

            ForEach(filters, id: \.self) { filter in

                Button {

                    selectedFilter = filter

                } label: {

                    Text(filter)
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(
                            selectedFilter == filter
                            ? AppColors.blue
                            : AppColors.primaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .padding(4)
                                }
                            }
                        )
                }
            }
        }
        .background(Color.gray.opacity(0.08))
        .cornerRadius(20)
    }

    private var summarySection: some View {

        HStack(spacing: 0) {

            summaryCard(
                icon: "arrow.left.arrow.right",
                color: AppColors.green,
                value: "\(vm.movementsCount)",
                title: "Movimientos",
                subtitle: nil
            )

            verticalDivider

            summaryCard(
                icon: "checkmark.rectangle",
                color: AppColors.blue,
                value: "\(vm.completedCount)",
                title: "Completos",
                subtitle: nil
            )

            verticalDivider

            summaryCard(
                icon: "chart.pie",
                color: AppColors.orange,
                value: "\(vm.partialCount)",
                title: "Parciales",
                subtitle: nil
            )

            verticalDivider

            summaryCard(
                icon: "xmark.circle",
                color: AppColors.red,
                value: "\(vm.withoutReplenishmentCount)",
                title: "Sin reposición",
                subtitle: nil
            )
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
    }

    private var verticalDivider: some View {

        Rectangle()
            .fill(Color.gray.opacity(0.15))
            .frame(width: 1, height: 86)
    }

    private func summaryCard(
        icon: String,
        color: Color,
        value: String,
        title: String,
        subtitle: String?
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
                        size: 26,
                        weight: .bold
                    )
                )

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if let subtitle {

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private var activityListSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Hoy")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )

            if filteredActivities.isEmpty {

                EmptyStateView(
                    icon: "clock",
                    title: "Sin actividad",
                    message: "No hay movimientos o decisiones para este filtro."
                )

            } else {

                VStack(spacing: 14) {

                    ForEach(filteredActivities) { item in

                        activityCard(item)
                    }
                }
            }
        }
    }

    private func activityCard(
        _ item: ActivityDTO
    ) -> some View {

        let color = statusColor(item.status)

        return HStack(
            alignment: .top,
            spacing: 10
        ) {

            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .padding(.top, 36)

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                VStack(
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

                            Image(systemName: iconForActivity(item))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(color)
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {

                            Text(typeLabel(item.type))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(color)

                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )

                            Text("\(item.origin) → \(item.destination)")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.secondaryText)

                            statusBadge(item.status)
                        }

                        Spacer()

                        VStack(
                            alignment: .trailing,
                            spacing: 8
                        ) {

                            Text(item.time)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.secondaryText)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }

                    reasonBox(item)

                    routeBox(item)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.10))
                )
            }
        }
    }

    private func statusBadge(
        _ status: String
    ) -> some View {

        let color = statusColor(status)

        return HStack(spacing: 5) {

            Image(systemName: badgeIcon(status))
                .font(.system(size: 10, weight: .bold))

            Text(statusLabel(status))
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(10)
    }

    private func reasonBox(
        _ item: ActivityDTO
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 4
        ) {

            Text("Motivo:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.primaryText)

            Text(item.reason)
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(14)
    }

    private func routeBox(
        _ item: ActivityDTO
    ) -> some View {

        HStack(spacing: 0) {

            routeColumn(
                icon: "shippingbox",
                title: "Origen",
                value: item.origin
            )

            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 1, height: 42)

            routeColumn(
                icon: "building.2",
                title: "Destino",
                value: item.destination
            )
        }
        .padding(12)
        .background(Color.gray.opacity(0.04))
        .cornerRadius(14)
    }

    private func routeColumn(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: icon)
                .foregroundColor(AppColors.secondaryText)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)

                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconForActivity(
        _ item: ActivityDTO
    ) -> String {

        switch item.type.uppercased() {

        case "MOVEMENT_COMPLETED":
            return "arrow.up.right"

        case "PARTIAL_REPLENISHMENT":
            return "chart.pie"

        case "WITHOUT_REPLENISHMENT":
            return "xmark.circle"

        case "SYSTEM_DECISION":
            return "brain.head.profile"

        default:
            return "info.circle"
        }
    }

    private func typeLabel(
        _ type: String
    ) -> String {

        switch type.uppercased() {

        case "MOVEMENT_COMPLETED":
            return "MOVIMIENTO COMPLETADO"

        case "PARTIAL_REPLENISHMENT":
            return "REPOSICIÓN PARCIAL"

        case "WITHOUT_REPLENISHMENT":
            return "SIN REPOSICIÓN"

        case "SYSTEM_DECISION":
            return "DECISIÓN DEL SISTEMA"

        default:
            return type
        }
    }

    private func statusLabel(
        _ status: String
    ) -> String {

        switch status.uppercased() {

        case "COMPLETED":
            return "Completo"

        case "PARTIAL":
            return "Parcial"

        case "WITHOUT_REPLENISHMENT":
            return "Sin reposición"

        case "SYSTEM_DECISION":
            return "Decisión"

        default:
            return status
        }
    }

    private func statusColor(
        _ status: String
    ) -> Color {

        switch status.uppercased() {

        case "COMPLETED":
            return AppColors.green

        case "PARTIAL":
            return AppColors.orange

        case "WITHOUT_REPLENISHMENT":
            return AppColors.red

        case "SYSTEM_DECISION":
            return AppColors.blue

        default:
            return AppColors.blue
        }
    }

    private func badgeIcon(
        _ status: String
    ) -> String {

        switch status.uppercased() {

        case "COMPLETED":
            return "checkmark.circle"

        case "PARTIAL":
            return "clock"

        case "WITHOUT_REPLENISHMENT":
            return "xmark.circle"

        case "SYSTEM_DECISION":
            return "brain.head.profile"

        default:
            return "info.circle"
        }
    }
}

struct ActivityView_Previews: PreviewProvider {

    static var previews: some View {
        ActivityView()
    }
}