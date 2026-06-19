import SwiftUI

struct BranchHealthCard: View {

    let icon: String
    let color: Color

    let value: String
    let title: String
    let subtitle: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundColor(color)
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(value)
                    .font(
                        .system(
                            size: 30,
                            weight: .bold
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(
                        AppColors.secondaryText
                    )
            }
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            minHeight: 160,
            maxHeight: 160,
            alignment: .topLeading
        )
        .background(Color.white)
        .cornerRadius(24)
    }
}