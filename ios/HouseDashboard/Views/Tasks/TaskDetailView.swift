import SwiftData
import SwiftUI

struct TaskDetailView: View {
    let task: TaskModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var syncEngine: SyncEngine
    @EnvironmentObject var notificationScheduler: NotificationScheduler
    @StateObject private var vm = TaskViewModel()

    @State private var notes = ""
    @State private var showCompleteConfirm = false

    private var completionHistory: [CompletionModel] {
        task.completions.sorted { $0.completedAt > $1.completedAt }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Frequency", value: task.frequency.replacingOccurrences(of: "_", with: " ").capitalized)
                if let season = task.season {
                    LabeledContent("Season", value: season.capitalized)
                }
                if let nextDue = task.nextDue {
                    LabeledContent("Next due", value: nextDue.formatted(date: .long, time: .omitted))
                }
                if let lastCompleted = task.lastCompleted {
                    LabeledContent("Last completed", value: lastCompleted.formatted(date: .long, time: .omitted))
                }
                LabeledContent("Source", value: task.source.capitalized)
            }

            if let reason = task.reason {
                Section("Why this task") {
                    Label(reason, systemImage: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                }
            }

            Section("Notes for completion") {
                TextField("Optional notes...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button {
                    showCompleteConfirm = true
                } label: {
                    if vm.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label("Mark as complete", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .bold()
                            .foregroundStyle(.green)
                    }
                }
                .disabled(vm.isLoading)

                Button(role: .destructive) {
                    vm.dismiss(task, context: context, notificationScheduler: notificationScheduler)
                    dismiss()
                } label: {
                    Label("Dismiss this task", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
            }

            if !completionHistory.isEmpty {
                Section("History") {
                    ForEach(completionHistory, id: \.persistentModelID) { completion in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.completedAt.formatted(date: .long, time: .shortened))
                                .font(.subheadline)
                            if let notes = completion.notes {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(task.name)
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Mark as complete?", isPresented: $showCompleteConfirm, titleVisibility: .visible) {
            Button("Complete") {
                Task {
                    await vm.complete(
                        task,
                        notes: notes.isEmpty ? nil : notes,
                        context: context,
                        syncEngine: syncEngine,
                        notificationScheduler: notificationScheduler
                    )
                    dismiss()
                }
            }
        } message: {
            Text("This will log today as the completion date and schedule the next reminder.")
        }
    }
}
