import SwiftUI

struct ActivityView: View {

    @StateObject private var vm = ActivityViewModel()
    @State private var selectedFilter = "Todas"

    private let filters = [
        "Todas",
        "Pipeline",
        "F8",
        "Reportes",
        "Errores"
    ]

    private var filteredActivities: [ActivityDTO] {

        switch selectedFilter {

        case "Pipeline":
            return vm.pipelineActivities

        case "F8":
            return vm.f8Activities

        case "Reportes":
            return vm.reportActivities

        case "Errores":
            return vm.errorActivities

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

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Actividad")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Text("Historial operativo del sistema")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
        }
    }

    private var filtersSection: some View {

        HStack(spacing: 0) {

            ForEach(filters, id: \.self) { filter in

                Button {

                    selectedFilter = filter

                } label: {

                    Text(filter)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            selectedFilter == filter
                            ? AppColors.blue
                            : AppColors.primaryText
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                }
                            }
                        )
                }
            }
        }
        .frame(height: 42)
        .padding(4)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(20)
    }

    private var summarySection: some View {

        VStack(spacing: 12) {

            HStack(spacing: 12) {

                summaryCard(
                    icon: "clock.arrow.circlepath",
                    color: AppColors.blue,
                    value: "\(vm.totalCount)",
                    title: "Eventos"
                )

                summaryCard(
                    icon: "checkmark.circle.fill",
                    color: AppColors.green,
                    value: "\(vm.completedCount)",
                    title: "Completados"
                )
            }

            HStack(spacing: 12) {

                summaryCard(
                    icon: "doc.text.fill",
                    color: AppColors.orange,
                    value: "\(vm.reportCount)",
                    title: "Reportes"
                )

                summaryCard(
                    icon: "exclamationmark.triangle.fill",
                    color: vm.failedCount > 0 ? AppColors.red : AppColors.green,
                    value: "\(vm.failedCount)",
                    title: "Errores"
                )
            }
        }
    }

    private func summaryCard(
        icon: String,
        color: Color,
        value: String,
        title: String
    ) -> some View {

        HStack(spacing: 12) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {

                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(22)
    }

    private var activityListSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Historial")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            if filteredActivities.isEmpty {

                EmptyStateView(
                    icon: "clock",
                    title: "Sin actividad",
                    message: "No hay eventos para este filtro."
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

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(
                alignment: .top,
                spacing: 12
            ) {

                ZStack {

                    RoundedRectangle(cornerRadius: 14)
                        .fill(activityColor(item).opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: activityIcon(item))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(activityColor(item))
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    HStack {

                        Text(activityLabel(item))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(activityColor(item))

                        Spacer()

                        Text(item.time)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                    }

                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    if !item.description.isEmpty {

                        Text(item.description)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.secondaryText)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }
                }
            }

            activityMetadata(item)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
    }

    private func activityMetadata(
        _ item: ActivityDTO
    ) -> some View {

        HStack(spacing: 8) {

            metadataBadge(
                title: "Origen",
                value: item.source
            )

            if let executionID = item.executionID {

                metadataBadge(
                    title: "Run",
                    value: "\(executionID)"
                )
            }

            if let draftID = item.draftID {

                metadataBadge(
                    title: "F8",
                    value: "\(draftID)"
                )
            }
        }
    }

    private func metadataBadge(
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 4) {

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AppColors.secondaryText)

            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.primaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
    }

    private func activityIcon(
        _ item: ActivityDTO
    ) -> String {

        let event = item.eventType.uppercased()

        if event.hasPrefix("F8_") {
            return "tablecells.fill"
        }

        if event == "REPORTS_GENERATED" {
            return "doc.text.fill"
        }

        if event.contains("FAILED") || item.status.uppercased() == "FAILED" {
            return "exclamationmark.triangle.fill"
        }

        if event.contains("COMPLETED") {
            return "checkmark.circle.fill"
        }

        return "gearshape.fill"
    }

    private func activityColor(
        _ item: ActivityDTO
    ) -> Color {

        let severity = item.severity.uppercased()
        let status = item.status.uppercased()

        if severity == "ERROR" || status == "FAILED" {
            return AppColors.red
        }

        if severity == "WARNING" {
            return AppColors.orange
        }

        if severity == "SUCCESS" || status == "COMPLETED" || status == "CONFIRMED" {
            return AppColors.green
        }

        if item.eventType.uppercased().hasPrefix("F8_") {
            return AppColors.orange
        }

        return AppColors.blue
    }

    private func activityLabel(
        _ item: ActivityDTO
    ) -> String {

        let source = item.source.uppercased()

        if source == "PIPELINE" {
            return "Pipeline"
        }

        if source == "REPORTS" {
            return "Reporte"
        }

        if source == "F8" {
            return "F8"
        }

        return source
    }
}