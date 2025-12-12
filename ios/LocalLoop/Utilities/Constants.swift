import Foundation

enum Constants {
    enum Recording {
        static let sampleRate: Double = 16000
        static let channels: UInt32 = 1
        static let bitRate: Int = 32000
        static let chunkDurationSeconds: TimeInterval = 600  // 10 minutes
        static let overlapDurationSeconds: TimeInterval = 5
        static let fileExtension = "m4a"
    }

    enum Upload {
        static let wifiOnlyDefault = true
        static let requireChargingDefault = false
        static let minimumBatteryLevel: Float = 0.5
        static let retryDelaySeconds: [TimeInterval] = [5, 15, 60, 300]  // Exponential backoff
    }

    enum Storage {
        static let localRetentionHours: Int = 24
    }
}
