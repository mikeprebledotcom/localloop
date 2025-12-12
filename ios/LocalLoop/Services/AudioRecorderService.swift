import AVFoundation
import UIKit

class AudioRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentDuration: TimeInterval = 0

    private var activeRecorder: AVAudioRecorder?
    private var pendingRecorder: AVAudioRecorder?
    private var rotationTimer: Timer?
    private var durationTimer: Timer?
    private var sessionStartTime: Date?

    private let fileManager = FileManager.default

    // MARK: - Audio Session

    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers]
        )

        try session.setActive(true)

        // Register for interruption notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            pauseRecording()
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumeRecording()
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Recorder Creation

    private func createRecorder(filename: String) -> AVAudioRecorder? {
        let url = getChunkURL(filename: filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Constants.Recording.sampleRate,
            AVNumberOfChannelsKey: Constants.Recording.channels,
            AVEncoderBitRateKey: Constants.Recording.bitRate,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.prepareToRecord()
            return recorder
        } catch {
            print("Failed to create recorder: \(error)")
            return nil
        }
    }

    private func getChunkURL(filename: String) -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let chunksFolder = documentsPath.appendingPathComponent("Chunks", isDirectory: true)

        // Create folder if needed
        try? fileManager.createDirectory(at: chunksFolder, withIntermediateDirectories: true)

        return chunksFolder.appendingPathComponent(filename)
    }

    private func generateChunkFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return "\(formatter.string(from: Date())).\(Constants.Recording.fileExtension)"
    }

    // MARK: - Recording Control

    func startRecording() {
        guard !isRecording else { return }

        do {
            try configureAudioSession()
        } catch {
            print("Failed to configure audio session: \(error)")
            return
        }

        sessionStartTime = Date()
        activeRecorder = createRecorder(filename: generateChunkFilename())
        activeRecorder?.record()
        isRecording = true

        startDurationTimer()
        scheduleNextRotation()
    }

    func stopRecording() {
        guard isRecording else { return }

        rotationTimer?.invalidate()
        rotationTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil

        // Stop both recorders
        activeRecorder?.stop()
        pendingRecorder?.stop()

        // Finalize any active chunks
        if let url = activeRecorder?.url {
            ChunkManager.shared.finalizeChunk(at: url)
        }

        activeRecorder = nil
        pendingRecorder = nil
        isRecording = false
        sessionStartTime = nil
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let startTime = self.sessionStartTime else { return }
            self.currentDuration = Date().timeIntervalSince(startTime)
        }
    }

    // MARK: - Chunk Rotation

    private func scheduleNextRotation() {
        let chunkDuration = Constants.Recording.chunkDurationSeconds
        let overlapDuration = Constants.Recording.overlapDurationSeconds

        // Start overlap recorder 5 seconds before chunk ends
        let overlapStartDelay = chunkDuration - overlapDuration

        rotationTimer = Timer.scheduledTimer(withTimeInterval: overlapStartDelay, repeats: false) { [weak self] _ in
            self?.startOverlapRecorder()

            // Schedule the actual rotation 5 seconds later
            DispatchQueue.main.asyncAfter(deadline: .now() + overlapDuration) {
                self?.completeRotation()
            }
        }
    }

    private func startOverlapRecorder() {
        pendingRecorder = createRecorder(filename: generateChunkFilename())
        pendingRecorder?.record()
    }

    private func completeRotation() {
        // Protect this operation from being killed
        let taskID = UIApplication.shared.beginBackgroundTask {
            // Cleanup if we run out of time
        }

        // Stop and finalize the old recorder
        activeRecorder?.stop()
        if let url = activeRecorder?.url {
            ChunkManager.shared.finalizeChunk(at: url)
        }

        // Promote pending to active
        activeRecorder = pendingRecorder
        pendingRecorder = nil

        // Schedule next rotation
        scheduleNextRotation()

        UIApplication.shared.endBackgroundTask(taskID)
    }

    func pauseRecording() {
        activeRecorder?.pause()
        pendingRecorder?.pause()
        rotationTimer?.invalidate()
    }

    func resumeRecording() {
        activeRecorder?.record()
        pendingRecorder?.record()
        // Recalculate rotation timing based on current recorder time
        scheduleNextRotation()
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
            // Notify user that recording stopped unexpectedly
            if isRecording {
                NotificationService.shared.notifyRecordingStopped(at: Date())
            }
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Encode error: \(error?.localizedDescription ?? "unknown")")
    }
}
