import SwiftUI

struct WaveformView: View {
    var level: Float
    var barCount: Int = 20
    var color: Color = .accentColor

    @State private var levels: [Float] = Array(repeating: 0, count: 20)
    @State private var phase: Double = 0

    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(barCount)
            let spacing: CGFloat = 2

            for i in 0..<barCount {
                let h = CGFloat(levels[i]) * size.height * 0.9 + 2
                let x = CGFloat(i) * barWidth + spacing / 2
                let y = (size.height - h) / 2
                let rect = CGRect(x: x, y: y, width: barWidth - spacing, height: h)
                let path = Path(roundedRect: rect, cornerRadius: 2)

                let alpha = 0.3 + 0.7 * Double(i) / Double(barCount)
                context.fill(path, with: .color(color.opacity(alpha)))
            }
        }
        .onChange(of: level) { newLevel in
            withAnimation(.linear(duration: 0.05)) {
                levels.removeFirst()
                levels.append(newLevel)
            }
        }
        .frame(height: 40)
    }
}

#Preview {
    WaveformView(level: 0.5)
        .frame(width: 200)
        .padding()
}
