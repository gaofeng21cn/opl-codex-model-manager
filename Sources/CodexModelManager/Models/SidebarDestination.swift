import Foundation

enum SidebarDestination: String, CaseIterable, Identifiable {
    case overview
    case allModels
    case customModels
    case logs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "概览"
        case .allModels: "全部模型"
        case .customModels: "自定义模型"
        case .logs: "同步日志"
        }
    }

    var icon: String {
        switch self {
        case .overview: "gauge.with.dots.needle.67percent"
        case .allModels: "square.stack.3d.up"
        case .customModels: "slider.horizontal.3"
        case .logs: "list.bullet.rectangle"
        }
    }
}
