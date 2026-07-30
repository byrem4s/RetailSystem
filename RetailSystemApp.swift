import SwiftUI

@main
struct RetailSystemApp: App {
    @StateObject private var profileStore = UserProfileStore()
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if sessionStore.isRestoring {
                    restoringView
                } else if sessionStore.isAuthenticated {
                    RootView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(profileStore)
            .environmentObject(sessionStore)
            .preferredColorScheme(profileStore.theme.colorScheme)
            .task { await sessionStore.restoreSession() }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .sessionUnauthorized
                )
            ) { _ in
                sessionStore.invalidateSession()
            }
        }
    }

    private var restoringView: some View {
        ZStack {
            AppColors.brandGradient
                .ignoresSafeArea()
            VStack(spacing: AppSpacing.regular) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppColors.blue)
                    .frame(width: 72, height: 72)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                ProgressView()
                    .tint(.white)
                Text("Preparando operaciones…")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}
