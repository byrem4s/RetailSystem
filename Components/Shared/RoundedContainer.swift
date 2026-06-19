import SwiftUI

struct RoundedContainer<Content: View>: View {

    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {

        self.content = content()
    }

    var body: some View {

        content
            .background(Color.white)
            .cornerRadius(22)
    }
}