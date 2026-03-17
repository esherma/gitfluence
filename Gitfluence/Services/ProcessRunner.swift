import Foundation

enum ProcessRunner {

    enum Error: Swift.Error, LocalizedError {
        case launchFailed(Swift.Error)
        case nonZeroExit(Int32, stderr: String)

        var errorDescription: String? {
            switch self {
            case .launchFailed(let e):        return "Failed to launch process: \(e.localizedDescription)"
            case .nonZeroExit(let code, let stderr): return "Process exited \(code): \(stderr)"
            }
        }
    }

    // Wraps Process + Pipe in @unchecked Sendable so they can cross the
    // concurrency boundary inside withCheckedThrowingContinuation.
    private final class Box: @unchecked Sendable {
        let process = Process()
        let stdout   = Pipe()
        let stderr   = Pipe()
    }

    // Resolve tools to absolute paths at startup so we don't depend on
    // the launcher's PATH (Xcode-launched apps have a stripped environment).
    static let gitPath: String = resolveExecutable("git")
    static let ghPath:  String = resolveExecutable("gh")

    private static func resolveExecutable(_ name: String) -> String {
        let candidates: [String]
        switch name {
        case "git":
            candidates = ["/opt/homebrew/bin/git", "/usr/local/bin/git", "/usr/bin/git"]
        case "gh":
            candidates = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh"]
        default:
            candidates = ["/usr/bin/\(name)"]
        }
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
            ?? "/usr/bin/\(name)"
    }

    /// Run a command, returning stdout. First element of `args` must be a
    /// tool name ("git", "gh") — it will be resolved to an absolute path.
    /// Throws `ProcessRunner.Error` on non-zero exit or launch failure.
    static func run(
        _ args: [String],
        cwd: URL? = nil,
        requireSuccess: Bool = true
    ) async throws -> String {
        guard !args.isEmpty else { return "" }

        let box = Box()
        // Resolve first arg to absolute path; fall back to /usr/bin/env lookup
        let execPath: String
        switch args[0] {
        case "git": execPath = gitPath
        case "gh":  execPath = ghPath
        default:    execPath = "/usr/bin/env"
        }
        box.process.executableURL  = URL(fileURLWithPath: execPath)
        box.process.arguments      = args[0] == "git" || args[0] == "gh"
                                        ? Array(args.dropFirst())
                                        : args
        box.process.standardOutput = box.stdout
        box.process.standardError  = box.stderr
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        box.process.environment = env
        if let cwd { box.process.currentDirectoryURL = cwd }

        return try await withCheckedThrowingContinuation { continuation in
            box.process.terminationHandler = { _ in
                let outData  = box.stdout.fileHandleForReading.readDataToEndOfFile()
                let errData  = box.stderr.fileHandleForReading.readDataToEndOfFile()
                let outStr   = String(data: outData, encoding: .utf8) ?? ""
                let errStr   = String(data: errData, encoding: .utf8) ?? ""

                if requireSuccess && box.process.terminationStatus != 0 {
                    continuation.resume(throwing: Error.nonZeroExit(box.process.terminationStatus, stderr: errStr))
                } else {
                    continuation.resume(returning: outStr)
                }
            }
            do {
                try box.process.run()
            } catch {
                continuation.resume(throwing: Error.launchFailed(error))
            }
        }
    }

    /// Convenience: run without throwing on non-zero exit, returns empty string on failure.
    static func runSilent(_ args: [String], cwd: URL? = nil) async -> String {
        (try? await run(args, cwd: cwd, requireSuccess: false)) ?? ""
    }
}
