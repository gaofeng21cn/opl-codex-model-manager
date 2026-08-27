import SwiftUI

struct SetupView: View {
    @ObservedObject var store: CatalogStore

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("设置 Codex 模型目录")
                    .font(.title2.weight(.semibold))
                Text("应用将建立模型目录、写入 Codex 配置，并安装每日同步任务。")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                SetupItem(title: "自动查找 Codex 运行时", icon: "magnifyingglass")
                SetupItem(title: "创建自定义模型目录", icon: "doc.badge.plus")
                SetupItem(title: "每天同步 OpenAI 官方模型", icon: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }
            .frame(width: 320, alignment: .leading)

            HStack(spacing: 12) {
                SettingsLink {
                    Text("高级设置")
                }

                Button {
                    Task {
                        do {
                            let configuration = try store.recommendedConfiguration()
                            _ = await store.applyConfiguration(configuration)
                        } catch {
                            store.errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    if store.isApplyingConfiguration {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("使用推荐设置")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(store.isApplyingConfiguration)
            }
        }
        .frame(minWidth: 700, minHeight: 520)
        .padding(40)
    }
}

private struct SetupItem: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
