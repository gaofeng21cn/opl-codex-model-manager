import SwiftUI

struct SyncLogView: View {
    let records: [SyncRecord]
    @State private var selection: SyncRecord.ID?

    private var selectedRecord: SyncRecord? {
        guard let selection else { return records.first }
        return records.first { $0.id == selection }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("同步日志")
                    .font(.title2.weight(.semibold))
                Text("查看目录是否发生改动、执行版本和合并数量。")
                    .foregroundStyle(.secondary)
            }
            .padding(20)

            Divider()

            if records.isEmpty {
                ContentUnavailableView("尚无日志", systemImage: "list.bullet.rectangle")
            } else {
                HSplitView {
                    List(records, selection: $selection) { record in
                        SyncRecordRow(record: record)
                            .tag(record.id)
                    }
                    .frame(minWidth: 520)
                    .clipped()

                    LogDetailView(record: selectedRecord)
                        .frame(minWidth: 300, idealWidth: 330, maxWidth: 390)
                        .clipped()
                }
                .frame(minWidth: 820)
            }
        }
        .navigationTitle("同步日志")
    }
}

private struct LogDetailView: View {
    let record: SyncRecord?

    var body: some View {
        if let record {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Image(systemName: record.changed ? "arrow.down.circle.fill" : "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(record.changed ? Color.blue : Color.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.changed ? "目录有改动" : "目录无改动")
                                .font(.title3.weight(.semibold))
                            Text(record.recordedAt.map(AppFormatters.timestamp.string) ?? "旧日志未记录时间")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    DetailRow(title: "状态", value: record.status)
                    DetailRow(title: "Codex 版本", value: record.appVersion)
                    DetailRow(title: "官方模型", value: String(record.bundledCount))
                    DetailRow(title: "自定义模型", value: String(record.customCount))
                    DetailRow(title: "合计", value: String(record.totalCount))
                    DetailRow(title: "哈希一致", value: record.hashesMatch ? "是" : "否")

                    if let backupPath = record.backupPath {
                        Divider()
                        Text("备份")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(backupPath)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ContentUnavailableView("选择一条日志", systemImage: "list.bullet.rectangle")
        }
    }
}
