import SwiftUI

struct RootView: View {

    @State private var selectedTab: AppTab = .home

    var body: some View {

        ZStack(alignment: .bottom) {

            Group {

                switch selectedTab {

                case .home:
                    HomeView()

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

            BottomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
        }
        .background(AppColors.background)
    }
}

struct RootView_Previews: PreviewProvider {

    static var previews: some View {

        RootView()
    }
}