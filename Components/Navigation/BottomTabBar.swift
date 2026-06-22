import SwiftUI

struct BottomTabBar: View {

    @Binding var selectedTab: AppTab

    var body: some View {

        HStack {

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
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .background(AppColors.card)
        .cornerRadius(28)
        .shadow(
            color: AppColors.shadow,
            radius: 12,
            y: 4
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
            .padding(.vertical, 3)
        }
    }
}