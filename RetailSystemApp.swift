import SwiftUI


@main
struct RetailSystemApp: App {

    var body: some Scene {

        WindowGroup {

            RootView()

                .preferredColorScheme(
                    .light
                )

                .onReceive(
                    AppState.shared.$refreshID
                ) { _ in

                    print(
                        "Global refresh triggered"
                    )
                }
        }
    }
}