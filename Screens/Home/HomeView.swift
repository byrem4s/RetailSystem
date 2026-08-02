import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var profileStore: UserProfileStore

    @StateObject private var batchesVM = ExcelBatchViewModel()
    @StateObject private var transfersVM = TransfersV2ViewModel()
    @StateObject private var notificationsVM = NotificationViewModel()
    @StateObject private var intelligenceVM = IntelligenceViewModel()

    @State private var branches: [BranchV2DTO] = []
    @State private var showsNotifications = false
    @State private var showsProfile = false

    let onNavigate: (AppTab) -> Void

    private let branchService = UserManagementService()

    var body: some View {
        NavigationStack {
            ResponsiveScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    welcomeHeader
                    if role != .warehouse {
                        IntelligenceDashboardSection(
                            viewModel: intelligenceVM,
                            isGlobal: role?.canViewGlobalIntelligence == true
                        )
                    }
                    operationalSummary
                    quickActions
                    latestUpdates
                }
            }
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showsNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                            if notificationsVM.unreadCount > 0 {
                                Text(
                                    notificationsVM.unreadCount > 9
                                        ? "9+"
                                        : "\(notificationsVM.unreadCount)"
                                )
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(AppColors.red)
                                .clipShape(Capsule())
                                .offset(x: 9, y: -8)
                            }
                        }
                    }
                    .accessibilityLabel("Notificaciones")

                    Button {
                        showsProfile = true
                    } label: {
                        Text(initials)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppColors.blue)
                            .frame(width: 32, height: 32)
                            .background(AppColors.selection)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Mi cuenta")
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showsNotifications) {
                NotificationsSheet(
                    vm: notificationsVM,
                    onNavigate: onNavigate
                )
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showsProfile) {
                AccountView(branchName: branchName)
                    .environmentObject(session)
                    .environmentObject(profileStore)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var welcomeHeader: some View {
        AppCard(padding: 0) {
            ZStack(alignment: .bottomLeading) {
                AppColors.brandGradient
                Circle()
                    .fill(AppColors.cyan.opacity(0.17))
                    .frame(width: 220, height: 220)
                    .offset(x: 170, y: -70)

                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    StatusPill(
                        title: roleLabel.uppercased(),
                        color: AppColors.cyan
                    )
                    Text("Hola, \(firstName)")
                        .font(
                            .system(
                                .largeTitle,
                                design: .rounded,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                    Text(contextMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 590, alignment: .leading)
                }
                .padding(AppSpacing.large)
            }
            .frame(minHeight: 220)
            .clipped()
        }
    }

    private var operationalSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Qué requiere atención")
                .font(AppTypography.sectionTitle)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 145), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(summaryMetrics) { metric in
                    SummaryMetricCard(metric: metric)
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Accesos rápidos")
                .font(AppTypography.sectionTitle)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 230), spacing: 12)
                ],
                spacing: 12
            ) {
                actionCard(
                    title: role == .branchManager
                        ? "Cargar mis ventas"
                        : "Gestionar reposición",
                    detail: role == .branchManager
                        ? "Ver solicitudes y adjuntar el Excel."
                        : "Abrir períodos, generar y distribuir F8.",
                    icon: "arrow.triangle.2.circlepath",
                    color: AppColors.blue,
                    tab: .replenishment
                )
                actionCard(
                    title: role == .branchManager
                        ? "Preparar y recibir"
                        : "Movimientos",
                    detail: role == .branchManager
                        ? "Ver sólo las tareas de tu sucursal."
                        : "Aprobar, coordinar y cerrar envíos.",
                    icon: "shippingbox.and.arrow.backward",
                    color: AppColors.orange,
                    tab: .transfers
                )
                if canManage {
                    actionCard(
                        title: "Usuarios y sucursales",
                        detail: "Administrar el acceso y consultar la red.",
                        icon: "person.2.badge.gearshape",
                        color: AppColors.purple,
                        tab: .management
                    )
                    actionCard(
                        title: "Historial",
                        detail: "Consultar F8 de períodos anteriores.",
                        icon: "clock.arrow.circlepath",
                        color: AppColors.green,
                        tab: .reports
                    )
                }
            }
        }
    }

    private var latestUpdates: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Últimas novedades")
                    .font(AppTypography.sectionTitle)
                Spacer()
                if !notificationsVM.notifications.isEmpty {
                    Button("Ver todas") {
                        showsNotifications = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }

            AppCard {
                if notificationsVM.isLoading
                    && notificationsVM.notifications.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if notificationsVM.notifications.isEmpty {
                    Label(
                        "No hay novedades pendientes.",
                        systemImage: "checkmark.circle"
                    )
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                } else {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(notificationsVM.notifications.prefix(3))
                        ) { notification in
                            HStack(
                                alignment: .top,
                                spacing: AppSpacing.medium
                            ) {
                                IconBadge(
                                    systemName: updateIcon(notification),
                                    color: notification.isRead
                                        ? AppColors.secondaryText
                                        : AppColors.blue,
                                    size: 38
                                )
                                VStack(
                                    alignment: .leading,
                                    spacing: AppSpacing.xSmall
                                ) {
                                    Text(notification.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(notification.message)
                                        .font(.caption)
                                        .foregroundStyle(
                                            AppColors.secondaryText
                                        )
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(.vertical, AppSpacing.medium)

                            if notification.id
                                != notificationsVM.notifications
                                .prefix(3).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func actionCard(
        title: String,
        detail: String,
        icon: String,
        color: Color,
        tab: AppTab
    ) -> some View {
        Button {
            onNavigate(tab)
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                IconBadge(systemName: icon, color: color)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.primaryText)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: AppSpacing.small)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.tertiaryText)
            }
            .padding(AppSpacing.regular)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background(AppColors.card)
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
                .stroke(AppColors.subtleBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var summaryMetrics: [SummaryMetric] {
        switch role {
        case .branchManager?:
            return [
                SummaryMetric(
                    title: "Ventas a cargar",
                    value: "\(pendingOwnSales)",
                    icon: "arrow.up.doc",
                    color: AppColors.blue
                ),
                SummaryMetric(
                    title: "Para preparar",
                    value: "\(originTasks)",
                    icon: "shippingbox",
                    color: AppColors.orange
                ),
                SummaryMetric(
                    title: "Para recibir",
                    value: "\(destinationTasks)",
                    icon: "tray.and.arrow.down",
                    color: AppColors.green
                ),
                notificationMetric
            ]
        case .warehouse?:
            return [
                SummaryMetric(
                    title: "Movimientos activos",
                    value: "\(activeTransfers.count)",
                    icon: "arrow.left.arrow.right",
                    color: AppColors.orange
                ),
                SummaryMetric(
                    title: "Para coordinar",
                    value: "\(coordinationTasks)",
                    icon: "truck.box",
                    color: AppColors.blue
                ),
                notificationMetric
            ]
        default:
            return [
                SummaryMetric(
                    title: "Períodos abiertos",
                    value: "\(openBatches)",
                    icon: "calendar",
                    color: AppColors.blue
                ),
                SummaryMetric(
                    title: "F8 para revisar",
                    value: "\(reviewableBatches)",
                    icon: "doc.text.magnifyingglass",
                    color: AppColors.purple
                ),
                SummaryMetric(
                    title: "Movimientos activos",
                    value: "\(activeTransfers.count)",
                    icon: "arrow.left.arrow.right",
                    color: AppColors.orange
                ),
                notificationMetric
            ]
        }
    }

    private var notificationMetric: SummaryMetric {
        SummaryMetric(
            title: "Avisos nuevos",
            value: "\(notificationsVM.unreadCount)",
            icon: "bell",
            color: AppColors.red
        )
    }

    private var role: UserRole? { session.user?.role }
    private var canManage: Bool {
        role == .systemOwner || role == .companyAdmin
    }
    private var firstName: String {
        session.user?.firstName.isEmpty == false
            ? session.user?.firstName ?? "Equipo"
            : "Equipo"
    }
    private var initials: String {
        let first = session.user?.firstName.first.map(String.init) ?? ""
        let last = session.user?.lastName.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "U" : value
    }
    private var roleLabel: String {
        session.user?.role.displayName ?? "Operaciones"
    }
    private var branchName: String? {
        guard let id = session.user?.branchID else { return nil }
        return branches.first { $0.id == id }?.name
    }
    private var branchCode: String? {
        guard let id = session.user?.branchID else { return nil }
        return branches.first { $0.id == id }?.code
    }
    private var contextMessage: String {
        switch role {
        case .branchManager?:
            return (
                "\(branchName ?? "Tu sucursal") · Revisá las ventas "
                + "solicitadas y los movimientos que te corresponden."
            )
        case .warehouse?:
            return "Coordiná los movimientos distribuidos y su despacho."
        default:
            return (
                "Una vista breve de los períodos, F8 y movimientos "
                + "que requieren una decisión."
            )
        }
    }

    private var pendingOwnSales: Int {
        guard let branchCode else { return 0 }
        return batchesVM.batches.filter {
            $0.distributedAt == nil
                && !$0.uploadedBranchCodes.contains(branchCode)
        }.count
    }
    private var activeTransfers: [TransferV2DTO] {
        transfersVM.transfers.filter {
            !["COMPLETED", "REJECTED"].contains($0.status)
        }
    }
    private var originTasks: Int {
        guard let branchID = session.user?.branchID else { return 0 }
        return activeTransfers.filter { $0.originBranchID == branchID }.count
    }
    private var destinationTasks: Int {
        guard let branchID = session.user?.branchID else { return 0 }
        return activeTransfers.filter {
            $0.destinationBranchID == branchID
        }.count
    }
    private var coordinationTasks: Int {
        activeTransfers.filter {
            ["RECOMMENDED", "APPROVED", "PREPARING"].contains($0.status)
        }.count
    }
    private var openBatches: Int {
        batchesVM.batches.filter {
            $0.distributedAt == nil
                && ["DRAFT", "READY", "PROCESSING"].contains($0.status)
        }.count
    }
    private var reviewableBatches: Int {
        batchesVM.batches.filter {
            $0.status == "COMPLETED" && $0.distributedAt == nil
        }.count
    }

    private func updateIcon(_ item: NotificationDTO) -> String {
        switch item.notificationType {
        case "SALES_REQUESTED": return "arrow.up.doc"
        case "SALES_UPLOADED": return "checkmark.circle"
        case "PREPARATION_REQUESTED": return "shippingbox"
        case "BATCH_DISTRIBUTED": return "arrow.triangle.branch"
        default: return "bell"
        }
    }

    private func load() async {
        await batchesVM.load()
        await transfersVM.load()
        await notificationsVM.loadNotifications()
        if role != .warehouse {
            await intelligenceVM.load()
        }
        if let values = try? await branchService.fetchBranches() {
            branches = values
        }
    }
}

private struct SummaryMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

private struct SummaryMetricCard: View {
    let metric: SummaryMetric

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                IconBadge(
                    systemName: metric.icon,
                    color: metric.color,
                    size: 38
                )
                Text(metric.value)
                    .font(AppTypography.metric)
                    .foregroundStyle(AppColors.primaryText)
                Text(metric.title)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        }
    }
}

private struct AccountView: View {
    let branchName: String?
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Cuenta") {
                    LabeledContent(
                        "Nombre",
                        value: session.user?.fullName ?? "—"
                    )
                    LabeledContent(
                        "Correo",
                        value: session.user?.email ?? "—"
                    )
                    LabeledContent(
                        "Rol",
                        value: session.user?.role.displayName ?? "—"
                    )
                    if session.user?.branchID != nil {
                        LabeledContent(
                            "Sucursal asignada",
                            value: branchName ?? "Asignada"
                        )
                    }
                }

                Section("Apariencia") {
                    Picker("Tema", selection: $profileStore.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Label(theme.title, systemImage: theme.icon)
                                .tag(theme)
                        }
                    }
                }

                Section("Preferencias") {
                    NavigationLink {
                        NotificationPreferencesView()
                    } label: {
                        Label("Notificaciones", systemImage: "bell.badge")
                    }
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        Task {
                            dismiss()
                            await session.logout()
                        }
                    }
                }
            }
            .navigationTitle("Mi cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
