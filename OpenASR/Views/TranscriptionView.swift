import SwiftUI

struct TranscriptionView: View {
    let segments: [TranscriptionSegment]
    var showTimestamps: Bool = false
    var isLive: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if segments.isEmpty {
                        emptyState
                    } else {
                        ForEach(segments) { seg in
                            segmentRow(seg)
                                .id(seg.id)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: segments.count) { _ in
                if isLive, let last = segments.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func segmentRow(_ seg: TranscriptionSegment) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if showTimestamps {
                Text(seg.formattedTimestamp)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
            Text(seg.text.trimmingCharacters(in: .whitespaces))
                .font(.body)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(isLive ? "Start recording to see transcription" : "No transcription yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
