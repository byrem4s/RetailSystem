import SwiftUI

struct ActivityCard: View {

    let item: ActivityModel

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(item.color.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(item.color)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))

                Text(item.description)
                    .font(.system(size: 13))

                Text(item.detail)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            Text(item.time)
                .font(.system(size: 11))
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(14)
        .background(AppColors.card)
        .cornerRadius(20)
        .shadow(
            color: AppColors.shadow,
            radius: 6,
            y: 2
        )
    }
}