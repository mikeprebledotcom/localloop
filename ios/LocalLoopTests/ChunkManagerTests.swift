import XCTest
@testable import LocalLoop

final class ChunkManagerTests: XCTestCase {
    func testChunkStatusValues() {
        // Test chunk status enum
        XCTAssertEqual(ChunkStatus.recording.rawValue, "recording")
        XCTAssertEqual(ChunkStatus.pendingUpload.rawValue, "pendingUpload")
        XCTAssertEqual(ChunkStatus.uploading.rawValue, "uploading")
        XCTAssertEqual(ChunkStatus.uploaded.rawValue, "uploaded")
        XCTAssertEqual(ChunkStatus.failed.rawValue, "failed")
    }

    func testChunkCodable() throws {
        // Test that Chunk can be encoded and decoded
        let chunk = Chunk(
            id: UUID(),
            filename: "test.m4a",
            localURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            createdAt: Date(),
            status: .pendingUpload
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(chunk)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Chunk.self, from: data)

        XCTAssertEqual(decoded.id, chunk.id)
        XCTAssertEqual(decoded.filename, chunk.filename)
        XCTAssertEqual(decoded.status, chunk.status)
    }
}
