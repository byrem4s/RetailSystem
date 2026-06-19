import SwiftUI

struct KPICard: View {

    let item: KPIModel

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(item.color.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(item.color)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(item.value)
                    .font(.system(size: 24, weight: .bold))

                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))

                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .cornerRadius(22)
        .shadow(
            color: AppColors.shadow,
            radius: 6,
            y: 2
        )
    }
}