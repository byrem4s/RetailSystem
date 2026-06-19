import SwiftUI

struct SectionHeader: View {

    let title: String
    let actionTitle: String?

    var body: some View {

        HStack {

            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Spacer()

            if let actionTitle {

                HStack(spacing: 4) {

                    Text(actionTitle)

                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.blue)
                .font(.subheadline)
            }
        }
    }
}