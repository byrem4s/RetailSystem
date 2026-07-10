import SwiftUI

struct BottomTabBar: View {

    @Binding var selectedTab: AppTab

    var body: some View {

        VStack(spacing: 0) {

            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 1)

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
            .frame(height: 54)
            .padding(.bottom, 7)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
    }

    private func tabButton(
        tab: AppTab,
        icon: String,
        title: String
    ) -> some View {

        Button {

            selectedTab = tab

        } label: {

            VStack(spacing: 2) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )

                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(
                selectedTab == tab
                ? AppColors.blue
                : AppColors.secondaryText
            )
            .frame(maxWidth: .infinity)
            .frame(height: 54, alignment: .bottom)
            .padding(.bottom, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}