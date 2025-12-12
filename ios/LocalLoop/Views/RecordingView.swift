import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // Record button
                RecordButton(
                    isRecording: viewModel.isRecording,
                    action: viewModel.toggleRecording
                )

                // Duration
                if viewModel.isRecording {
                    Text(viewModel.formattedDuration)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.primary)

                    Text("\(viewModel.chunkCount) chunks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Upload status
                UploadStatusView(
                    pendingCount: viewModel.pendingUploadCount,
                    isUploading: viewModel.isUploading,
                    lastUploadTime: viewModel.lastUploadTime
                )
                .padding(.bottom, 40)
            }
            .navigationTitle("Local Loop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct UploadStatusView: View {
    let pendingCount: Int
    let isUploading: Bool
    let lastUploadTime: Date?

    var body: some View {
        VStack(spacing: 8) {
            if pendingCount > 0 {
                HStack {
                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "clock")
                    }
                    Text("\(pendingCount) pending upload")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            if let lastUpload = lastUploadTime {
                Text("Last upload: \(lastUpload.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    RecordingView()
}
