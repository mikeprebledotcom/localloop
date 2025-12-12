import Foundation

struct Chunk: Codable, Identifiable {
    let id: UUID
    let filename: String
    let localURL: URL
    let createdAt: Date
    var status: ChunkStatus
    var driveFileId: String?
    var uploadedAt: Date?
    var lastError: String?
    var retryCount: Int = 0
}

enum ChunkStatus: String, Codable {
    case recording
    case pendingUpload
    case uploading
    case uploaded
    case failed
}
