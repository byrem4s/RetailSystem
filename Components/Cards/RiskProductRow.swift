import SwiftUI

struct RiskProductRow: View {

    let item: BranchRiskProduct

    var body: some View {

        HStack(spacing: 14) {

            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.background)
                .frame(width: 54, height: 54)

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Text(item.name)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )

                Text(item.status)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
                    .foregroundColor(item.color)
            }

            Spacer()

            VStack(spacing: 4) {

                Text("Stock")
                    .font(.system(size: 11))
                    .foregroundColor(
                        AppColors.secondaryText
                    )

                Text(item.stock)
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundColor(item.color)
            }

            VStack(spacing: 4) {

                Text("Necesidad")
                    .font(.system(size: 11))
                    .foregroundColor(
                        AppColors.secondaryText
                    )

                Text(item.needed)
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundColor(item.color)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(
                    AppColors.secondaryText
                )
        }
        .padding(.vertical, 10)
    }
}