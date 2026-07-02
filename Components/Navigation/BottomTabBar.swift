import SwiftUI

struct BottomTabBar: View {

    @Binding var selectedTab: AppTab

    var body: some View {

        HStack(spacing: 0) {

            tabButton(
                tab: .home,
                icon: "house",
                title: "Home"
            )

            tabButton(
                tab: .alerts,
                icon: "bell",
                title: "Alerts"
            )

            tabButton(
                tab: .activity,
                icon: "arrow.left.arrow.right",
                title: "Activity"
            )

            tabButton(
                tab: .branches,
                icon: "building.2",
                title: "Branches"
            )

            tabButton(
                tab: .reports,
                icon: "doc.text",
                title: "Reports"
            )
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 1),
            alignment: .top
        )
    }

    func tabButton(
        tab: AppTab,
        icon: String,
        title: String
    ) -> some View {

        Button {

            selectedTab = tab

        } label: {

            VStack(spacing: 4) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )

                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(
                selectedTab == tab
                ? AppColors.blue
                : AppColors.secondaryText
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
    }
}