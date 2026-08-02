import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()

    var body: some View {
        List {
            Section {
                ForEach(viewModel.preferences) { item in
                    Toggle(
                        item.title,
                        isOn: Binding(
                            get: { item.enabled },
                            set: { enabled in
                                Task { await viewModel.set(item, enabled: enabled) }
                            }
                        )
                    )
                }
            } footer: {
                Text(
                    "Las alertas desactivadas no se crearán para tu usuario. "
                    + "Podés volver a activarlas cuando quieras."
                )
            }
        }
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading && viewModel.preferences.isEmpty {
                ProgressView("Cargando preferencias…")
            }
        }
        .task { await viewModel.load() }
        .alert(
            "No se pudo guardar",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
