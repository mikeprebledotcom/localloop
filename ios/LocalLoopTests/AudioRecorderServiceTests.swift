import XCTest
@testable import LocalLoop

final class AudioRecorderServiceTests: XCTestCase {
    func testChunkFilenameFormat() {
        // Test that the filename format is correct
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let filename = "\(formatter.string(from: Date())).\(Constants.Recording.fileExtension)"

        XCTAssertTrue(filename.hasSuffix(".m4a"))
        XCTAssertTrue(filename.contains("_"))
    }

    func testConstantsValues() {
        XCTAssertEqual(Constants.Recording.sampleRate, 16000)
        XCTAssertEqual(Constants.Recording.channels, 1)
        XCTAssertEqual(Constants.Recording.chunkDurationSeconds, 600)
        XCTAssertEqual(Constants.Recording.overlapDurationSeconds, 5)
    }
}
