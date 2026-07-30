import SwiftUI

struct RootView: View {

    @EnvironmentObject private var session: SessionStore
    @State private var selectedTab: AppTab = .home

    var body: some View {

        ZStack(alignment: .bottom) {

            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)

            VStack(spacing: 0) {

                Spacer(minLength: 0)

                BottomTabBar(
                    selectedTab: $selectedTab,
                    tabs: availableTabs
                )
            }
            .ignoresSafeArea(
                .container,
                edges: .bottom
            )
        }
        .background(AppColors.background)
        .onAppear {
            ensureSelectedTabIsAvailable()
        }
        .onChange(of: session.user?.role) { _, _ in
            ensureSelectedTabIsAvailable()
        }
    }

    @ViewBuilder
    private var currentScreen: some View {

        switch selectedTab {

        case .home:
            HomeView(
                onOpenAlerts: {
                    selectedTab = .alerts
                },
                onOpenActivityHistory: {
                    AppState.shared.requestActivityHistoryFocus()
                    selectedTab = .activity
                }
            )

        case .alerts:
            AlertsView()

        case .transfers:
            TransfersV2View()

        case .users:
            UserManagementView()

        case .activity:
            ActivityView()

        case .branches:
            BranchesView()

        case .replenishment:
            ReplenishmentView()

        case .reports:
            ReportsView()
        }
    }

    private var availableTabs: [AppTab] {
        guard let role = session.user?.role else {
            return [.transfers]
        }
        if role.canViewLegacyDashboard {
            return [
                .home,
                .replenishment,
                .transfers,
                .users,
                .branches,
                .reports
            ]
        }
        if role == .branchManager {
            return [.replenishment, .transfers]
        }
        return [.transfers]
    }

    private func ensureSelectedTabIsAvailable() {
        if !availableTabs.contains(selectedTab) {
            selectedTab = availableTabs.first ?? .transfers
        }
    }
}

struct RootView_Previews: PreviewProvider {

    static var previews: some View {
        RootView()
            .environmentObject(
                UserProfileStore()
            )
            .environmentObject(
                SessionStore()
            )
    }
}
