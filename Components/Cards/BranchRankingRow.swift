import SwiftUI

struct BranchRankingRow: View {

    let position: Int
    let item: BranchModel

    let selected: Bool

    var body: some View {

        HStack(spacing: 14) {

            Text("\(position)")
                .font(
                    .system(
                        size: 16,
                        weight: .bold
                    )
                )
                .foregroundColor(
                    AppColors.secondaryText
                )
                .frame(width: 20)

            ZStack {

                Circle()
                    .stroke(
                        item.color.opacity(0.18),
                        lineWidth: 5
                    )
                    .frame(width: 42, height: 42)

                Circle()
                    .trim(
                        from: 0,
                        to: CGFloat(item.health) / 100
                    )
                    .stroke(
                        item.color,
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 42, height: 42)

                Text("\(item.health)")
                    .font(
                        .system(
                            size: 10,
                            weight: .bold
                        )
                    )
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(item.name)
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )

                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(
                        AppColors.secondaryText
                    )
            }

            Spacer()

            compactMetric(
                value: "\(item.breakRisk)",
                color: AppColors.red
            )

            compactMetric(
                value: "\(item.noRotation)",
                color: AppColors.orange
            )

            compactMetric(
                value: "\(item.overstock)",
                color: AppColors.blue
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    selected
                    ? AppColors.blue.opacity(0.25)
                    : Color.clear,
                    lineWidth: 1.5
                )
        )
        .cornerRadius(20)
    }

    func compactMetric(
        value: String,
        color: Color
    ) -> some View {

        Text(value)
            .font(
                .system(
                    size: 16,
                    weight: .bold
                )
            )
            .foregroundColor(color)
            .frame(width: 28)
    }
}