import SwiftUI
import UniformTypeIdentifiers

struct FileDropZoneView: View {
    let onFilesDropped: ([URL]) -> Void

    @State private var isDragTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isDragTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isDragTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                )

            VStack(spacing: 6) {
                Image(systemName: "waveform.badge.plus")
                    .font(.title2)
                    .foregroundColor(isDragTargeted ? .accentColor : Color(NSColor.secondaryLabelColor))
                Text("Drop audio/video file here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Choose File...") {
                    openFilePicker()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        }
        .frame(height: 80)
        .onDrop(of: [.audio, .movie, .fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
        }
        .animation(.easeInOut(duration: 0.15), value: isDragTargeted)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil),
                       url.isAudioFile {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if !urls.isEmpty {
                onFilesDropped(urls)
            }
        }
        return true
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio, .movie, .mp3, .wav, .aiff, .mpeg4Audio]
        panel.message = "Select an audio or video file to transcribe"

        if panel.runModal() == .OK, let url = panel.url {
            onFilesDropped([url])
        }
    }
}
