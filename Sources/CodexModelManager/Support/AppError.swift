import Foundation

enum AppError: LocalizedError {
    case configurationNotFound(String)
    case invalidConfiguration(String)
    case invalidData(String)
    case duplicateSlug(String)
    case invalidSlug
    case missingTemplate
    case processFailed(String)
    case syncTimedOut

    var errorDescription: String? {
        switch self {
        case .configurationNotFound(let path):
            "尚未找到本机配置：\(path)。请参考 README 创建配置文件后重新打开应用。"
        case .invalidConfiguration(let detail): "本机配置无效：\(detail)"
        case .invalidData(let detail): "模型目录格式无效：\(detail)"
        case .duplicateSlug(let slug): "模型 slug “\(slug)” 已存在。"
        case .invalidSlug: "slug 只能包含小写字母、数字、点、下划线和连字符。"
        case .missingTemplate: "请选择一个自定义模型作为能力模板。"
        case .processFailed(let detail): detail
        case .syncTimedOut: "同步任务已启动，但等待完成超时。请到同步日志查看结果。"
        }
    }
}
