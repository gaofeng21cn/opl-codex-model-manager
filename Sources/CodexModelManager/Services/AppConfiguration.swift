import Foundation

struct CatalogPaths: Equatable {
    let customSource: URL
    let mergedCatalog: URL
    let syncLog: URL
    let errorLog: URL
    let launchAgentPlist: URL
    let launchAgentLabel: String
    let backupDirectory: URL
}

struct AppConfiguration: Decodable {
    let customSourcePath: String
    let mergedCatalogPath: String
    let syncLogPath: String
    let errorLogPath: String
    let launchAgentPlistPath: String
    let launchAgentLabel: String
    let backupDirectoryPath: String

    static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent("CodexModelManager", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    static func load(
        from url: URL = defaultURL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws -> CatalogPaths {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AppError.configurationNotFound(url.path)
        }

        let configuration: AppConfiguration
        do {
            configuration = try JSONDecoder().decode(
                AppConfiguration.self,
                from: Data(contentsOf: url)
            )
        } catch let error as DecodingError {
            throw AppError.invalidConfiguration(decodingDetail(error))
        } catch {
            throw AppError.invalidConfiguration(error.localizedDescription)
        }

        let label = configuration.launchAgentLabel
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else {
            throw AppError.invalidConfiguration("launchAgentLabel 不能为空")
        }

        return CatalogPaths(
            customSource: try resolve(
                configuration.customSourcePath,
                field: "customSourcePath",
                homeDirectory: homeDirectory
            ),
            mergedCatalog: try resolve(
                configuration.mergedCatalogPath,
                field: "mergedCatalogPath",
                homeDirectory: homeDirectory
            ),
            syncLog: try resolve(
                configuration.syncLogPath,
                field: "syncLogPath",
                homeDirectory: homeDirectory
            ),
            errorLog: try resolve(
                configuration.errorLogPath,
                field: "errorLogPath",
                homeDirectory: homeDirectory
            ),
            launchAgentPlist: try resolve(
                configuration.launchAgentPlistPath,
                field: "launchAgentPlistPath",
                homeDirectory: homeDirectory
            ),
            launchAgentLabel: label,
            backupDirectory: try resolve(
                configuration.backupDirectoryPath,
                field: "backupDirectoryPath",
                homeDirectory: homeDirectory
            )
        )
    }

    private static func resolve(
        _ rawValue: String,
        field: String,
        homeDirectory: URL
    ) throws -> URL {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw AppError.invalidConfiguration("\(field) 不能为空")
        }

        let url: URL
        if value == "~" {
            url = homeDirectory
        } else if value.hasPrefix("~/") {
            url = homeDirectory.appendingPathComponent(String(value.dropFirst(2)))
        } else if NSString(string: value).isAbsolutePath {
            url = URL(fileURLWithPath: value)
        } else {
            throw AppError.invalidConfiguration("\(field) 必须使用绝对路径或 ~/ 路径")
        }

        let standardized = url.standardizedFileURL
        guard standardized.path != "/" else {
            throw AppError.invalidConfiguration("\(field) 不能指向文件系统根目录")
        }
        return standardized
    }

    private static func decodingDetail(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _):
            return "缺少必填字段 \(key.stringValue)"
        case .typeMismatch(_, let context),
             .valueNotFound(_, let context),
             .dataCorrupted(let context):
            return context.debugDescription
        @unknown default:
            return error.localizedDescription
        }
    }
}
