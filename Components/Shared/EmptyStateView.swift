import SwiftUI

struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String

    var body: some View {

        VStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(AppColors.secondaryText)

            Text(title)
                .font(.system(size: 18, weight: .semibold))

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(22)
    }
}