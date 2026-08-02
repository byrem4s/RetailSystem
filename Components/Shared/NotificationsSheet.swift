import SwiftUI

struct NotificationsSheet: View {
    @ObservedObject var vm: NotificationViewModel
    let onNavigate: (AppTab) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.notifications.isEmpty {
                    ProgressView("Cargando notificaciones…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.notifications.isEmpty {
                    ContentUnavailableView(
                        "Todo al día",
                        systemImage: "bell.slash",
                        description: Text(
                            "Las solicitudes de ventas y tareas de envío "
                            + "aparecerán acá."
                        )
                    )
                } else {
                    List(vm.notifications) { item in
                        Button {
                            Task {
                                await vm.markAsRead(item)
                                let destination = destination(for: item)
                                dismiss()
                                onNavigate(destination)
                            }
                        } label: {
                            notificationRow(item)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Leer todo") {
                        Task { await vm.markAllAsRead() }
                    }
                    .disabled(vm.unreadCount == 0)
                }
            }
            .task { await vm.loadNotifications() }
            .alert(
                "No se pudo completar la acción",
                isPresented: Binding(
                    get: { vm.errorMessage != nil },
                    set: { if !$0 { vm.errorMessage = nil } }
                )
            ) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private func notificationRow(_ item: NotificationDTO) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            IconBadge(
                systemName: icon(for: item),
                color: color(for: item),
                size: 44
            )
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.primaryText)
                    Spacer(minLength: AppSpacing.small)
                    if !item.isRead {
                        Circle()
                            .fill(AppColors.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(item.message)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(relativeDate(item.createdAt))
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
        .padding(.vertical, AppSpacing.small)
    }

    private func icon(for item: NotificationDTO) -> String {
        switch item.notificationType {
        case "SALES_REQUESTED": return "doc.badge.plus"
        case "SALES_UPLOADED": return "checkmark.circle.fill"
        case "PREPARATION_REQUESTED": return "shippingbox.fill"
        case "INCOMING_TRANSFER": return "tray.and.arrow.down.fill"
        case "BATCH_DISTRIBUTED": return "arrow.triangle.branch"
        default: return "bell.fill"
        }
    }

    private func destination(for item: NotificationDTO) -> AppTab {
        if item.transferID != nil
            || item.notificationType.hasPrefix("CUSTOMER_")
            || item.notificationType == "PREPARATION_REQUESTED"
            || item.notificationType == "INCOMING_TRANSFER" {
            return .transfers
        }
        if item.batchID != nil
            || item.notificationType == "SALES_REQUESTED"
            || item.notificationType == "BATCH_DISTRIBUTED" {
            return .replenishment
        }
        return .home
    }

    private func color(for item: NotificationDTO) -> Color {
        switch item.severity.uppercased() {
        case "ERROR": return AppColors.red
        case "WARNING": return AppColors.orange
        case "SUCCESS": return AppColors.green
        default: return AppColors.blue
        }
    }

    private func relativeDate(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        let date = formatter.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
        guard let date else { return value }
        return date.formatted(.relative(presentation: .named))
    }
}
