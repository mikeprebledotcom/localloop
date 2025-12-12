import Foundation
import UIKit
import Network

class UploadQueue: ObservableObject {
    static let shared = UploadQueue()

    @Published var isUploading = false
    @Published var currentUpload: Chunk?
    @Published var queueCount: Int = 0

    private var queue: [Chunk] = []
    private let networkMonitor = NWPathMonitor()
    private var isWiFiConnected = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private init() {
        setupNetworkMonitor()
        loadQueueFromDisk()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isWiFiConnected = (path.status == .satisfied && !path.isExpensive)

            if self?.isWiFiConnected == true && self?.shouldUpload() == true {
                Task { await self?.processQueue() }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    // MARK: - Queue Management

    func enqueue(_ chunk: Chunk) {
        queue.append(chunk)
        queueCount = queue.count
        saveQueueToDisk()

        if shouldUpload() {
            Task { await processQueue() }
        }
    }

    private func shouldUpload() -> Bool {
        let settings = SettingsViewModel.shared

        // Check Wi-Fi requirement
        if settings.wifiOnly && !isWiFiConnected {
            return false
        }

        // Check battery requirement
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let isCharging = UIDevice.current.batteryState == .charging ||
                         UIDevice.current.batteryState == .full

        if settings.requireCharging && !isCharging && batteryLevel < Constants.Upload.minimumBatteryLevel {
            return false
        }

        return true
    }

    // MARK: - Upload Processing

    func processQueue() async {
        guard !isUploading, !queue.isEmpty else { return }
        guard GoogleDriveService.shared.isSignedIn else { return }

        // Start background task
        await MainActor.run {
            backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                self?.endBackgroundTask()
            }
        }

        await MainActor.run {
            isUploading = true
        }

        while !queue.isEmpty && shouldUpload() {
            let chunk = queue[0]
            await MainActor.run {
                currentUpload = chunk
            }

            do {
                let fileId = try await GoogleDriveService.shared.uploadFile(
                    at: chunk.localURL,
                    filename: chunk.filename
                )

                // Success - remove from queue and mark uploaded
                queue.removeFirst()
                await MainActor.run {
                    queueCount = queue.count
                }
                ChunkManager.shared.markUploaded(chunk, driveFileId: fileId)
                saveQueueToDisk()

            } catch {
                // Failure - apply retry logic
                handleUploadFailure(chunk: chunk, error: error)
                break  // Stop processing on failure
            }
        }

        await MainActor.run {
            isUploading = false
            currentUpload = nil
        }
        endBackgroundTask()
    }

    private func handleUploadFailure(chunk: Chunk, error: Error) {
        ChunkManager.shared.markFailed(chunk, error: error)

        // Move failed chunk to end of queue
        if let index = queue.firstIndex(where: { $0.id == chunk.id }) {
            var failedChunk = queue.remove(at: index)
            failedChunk.retryCount += 1

            // Only requeue if under retry limit
            if failedChunk.retryCount < Constants.Upload.retryDelaySeconds.count {
                queue.append(failedChunk)

                // Schedule retry
                let delay = Constants.Upload.retryDelaySeconds[failedChunk.retryCount]
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    Task { await self?.processQueue() }
                }
            }
        }

        saveQueueToDisk()
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    // MARK: - Persistence

    private func saveQueueToDisk() {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: "uploadQueue")
        }
    }

    private func loadQueueFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "uploadQueue"),
           let loaded = try? JSONDecoder().decode([Chunk].self, from: data) {
            queue = loaded
            queueCount = queue.count
        }
    }
}
