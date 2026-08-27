import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarDestination?
    let scheduler: SchedulerSnapshot
    let lastRunAt: Date?

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(SidebarDestination.allCases) { destination in
                    Label(destination.title, systemImage: destination.icon)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .tag(destination)
                }
            }

            Section("同步任务") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(scheduler.isHealthy ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scheduler.isHealthy ? "运行正常" : "需要检查")
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(lastRunLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("模型目录")
    }

    private var lastRunLabel: String {
        guard let lastRunAt else { return "尚无执行时间" }
        return AppFormatters.timestamp.string(from: lastRunAt)
    }
}
