import CodexModelCore
import Darwin
import Foundation

do {
    let arguments = CommandLine.arguments
    let configurationURL: URL
    if let index = arguments.firstIndex(of: "--config"), arguments.indices.contains(index + 1) {
        configurationURL = URL(fileURLWithPath: arguments[index + 1])
    } else {
        configurationURL = AppConfiguration.defaultURL
    }
    let paths = try AppConfiguration.load(from: configurationURL)
    let service = CatalogSyncService(paths: paths)
    try service.clearErrorLog()
    let result = try service.sync()
    FileHandle.standardOutput.write(result.recordData + Data([0x0A]))
} catch {
    FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
    exit(EXIT_FAILURE)
}
