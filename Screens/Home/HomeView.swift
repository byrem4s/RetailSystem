import SwiftUI
import UIKit

struct HomeView: View {

    @EnvironmentObject private var profileStore: UserProfileStore

    @StateObject private var vm = HomeViewModel()

    @State private var showAllSummaryKPIs = false

    @State private var showAnalysisDateSelector = false

    @StateObject private var notificationsVM = NotificationViewModel()
    
    @State private var showNotifications = false
    @State private var showProfile = false

    let onOpenAlerts: () -> Void
    let onOpenActivityHistory: () -> Void

    init(
        onOpenAlerts: @escaping () -> Void = {},
        onOpenActivityHistory: @escaping () -> Void = {}
    ) {
        self.onOpenAlerts = onOpenAlerts
        self.onOpenActivityHistory = onOpenActivityHistory
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
            isPresented: Binding<Bool>(
                get: {
                    vm.errorMessage != nil
                },
                set: { _ in
                    vm.errorMessage = nil
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    vm.errorMessage = nil
                }
            },
            message: {
                Text(vm.errorMessage ?? "")
            }
        )
        .alert(
            "Sin información",
            isPresented: Binding<Bool>(
                get: {
                    vm.historyMessage != nil
                },
                set: { _ in
                    vm.historyMessage = nil
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    vm.historyMessage = nil
                }
            },
            message: {
                Text(vm.historyMessage ?? "")
            }
        )
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
        }
        .sheet(
            isPresented: $showNotifications
        ) {

            NotificationsSheet(
                vm: notificationsVM
            )
        }
        .sheet(
            isPresented: $showProfile
        ) {

            ProfileView()
                .environmentObject(profileStore)
        }
        .task {
            await vm.loadData()

            profileStore.seedIfNeeded(
                name: vm.userName,
                branch: vm.userBranch
            )

            await notificationsVM.loadUnreadCount()
        }
        .onReceive(AppState.shared.$refreshID) { _ in
            Task {
                await vm.loadData()
                await notificationsVM.loadUnreadCount()
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

            HStack(spacing: 8) {

                Button {

                    showProfile = true

                } label: {

                    ZStack {

                        Circle()
                            .fill(AppColors.blue.opacity(0.14))
                            .frame(width: 42, height: 42)

                        Text(profileStore.initials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.blue)
                    }
                }
                .accessibilityLabel("Abrir perfil")

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
    }

    private var userSection: some View {

        HStack(
            alignment: .top
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Hola, \(profileStore.fullName)")
                    .font(
                        .system(
                            size: 22,
                            weight: .semibold
                        )
                    )

                Text(profileStore.displayBranch)
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

            HStack(spacing: 6) {

                Button {

                    showProfile = true

                } label: {

                    Image(systemName: "person.crop.circle")
                        .font(
                            .system(
                                size: 23,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(AppColors.blue)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Editar perfil")

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
                    .background(AppColors.card)
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

            sectionHeader(
                title: "Actividad reciente",
                actionTitle: "Ver más"
            ) {

                onOpenActivityHistory()
            }

            if vm.recentActivity.isEmpty {

                EmptyStateView(
                    icon: "clock",
                    title: "Sin actividad reciente",
                    message: "Todavía no hay movimientos registrados."
                )

            } else {

                VStack(spacing: 12) {

                    ForEach(vm.recentActivity.prefix(5)) { item in

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
        .background(AppColors.card)
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
        .background(AppColors.card)
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
            .environmentObject(
                UserProfileStore()
            )
    }
}

struct ProfileView: View {

    @EnvironmentObject private var profileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var branch = ""
    @State private var selectedTheme: AppTheme = .light
    @State private var validationMessage: String?

    var body: some View {

        NavigationView {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {

                    VStack(
                        alignment: .leading,
                        spacing: 20
                    ) {

                        identityCard

                        personalInformationSection

                        appearanceSection

                        saveButton

                        Text("Esta información se guarda localmente en esta versión. Cuando se agreguen usuarios, podrá sincronizarse con la cuenta del sistema.")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDraft()
            }
            .alert(
                "Revisar perfil",
                isPresented: Binding(
                    get: {
                        validationMessage != nil
                    },
                    set: { _ in
                        validationMessage = nil
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage ?? "")
            }
        }
        .preferredColorScheme(
            selectedTheme.colorScheme
        )
    }

    private var identityCard: some View {

        VStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(AppColors.blue.opacity(0.14))
                    .frame(width: 88, height: 88)

                Text(draftInitials)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.blue)
            }

            VStack(spacing: 4) {

                Text(draftFullName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Text(
                    branch.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                    ? "Sucursal sin definir"
                    : branch
                )
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 18)
        .background(AppColors.card)
        .cornerRadius(26)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppColors.border.opacity(0.35))
        )
    }

    private var personalInformationSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            sectionTitle(
                "Información personal",
                icon: "person.text.rectangle"
            )

            profileField(
                title: "Nombre",
                placeholder: "Nombre",
                text: $firstName,
                contentType: .givenName
            )

            profileField(
                title: "Apellido",
                placeholder: "Apellido",
                text: $lastName,
                contentType: .familyName
            )

            profileField(
                title: "Sucursal",
                placeholder: "Ej. Calle 12",
                text: $branch,
                contentType: .organizationName
            )
        }
        .padding(18)
        .background(AppColors.card)
        .cornerRadius(24)
    }

    private var appearanceSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            sectionTitle(
                "Apariencia",
                icon: "paintbrush.fill"
            )

            Text("Elegí cómo querés ver la aplicación.")
                .font(.system(size: 13))
                .foregroundColor(AppColors.secondaryText)

            HStack(spacing: 10) {

                ForEach(AppTheme.allCases) { theme in

                    Button {
                        selectedTheme = theme
                    } label: {

                        VStack(spacing: 9) {

                            Image(systemName: theme.icon)
                                .font(.system(size: 20, weight: .semibold))

                            Text(theme.title)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundColor(
                            selectedTheme == theme
                            ? AppColors.blue
                            : AppColors.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 82)
                        .background(
                            selectedTheme == theme
                            ? AppColors.blue.opacity(0.12)
                            : AppColors.elevated
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    selectedTheme == theme
                                    ? AppColors.blue
                                    : AppColors.border.opacity(0.35),
                                    lineWidth: selectedTheme == theme ? 1.5 : 1
                                )
                        )
                        .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                }
            }

            themePreview
        }
        .padding(18)
        .background(AppColors.card)
        .cornerRadius(24)
    }

    private var themePreview: some View {

        HStack(spacing: 12) {

            ZStack {

                RoundedRectangle(cornerRadius: 13)
                    .fill(AppColors.blue.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: "chart.bar.fill")
                    .foregroundColor(AppColors.blue)
            }

            VStack(alignment: .leading, spacing: 3) {

                Text("Vista previa")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)

                Text("Las tarjetas, textos y fondos se adaptan al tema seleccionado.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.elevated)
        .cornerRadius(18)
    }

    private var saveButton: some View {

        Button {
            saveProfile()
        } label: {

            HStack(spacing: 8) {

                Image(systemName: "checkmark.circle.fill")

                Text("Guardar cambios")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.blue)
            .cornerRadius(18)
        }
    }

    private func sectionTitle(
        _ title: String,
        icon: String
    ) -> some View {

        HStack(spacing: 9) {

            Image(systemName: icon)
                .foregroundColor(AppColors.blue)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.primaryText)
        }
    }

    private func profileField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)

            TextField(
                placeholder,
                text: text
            )
            .textContentType(contentType)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppColors.primaryText)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(AppColors.field)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppColors.border.opacity(0.40))
            )
            .cornerRadius(15)
        }
    }

    private var draftFullName: String {

        let values = [firstName, lastName]
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        return values.isEmpty
        ? "Nuevo usuario"
        : values.joined(separator: " ")
    }

    private var draftInitials: String {

        let first = firstName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
            .map(String.init)

        let last = lastName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
            .map(String.init)

        let value = [first, last]
            .compactMap { $0 }
            .joined()
            .uppercased()

        return value.isEmpty ? "U" : value
    }

    private func loadDraft() {

        firstName = profileStore.firstName
        lastName = profileStore.lastName
        branch = profileStore.branch
        selectedTheme = profileStore.theme
    }

    private func saveProfile() {

        guard !firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {

            validationMessage = "Ingresá el nombre del usuario."
            return
        }

        profileStore.updateProfile(
            firstName: firstName,
            lastName: lastName,
            branch: branch,
            theme: selectedTheme
        )

        dismiss()
    }
}

struct ProfileView_Previews: PreviewProvider {

    static var previews: some View {
        ProfileView()
            .environmentObject(
                UserProfileStore()
            )
    }
}
