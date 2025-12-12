import Foundation
import Combine

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var formattedDuration = "00:00:00"
    @Published var chunkCount = 0
    @Published var pendingUploadCount = 0
    @Published var isUploading = false
    @Published var lastUploadTime: Date?

    private let audioService = AudioRecorderService()
    private let chunkManager = ChunkManager.shared
    private let uploadQueue = UploadQueue.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        audioService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)

        audioService.$currentDuration
            .receive(on: DispatchQueue.main)
            .map { duration in
                let hours = Int(duration) / 3600
                let minutes = Int(duration) / 60 % 60
                let seconds = Int(duration) % 60
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            }
            .assign(to: &$formattedDuration)

        chunkManager.$pendingChunks
            .receive(on: DispatchQueue.main)
            .map { $0.count }
            .assign(to: &$pendingUploadCount)

        uploadQueue.$isUploading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isUploading)

        // Calculate chunk count from session duration
        audioService.$currentDuration
            .receive(on: DispatchQueue.main)
            .map { duration in
                Int(duration / Constants.Recording.chunkDurationSeconds) + 1
            }
            .assign(to: &$chunkCount)
    }

    func toggleRecording() {
        if isRecording {
            audioService.stopRecording()
        } else {
            audioService.startRecording()
        }
    }
}
