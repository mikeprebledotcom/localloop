import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(isRecording ? Color.red : Color.red.opacity(0.8))
                    .frame(width: 80, height: 80)

                if isRecording {
                    // Pulsing animation
                    Circle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .opacity(0.5)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }
}

#Preview {
    VStack(spacing: 40) {
        RecordButton(isRecording: false, action: {})
        RecordButton(isRecording: true, action: {})
    }
}
