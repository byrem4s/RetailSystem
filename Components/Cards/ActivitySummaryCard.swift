import SwiftUI

struct ActivitySummaryCard: View {

    let icon: String
    let color: Color

    let value: String
    let title: String
    let trend: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundColor(color)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(value)
                    .font(
                        .system(
                            size: 26,
                            weight: .bold
                        )
                    )

                Text(title)
                    .font(.system(size: 13))

                Text(trend)
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(22)
    }
}