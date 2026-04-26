import SwiftUI

struct TaskCardView: View {
    let task: TaskModel

    private var statusColor: Color {
        if task.isOverdue { return .red }
        if task.isDueSoon { return .orange }
        return .green
    }

    private var dueDateText: String {
        guard let nextDue = task.nextDue else { return "No date set" }
        if task.isOverdue {
            return "Overdue · \(nextDue.formatted(.relative(presentation: .named)))"
        }
        return "Due \(nextDue.formatted(.relative(presentation: .named)))"
    }

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Label(dueDateText, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(task.frequency.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }

                if task.source == "llm", let reason = task.reason {
                    Label(reason, systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}
