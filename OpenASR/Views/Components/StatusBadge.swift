import SwiftUI

struct StatusBadge: View {
    enum Status {
        case idle
        case recording
        case processing
        case error

        var label: String {
            switch self {
            case .idle: return "Idle"
            case .recording: return "Recording"
            case .processing: return "Processing"
            case .error: return "Error"
            }
        }

        var color: Color {
            switch self {
            case .idle: return .secondary
            case .recording: return .red
            case .processing: return .orange
            case .error: return .red
            }
        }

        var systemImage: String {
            switch self {
            case .idle: return "circle"
            case .recording: return "record.circle"
            case .processing: return "gearshape"
            case .error: return "exclamationmark.circle"
            }
        }
    }

    let status: Status

    var body: some View {
        HStack(spacing: 4) {
            if status == .recording {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .modifier(PulseModifier())
            } else {
                Image(systemName: status.systemImage)
                    .foregroundStyle(status.color)
                    .imageScale(.small)
            }
            Text(status.label)
                .font(.caption)
                .foregroundStyle(status.color)
        }
    }
}

struct PulseModifier: ViewModifier {
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(pulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
    }
}
