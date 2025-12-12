import SwiftUI

struct StatusIndicator: View {
    let isActive: Bool
    let color: Color

    var body: some View {
        Circle()
            .fill(isActive ? color : color.opacity(0.3))
            .frame(width: 12, height: 12)
            .overlay {
                if isActive {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .scaleEffect(1.5)
                        .opacity(0)
                        .animation(
                            .easeOut(duration: 1)
                            .repeatForever(autoreverses: false),
                            value: isActive
                        )
                }
            }
    }
}

#Preview {
    HStack(spacing: 20) {
        StatusIndicator(isActive: false, color: .red)
        StatusIndicator(isActive: true, color: .red)
        StatusIndicator(isActive: true, color: .green)
    }
}
