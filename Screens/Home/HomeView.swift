import SwiftUI

struct HomeView: View {

    @StateObject private var vm = HomeViewModel()

    private var summaryKPIs: [KPIModel] {

        [
            .init(
                icon: "arrow.left.arrow.right",
                color: AppColors.blue,
                value: valueText(vm.homeData?.summary.movements),
                title: "Movimientos",
                subtitle: "realizados"
            ),
            .init(
                icon: "checkmark.circle.fill",
                color: AppColors.green,
                value: valueText(vm.homeData?.summary.completedReplenishments),
                title: "Reposiciones",
                subtitle: "completas"
            ),
            .init(
                icon: "chart.pie.fill",
                color: AppColors.orange,
                value: valueText(vm.homeData?.summary.partialReplenishments),
                title: "Reposiciones",
                subtitle: "parciales"
            ),
            .init(
                icon: "exclamationmark.triangle.fill",
                color: AppColors.red,
                value: valueText(vm.homeData?.summary.withoutReplenishment),
                title: "Sin reposición",
                subtitle: "stock insuficiente"
            )
        ]
    }

    var body: some View {

        ZStack {

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    headerSection

                    userSection

                    summarySection

                    risksSection

                    recentActivitySection
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

                Text("Home")
                    .font(
                        .system(
                            size: 34,
                            weight: .bold
                        )
                    )

                Text("Resumen operativo")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            Button {

            } label: {

                ZStack {

                    Circle()
                        .fill(Color.white)
                        .frame(width: 46, height: 46)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }

    private var userSection: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Hola, \(vm.userName)")
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )

            Text(vm.userBranch)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
        }
    }

    private var summarySection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            SectionHeader(
                title: "Resumen general",
                actionTitle: nil
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 14
            ) {

                ForEach(summaryKPIs) { item in
                    KPICard(item: item)
                }
            }
        }
    }

    private var risksSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            SectionHeader(
                title: "Alertas activas",
                actionTitle: nil
            )

            HStack(spacing: 10) {

                riskCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Riesgo crítico",
                    value: valueText(vm.homeData?.risks.critical),
                    color: AppColors.red
                )

                riskCard(
                    icon: "flame.fill",
                    title: "Riesgo alto",
                    value: valueText(vm.homeData?.risks.high),
                    color: AppColors.orange
                )

                riskCard(
                    icon: "clock.fill",
                    title: "Riesgo medio",
                    value: valueText(vm.homeData?.risks.medium),
                    color: AppColors.blue
                )
            }
        }
    }

    private var recentActivitySection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            SectionHeader(
                title: "Actividad reciente",
                actionTitle: nil
            )

            if vm.recentActivity.isEmpty {

                EmptyStateView(
                    icon: "clock",
                    title: "Sin actividad reciente",
                    message: "Todavía no hay movimientos registrados."
                )

            } else {

                VStack(spacing: 12) {

                    ForEach(vm.recentActivity.prefix(4)) { item in

                        activityRow(item)
                    }
                }
            }
        }
    }

    private func riskCard(
        icon: String,
        title: String,
        value: String,
        color: Color
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
                        size: 28,
                        weight: .bold
                    )
                )

            Text(title)
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundColor(AppColors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(22)
    }

    private func activityRow(
        _ item: HomeRecentActivityDTO
    ) -> some View {

        RoundedContainer {

            HStack(
                alignment: .top,
                spacing: 14
            ) {

                ZStack {

                    RoundedRectangle(cornerRadius: 14)
                        .fill(priorityColor(item.priority).opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: activityIcon(item))
                        .foregroundColor(priorityColor(item.priority))
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    HStack {

                        Text(priorityLabel(item.priority))
                            .font(
                                .system(
                                    size: 11,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(priorityColor(item.priority))

                        Spacer()

                        Text("Sugerido: \(item.suggested)")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.secondaryText)
                    }

                    Text(item.title)
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )

                    Text(item.branch)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)

                    Text(item.reason)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }
            .padding()
        }
    }

    private func activityIcon(
        _ item: HomeRecentActivityDTO
    ) -> String {

        item.suggested > 0
        ? "arrow.left.arrow.right"
        : "exclamationmark.triangle.fill"
    }

    private func priorityLabel(
        _ priority: String
    ) -> String {

        let value = priority.uppercased()

        if value.contains("CRITICAL") {
            return "Crítico"
        }

        if value.contains("HIGH") {
            return "Alto"
        }

        if value.contains("MEDIUM") {
            return "Medio"
        }

        return priority
    }

    private func priorityColor(
        _ priority: String
    ) -> Color {

        let value = priority.uppercased()

        if value.contains("CRITICAL") {
            return AppColors.red
        }

        if value.contains("HIGH") {
            return AppColors.orange
        }

        if value.contains("MEDIUM") {
            return AppColors.blue
        }

        return AppColors.green
    }

    private func valueText(
        _ value: Int?
    ) -> String {

        guard let value else {
            return "-"
        }

        return "\(value)"
    }
}

struct HomeView_Previews: PreviewProvider {

    static var previews: some View {
        HomeView()
    }
}