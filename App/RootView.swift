import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(availableTabs) { tab in
                screen(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(AppColors.blue)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(AppColors.canvas, for: .tabBar)
        .onAppear { ensureSelectedTabIsAvailable() }
        .onChange(of: session.user?.role) { _, _ in
            ensureSelectedTabIsAvailable()
        }
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView { destination in
                guard availableTabs.contains(destination) else { return }
                selectedTab = destination
            }
        case .replenishment:
            ReplenishmentView()
        case .transfers:
            TransfersV2View()
        case .management:
            ManagementView()
        case .reports:
            ReportsView()
        }
    }

    private var availableTabs: [AppTab] {
        guard let role = session.user?.role else {
            return [.home]
        }
        switch role {
        case .systemOwner, .companyAdmin:
            return [
                .home,
                .replenishment,
                .transfers,
                .management,
                .reports
            ]
        case .branchManager:
            return [.home, .replenishment, .transfers]
        case .warehouse:
            return [.home, .transfers]
        }
    }

    private func ensureSelectedTabIsAvailable() {
        if !availableTabs.contains(selectedTab) {
            selectedTab = availableTabs.first ?? .home
        }
    }
}
