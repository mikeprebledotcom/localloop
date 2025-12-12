import Foundation

class ChunkManager: ObservableObject {
    static let shared = ChunkManager()

    @Published var pendingChunks: [Chunk] = []
    @Published var uploadedChunks: [Chunk] = []

    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard

    private init() {
        loadPersistedChunks()
    }

    // MARK: - Chunk Lifecycle

    func finalizeChunk(at url: URL) {
        let chunk = Chunk(
            id: UUID(),
            filename: url.lastPathComponent,
            localURL: url,
            createdAt: Date(),
            status: .pendingUpload
        )

        pendingChunks.append(chunk)
        persistChunks()

        // Notify upload queue
        UploadQueue.shared.enqueue(chunk)
    }

    func markUploaded(_ chunk: Chunk, driveFileId: String) {
        var updatedChunk = chunk
        updatedChunk.status = .uploaded
        updatedChunk.driveFileId = driveFileId
        updatedChunk.uploadedAt = Date()

        pendingChunks.removeAll { $0.id == chunk.id }
        uploadedChunks.append(updatedChunk)
        persistChunks()

        // Schedule local file deletion after retention period
        scheduleLocalDeletion(for: updatedChunk)
    }

    func markFailed(_ chunk: Chunk, error: Error) {
        if let index = pendingChunks.firstIndex(where: { $0.id == chunk.id }) {
            pendingChunks[index].status = .failed
            pendingChunks[index].lastError = error.localizedDescription
            pendingChunks[index].retryCount += 1
        }
        persistChunks()
    }

    // MARK: - Persistence

    private func persistChunks() {
        let encoder = JSONEncoder()
        if let pendingData = try? encoder.encode(pendingChunks) {
            userDefaults.set(pendingData, forKey: "pendingChunks")
        }
        if let uploadedData = try? encoder.encode(uploadedChunks) {
            userDefaults.set(uploadedData, forKey: "uploadedChunks")
        }
    }

    private func loadPersistedChunks() {
        let decoder = JSONDecoder()
        if let pendingData = userDefaults.data(forKey: "pendingChunks"),
           let pending = try? decoder.decode([Chunk].self, from: pendingData) {
            pendingChunks = pending
        }
        if let uploadedData = userDefaults.data(forKey: "uploadedChunks"),
           let uploaded = try? decoder.decode([Chunk].self, from: uploadedData) {
            uploadedChunks = uploaded
        }
    }

    // MARK: - Cleanup

    private func scheduleLocalDeletion(for chunk: Chunk) {
        let retentionInterval = TimeInterval(Constants.Storage.localRetentionHours * 3600)

        DispatchQueue.main.asyncAfter(deadline: .now() + retentionInterval) { [weak self] in
            self?.deleteLocalFile(for: chunk)
        }
    }

    private func deleteLocalFile(for chunk: Chunk) {
        try? fileManager.removeItem(at: chunk.localURL)
    }
}
