import SwiftUI

struct ModelManagerView: View {
    @ObservedObject var modelManager = ModelManager.shared
    @Binding var selectedModel: WhisperModel
    @State private var downloadError: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(WhisperModel.allCases) { model in
                    ModelCard(
                        model: model,
                        isSelected: selectedModel == model,
                        isDownloaded: modelManager.isDownloaded(model),
                        downloadProgress: modelManager.downloadProgress[model],
                        onSelect: { selectedModel = model },
                        onDownload: { download(model) },
                        onDelete: { delete(model) }
                    )
                }
            }
            .padding()
        }
        .alert("Download Error", isPresented: .constant(downloadError != nil)) {
            Button("OK") { downloadError = nil }
        } message: {
            Text(downloadError ?? "")
        }
    }

    private func download(_ model: WhisperModel) {
        Task {
            do {
                try await modelManager.download(model)
            } catch {
                downloadError = error.localizedDescription
            }
        }
    }

    private func delete(_ model: WhisperModel) {
        try? modelManager.delete(model)
        if selectedModel == model {
            selectedModel = .base
        }
    }
}

struct ModelCard: View {
    let model: WhisperModel
    let isSelected: Bool
    let isDownloaded: Bool
    let downloadProgress: Double?
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected && isDownloaded ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected && isDownloaded ? .accentColor : Color(NSColor.secondaryLabelColor))
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label("\(model.fileSizeMB) MB", systemImage: "internaldrive")
                    speedLabel
                    accuracyLabel
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Action button
            if let progress = downloadProgress {
                VStack(spacing: 4) {
                    ProgressView(value: progress)
                        .frame(width: 60)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                }
            } else if isDownloaded {
                HStack(spacing: 4) {
                    if isSelected {
                        Text("In Use")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Use", action: onSelect)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            } else {
                Button("Download", action: onDownload)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected && isDownloaded ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected && isDownloaded ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    private var speedLabel: some View {
        HStack(spacing: 1) {
            Text("Speed:")
            ForEach(0..<5) { i in
                Image(systemName: i < model.speedRating ? "bolt.fill" : "bolt")
                    .foregroundColor(i < model.speedRating ? .yellow : Color(NSColor.tertiaryLabelColor))
            }
        }
    }

    private var accuracyLabel: some View {
        HStack(spacing: 1) {
            Text("Accuracy:")
            ForEach(0..<5) { i in
                Image(systemName: i < model.accuracyRating ? "star.fill" : "star")
                    .foregroundColor(i < model.accuracyRating ? .yellow : Color(NSColor.tertiaryLabelColor))
            }
        }
    }
}
