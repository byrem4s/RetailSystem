import SwiftUI

@main
struct RetailSystemApp: App {

    @StateObject private var profileStore = UserProfileStore()

    var body: some Scene {

        WindowGroup {

            RootView()
                .environmentObject(profileStore)
                .preferredColorScheme(
                    profileStore.theme.colorScheme
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
