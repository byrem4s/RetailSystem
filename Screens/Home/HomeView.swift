import SwiftUI

struct HomeView: View {

    @StateObject private var vm = HomeViewModel()

    @State private var showAllSummaryKPIs = false

    @State private var showAnalysisDateSelector = false

    @StateObject private var notificationsVM = NotificationViewModel()
    
    @State private var showNotifications = false

    let onOpenAlerts: () -> Void

    init(
        onOpenAlerts: @escaping () -> Void = {}
    ) {
        self.onOpenAlerts = onOpenAlerts
    }

    private var primarySummaryKPIs: [KPIModel] {

        [
            .init(
                icon: "arrow.left.arrow.right",
                color: AppColors.blue,
                value: valueText(vm.homeData?.summary.movements),
                title: "Unidades",
                subtitle: "a mover"
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

    private var extraSummaryKPIs: [KPIModel] {

        [
            .init(
                icon: "shippingbox.fill",
                color: AppColors.blue,
                value: valueText(vm.homeData?.summary.suggestedUnits),
                title: "Unidades",
                subtitle: "sugeridas"
            ),
            .init(
                icon: "checkmark.seal.fill",
                color: AppColors.green,
                value: valueText(vm.homeData?.summary.coveredUnits),
                title: "Unidades",
                subtitle: "cubiertas"
            ),
            .init(
                icon: "clock.badge.exclamationmark.fill",
                color: AppColors.orange,
                value: valueText(vm.homeData?.summary.pendingUnits),
                title: "Unidades",
                subtitle: "pendientes"
            ),
            .init(
                icon: "percent",
                color: AppColors.green,
                value: percentText(vm.homeData?.summary.coverageRate),
                title: "Cobertura",
                subtitle: "general"
            ),
            .init(
                icon: "list.bullet.rectangle.fill",
                color: AppColors.blue,
                value: valueText(vm.homeData?.summary.detectedCases),
                title: "Reposiciones ",
                subtitle: "sugeridas"
            ),
            .init(
                icon: "building.2.crop.circle.fill",
                color: AppColors.red,
                value: valueText(vm.homeData?.summary.branchesWithRisk),
                title: "Sucursales",
                subtitle: "con riesgo"
            ),
            .init(
                icon: "clock.fill",
                color: AppColors.orange,
                value: vm.homeData?.summary.lastUpdate ?? "-",
                title: "Última",
                subtitle: "actualización"
            )
        ]
    }

    private var visibleSummaryKPIs: [KPIModel] {

        showAllSummaryKPIs
        ? primarySummaryKPIs + extraSummaryKPIs
        : primarySummaryKPIs
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
        )
        .alert(
            "Sin información",
            isPresented: Binding(
                get: { vm.historyMessage != nil },
                set: { _ in vm.historyMessage = nil }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(vm.historyMessage ?? "")
        } 
        .sheet(
            isPresented: $showAnalysisDateSelector
        ) {

            AnalysisDateSelectorSheet(
                selectedDate: $vm.selectedHistoryDate,
                analyses: vm.historyAnalyses,
                isLoading: vm.isHistoryLoading,
                isHistoricalMode: vm.isHistoricalMode,
                historicalLabel: vm.historicalLabel,
                onSearch: {
                    Task {
                        await vm.loadHistoryForSelectedDate()
                    }
                },
                onSelect: { item in
                    Task {
                        await vm.selectHistoricalAnalysis(
                            item
                        )
                    }
                },
                onClear: {
                    Task {
                        await vm.clearHistoricalMode()
                    }
                }
            )
        }{
            Button("OK") {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task {
            await vm.loadData()
            await notificationsVM.loadUnreadCount()
        }
        .onReceive(AppState.shared.$refreshID) { _ in
            Task {
                await vm.loadData()
                await notificationsVM.loadUnreadCount()
            }
        }

        .sheet(
            isPresented: $showNotifications
        ) {

            NotificationsSheet(
                vm: notificationsVM
            )
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

                showNotifications = true

            } label: {

                ZStack(alignment: .topTrailing) {

                    Image(systemName: "bell")
                        .font(
                            .system(
                                size: 24,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(AppColors.primaryText)
                        .frame(width: 44, height: 44)

                    if notificationsVM.unreadCount > 0 {

                        Text(
                            notificationsVM.unreadCount > 99
                            ? "99+"
                            : "\(notificationsVM.unreadCount)"
                        )
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(AppColors.red)
                        .clipShape(Capsule())
                        .offset(x: 4, y: 2)
                    }
                }
            }
        }
    }

    private var userSection: some View {

        HStack(
            alignment: .top
        ) {

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

                if vm.isHistoricalMode,
                let historicalLabel = vm.historicalLabel {

                    Text("Modo histórico · \(historicalLabel)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.orange)
                        .padding(.top, 4)
                }
            }

            Spacer()

            Button {

                showAnalysisDateSelector = true

            } label: {

                Image(systemName: "calendar")
                    .font(
                        .system(
                            size: 23,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(
                        vm.isHistoricalMode
                        ? AppColors.orange
                        : AppColors.primaryText
                    )
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var summarySection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            sectionHeader(
                title: "Resumen general",
                actionTitle: showAllSummaryKPIs ? nil : "Ver más"
            ) {

                withAnimation(.easeInOut) {
                    showAllSummaryKPIs = true
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(
                            minimum: 145,
                            maximum: 165
                        ),
                        spacing: 12
                    )
                ],
                alignment: .center,
                spacing: 12
            ) {

                ForEach(visibleSummaryKPIs) { item in

                    summaryKPICard(item)
                }
            }

            if showAllSummaryKPIs {

                Button {

                    withAnimation(.easeInOut) {
                        showAllSummaryKPIs = false
                    }

                } label: {

                    HStack(spacing: 6) {

                        Text("Mostrar menos")

                        Image(systemName: "chevron.up")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(16)
                }
            }
        }
    }

    private var risksSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            sectionHeader(
                title: "Alertas activas",
                actionTitle: "Ver más"
            ) {

                onOpenAlerts()
            }

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

    private func sectionHeader(
        title: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {

        HStack {

            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Spacer()

            if let actionTitle {

                Button {

                    action()

                } label: {

                    HStack(spacing: 4) {

                        Text(actionTitle)

                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.blue)
                }
            }
        }
    }

    private func summaryKPICard(
        _ item: KPIModel
    ) -> some View {

        VStack(
            alignment: .center,
            spacing: 12
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 16)
                    .fill(item.color.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(item.color)
            }

            Text(item.value)
                .font(.system(size: 27, weight: .bold))
                .foregroundColor(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack(spacing: 3) {

                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(item.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(14)
        .frame(
            minHeight: 145
        )
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
        .background(Color.white)
        .cornerRadius(22)
    }

    private func riskCard(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {

        VStack(
            alignment: .center,
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
                .multilineTextAlignment(.center)

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
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .center)
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
                        .fill(activityColor(item).opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: activityIcon(item))
                        .foregroundColor(activityColor(item))
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    HStack {

                        Text(activityLabel(item))
                            .font(
                                .system(
                                    size: 11,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(activityColor(item))

                        Spacer()

                        Text(item.time)
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

                    if !item.description.isEmpty {

                        Text(item.description)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }

                    activityMetadata(
                        item
                    )
                }
            }
            .padding()
        }
    }


    private func activityMetadata(
        _ item: HomeRecentActivityDTO
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
        _ item: HomeRecentActivityDTO
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


    private func activityLabel(
        _ item: HomeRecentActivityDTO
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


    private func activityColor(
        _ item: HomeRecentActivityDTO
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

    private func valueText(
        _ value: Int?
    ) -> String {

        guard let value else {
            return "-"
        }

        return "\(value)"
    }

    private func percentText(
        _ value: Int?
    ) -> String {

        guard let value else {
            return "-"
        }

        return "\(value)%"
    }
}

struct HomeView_Previews: PreviewProvider {

    static var previews: some View {
        HomeView()
    }
}