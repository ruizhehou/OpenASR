import SwiftUI

struct CopyButton: View {
    let text: String
    var label: String = "Copy"

    @State private var copied = false

    var body: some View {
        Button {
            ClipboardService.copy(text)
            withAnimation {
                copied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { copied = false }
            }
        } label: {
            Label(copied ? "Copied!" : label,
                  systemImage: copied ? "checkmark" : "doc.on.doc")
        }
        .disabled(text.isEmpty)
    }
}
