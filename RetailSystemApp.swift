import SwiftUI

@main
struct RetailSystemApp: App {

    @StateObject private var profileStore = UserProfileStore()
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {

        WindowGroup {

            Group {
                if sessionStore.isRestoring {
                    ProgressView("Restaurando sesión…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.background)
                } else if sessionStore.isAuthenticated {
                    RootView()
                } else {
                    LoginView()
                }
            }
                .environmentObject(profileStore)
                .environmentObject(sessionStore)
                .preferredColorScheme(
                    profileStore.theme.colorScheme
                )
                .task {
                    await sessionStore.restoreSession()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: .sessionUnauthorized
                    )
                ) { _ in
                    sessionStore.invalidateSession()
                }
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
