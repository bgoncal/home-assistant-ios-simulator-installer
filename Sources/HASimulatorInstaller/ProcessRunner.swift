import Foundation

struct ProcessResult: Sendable {
    let status: Int32
    let output: String
    let error: String

    var succeeded: Bool { status == 0 }

    var lastErrorLine: String {
        (error + "\n" + output)
            .split(whereSeparator: \.isNewline)
            .last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map(String.init) ?? "Unknown error (\(status))"
    }
}

enum ProcessRunner {
    static func run(
        _ executable: String,
        _ arguments: [String],
        environment: [String: String] = [:],
        currentDirectory: URL? = nil,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws -> ProcessResult {
        let process = makeProcess(executable, arguments, environment: environment)
        process.currentDirectoryURL = currentDirectory
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        let output = PipeCollector(outputPipe.fileHandleForReading, onOutput: onOutput)
        let error = PipeCollector(errorPipe.fileHandleForReading, onOutput: onOutput)
        let handle = ProcessHandle(process)

        let result = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { process in
                    continuation.resume(returning: ProcessResult(
                        status: process.terminationStatus,
                        output: output.finish(),
                        error: error.finish()
                    ))
                }
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            handle.terminate()
        }
        try Task.checkCancellation()
        return result
    }

    static func start(
        _ executable: String,
        _ arguments: [String],
        environment: [String: String] = [:]
    ) throws -> Process {
        let process = makeProcess(executable, arguments, environment: environment)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        return process
    }

    private static func makeProcess(
        _ executable: String,
        _ arguments: [String],
        environment: [String: String]
    ) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
        return process
    }
}

private final class ProcessHandle: @unchecked Sendable {
    private let process: Process

    init(_ process: Process) {
        self.process = process
    }

    func terminate() {
        if process.isRunning {
            process.terminate()
        }
    }
}

private final class PipeCollector: @unchecked Sendable {
    private let handle: FileHandle
    private let onOutput: (@Sendable (String) -> Void)?
    private let lock = NSLock()
    private var data = Data()

    init(_ handle: FileHandle, onOutput: (@Sendable (String) -> Void)?) {
        self.handle = handle
        self.onOutput = onOutput
        handle.readabilityHandler = { [weak self] handle in
            self?.append(handle.availableData)
        }
    }

    func finish() -> String {
        handle.readabilityHandler = nil
        append(handle.readDataToEndOfFile())
        lock.lock()
        defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }

    private func append(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        lock.lock()
        data.append(chunk)
        lock.unlock()
        onOutput?(String(decoding: chunk, as: UTF8.self))
    }
}
