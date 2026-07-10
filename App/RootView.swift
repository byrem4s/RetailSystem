import SwiftUI

struct RootView: View {

    @State private var selectedTab: AppTab = .home

    var body: some View {

        ZStack(alignment: .bottom) {

            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)

            VStack(spacing: 0) {

                Spacer(minLength: 0)

                BottomTabBar(
                    selectedTab: $selectedTab
                )
            }
            .ignoresSafeArea(
                .container,
                edges: .bottom
            )
        }
        .background(AppColors.background)
    }

    @ViewBuilder
    private var currentScreen: some View {

        switch selectedTab {

        case .home:
            HomeView(
                onOpenAlerts: {
                    selectedTab = .alerts
                }
            )

        case .alerts:
            AlertsView()

        case .activity:
            ActivityView()

        case .branches:
            BranchesView()

        case .reports:
            ReportsView()
        }
    }
}

struct RootView_Previews: PreviewProvider {

    static var previews: some View {
        RootView()
    }
}   