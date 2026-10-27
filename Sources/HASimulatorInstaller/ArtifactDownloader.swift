import Foundation

final class ArtifactDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let destination: URL
    private let expectedSize: Int
    private let progress: @Sendable (Double) -> Void
    private let lock = NSLock()
    private var continuation: CheckedContinuation<URL, Error>?
    private var failure: Error?

    private init(destination: URL, expectedSize: Int, progress: @escaping @Sendable (Double) -> Void) {
        self.destination = destination
        self.expectedSize = expectedSize
        self.progress = progress
    }

    static func download(
        _ request: URLRequest,
        to destination: URL,
        expectedSize: Int,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let downloader = ArtifactDownloader(destination: destination, expectedSize: expectedSize, progress: progress)
        let session = URLSession(configuration: .default, delegate: downloader, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }

        let task = session.downloadTask(with: request)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                downloader.lock.withLock { downloader.continuation = continuation }
                task.resume()
            }
        } onCancel: {
            task.cancel()
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard request.url?.host != "api.github.com" else { return request }
        var redirected = request
        redirected.setValue(nil, forHTTPHeaderField: "Authorization")
        return redirected
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let total = totalBytesExpectedToWrite > 0 ? Double(totalBytesExpectedToWrite) : Double(expectedSize)
        guard total > 0 else { return }
        progress(min(Double(totalBytesWritten) / total, 1))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let message = status == 410
                ? "This build has expired on GitHub. Pick a newer one."
                : "The download failed (\(status))."
            lock.withLock { failure = InstallerError(message) }
            return
        }
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            lock.withLock { failure = error }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let (continuation, failure) = lock.withLock {
            let pending = (self.continuation, error ?? self.failure)
            self.continuation = nil
            return pending
        }
        if let failure {
            continuation?.resume(throwing: failure)
        } else {
            continuation?.resume(returning: destination)
        }
    }
}
