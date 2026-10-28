import SwiftUI

struct AndroidLogo: View {
    var body: some View {
        Canvas { context, size in
            let unit = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - unit) / 2, y: (size.height - unit) / 2)
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: origin.x + x * unit, y: origin.y + y * unit)
            }

            var head = Path()
            head.addArc(center: point(0.5, 0.82), radius: 0.48 * unit, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            head.closeSubpath()
            context.fill(head, with: .foreground)

            var antennae = Path()
            antennae.move(to: point(0.28, 0.42))
            antennae.addLine(to: point(0.16, 0.2))
            antennae.move(to: point(0.72, 0.42))
            antennae.addLine(to: point(0.84, 0.2))
            context.stroke(antennae, with: .foreground, style: StrokeStyle(lineWidth: 0.07 * unit, lineCap: .round))

            context.blendMode = .destinationOut
            for x in [0.33, 0.67] {
                let eye = CGRect(x: origin.x + (x - 0.05) * unit, y: origin.y + 0.57 * unit, width: 0.1 * unit, height: 0.1 * unit)
                context.fill(Path(ellipseIn: eye), with: .color(.black))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Android")
    }
}

#Preview {
    HStack(spacing: 20) {
        AndroidLogo().frame(width: 14, height: 14)
        AndroidLogo().frame(width: 64, height: 64).foregroundStyle(.green)
    }
    .padding()
}
