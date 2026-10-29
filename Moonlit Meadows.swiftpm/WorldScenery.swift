import SwiftUI

// MARK: - Time of day

/// Sky colors that follow the real clock.
struct SkyMood {
    let colors: [Color]
    let isNight: Bool

    init(_ date: Date) {
        self.init(hour: Calendar.current.component(.hour, from: date))
    }

    init(hour: Int) {
        switch hour {
        case 5..<8:
            colors = [Palette.peach, Palette.blush]
            isNight = false
        case 8..<17:
            colors = [Palette.sky, Palette.lavender]
            isNight = false
        case 17..<20:
            colors = [Palette.lavender, Palette.peach]
            isNight = false
        default:
            colors = [Color(red: 0.30, green: 0.27, blue: 0.52), Color(red: 0.60, green: 0.48, blue: 0.75)]
            isNight = true
        }
    }
}

// MARK: - Sky

struct SkyView: View {
    let mood: SkyMood
    let weather: Weather
    let t: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: weather == .cloudy || weather == .rainy
                        ? mood.colors.map { $0.mix(with: .gray, by: 0.2) }
                        : mood.colors,
                    startPoint: .top,
                    endPoint: .bottom
                )

                if mood.isNight {
                    ForEach(0..<30, id: \.self) { index in
                        Circle()
                            .fill(.white)
                            .frame(width: 2.5, height: 2.5)
                            .opacity(0.3 + 0.7 * abs(sin(t * 0.7 + Double(index))))
                            .position(x: hash01(index, 1) * size.width, y: hash01(index, 2) * size.height * 0.45)
                    }
                    Circle()
                        .fill(Palette.cream)
                        .frame(width: size.height * 0.1, height: size.height * 0.1)
                        .shadow(color: Palette.butter, radius: 16)
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(mood.colors[0])
                                .frame(width: size.height * 0.08, height: size.height * 0.08)
                                .offset(x: size.height * 0.025, y: -size.height * 0.01)
                        }
                        .position(x: size.width * 0.82, y: size.height * 0.12)
                } else if weather != .rainy {
                    Circle()
                        .fill(Palette.butter)
                        .frame(width: size.height * 0.12, height: size.height * 0.12)
                        .shadow(color: Palette.butter, radius: 24)
                        .position(x: size.width * 0.82, y: size.height * 0.12)
                }

                let cloudCount = weather == .cloudy || weather == .rainy ? 6 : 3
                ForEach(0..<cloudCount, id: \.self) { index in
                    let span = size.width + 200
                    let speed = 5 + Double(index % 3) * 3
                    let x = (t * speed + Double(index) * span / Double(cloudCount))
                        .truncatingRemainder(dividingBy: span) - 100
                    Cloud(isGray: weather == .rainy)
                        .frame(width: 110, height: 40)
                        .scaleEffect(0.7 + 0.4 * hash01(index, 3))
                        .position(x: x, y: size.height * (0.07 + 0.08 * Double(index % 3)))
                        .opacity(mood.isNight ? 0.5 : 1)
                }
            }
        }
    }
}

private struct Cloud: View {
    let isGray: Bool

    var body: some View {
        ZStack {
            Capsule()
                .frame(height: 26)
                .offset(y: 7)
            Circle()
                .frame(width: 36, height: 36)
                .offset(x: -18, y: -3)
            Circle()
                .frame(width: 40, height: 40)
                .offset(x: 12, y: -7)
        }
        .foregroundStyle(isGray ? Color(white: 0.92) : .white.opacity(0.92))
    }
}

// MARK: - Land

/// Rolling hills: a far lavender-green ridge and the near meadow.
struct HillsView: View {
    var body: some View {
        Canvas { context, size in
            var far = Path()
            far.move(to: CGPoint(x: 0, y: size.height * 0.46))
            far.addQuadCurve(to: CGPoint(x: size.width * 0.45, y: size.height * 0.42),
                             control: CGPoint(x: size.width * 0.22, y: size.height * 0.32))
            far.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.40),
                             control: CGPoint(x: size.width * 0.75, y: size.height * 0.30))
            far.addLine(to: CGPoint(x: size.width, y: size.height))
            far.addLine(to: CGPoint(x: 0, y: size.height))
            far.closeSubpath()
            context.fill(far, with: .color(Palette.farHill))

            var near = Path()
            near.move(to: CGPoint(x: 0, y: size.height * 0.56))
            near.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.52),
                              control: CGPoint(x: size.width * 0.5, y: size.height * 0.46))
            near.addLine(to: CGPoint(x: size.width, y: size.height))
            near.addLine(to: CGPoint(x: 0, y: size.height))
            near.closeSubpath()
            context.fill(near, with: .linearGradient(
                Gradient(colors: [Palette.meadow, Color(red: 0.66, green: 0.87, blue: 0.70)]),
                startPoint: CGPoint(x: 0, y: size.height * 0.5),
                endPoint: CGPoint(x: 0, y: size.height)
            ))

            // Little grass tufts and flowers dotted over the meadow.
            for index in 0..<40 {
                let x = hash01(index, 11) * size.width
                let y = size.height * (0.58 + 0.4 * hash01(index, 12))
                let dot = CGRect(x: x, y: y, width: 5, height: 5)
                let colors = [Palette.petal, .white, Palette.butter, Palette.lavender]
                context.fill(Path(ellipseIn: dot), with: .color(colors[index % colors.count].opacity(0.9)))
            }

            // A winding path toward the cottage.
            var trail = Path()
            trail.move(to: CGPoint(x: size.width * 0.58, y: size.height))
            trail.addCurve(to: CGPoint(x: size.width * 0.74, y: size.height * 0.6),
                           control1: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                           control2: CGPoint(x: size.width * 0.8, y: size.height * 0.75))
            context.stroke(trail, with: .color(Palette.cream.opacity(0.85)),
                           style: StrokeStyle(lineWidth: size.height * 0.05, lineCap: .round))
        }
    }
}

/// A cherry blossom tree that sways a little.
struct BlossomTree: View {
    let height: CGFloat
    let t: Double
    var phase: Double = 0

    var body: some View {
        let sway = sin(t * 0.9 + phase) * 2

        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Palette.bark)
                .frame(width: height * 0.12, height: height * 0.5)
            ZStack {
                Circle().frame(width: height * 0.5, height: height * 0.5).offset(x: -height * 0.18, y: height * 0.06)
                Circle().frame(width: height * 0.55, height: height * 0.55).offset(x: height * 0.16, y: height * 0.04)
                Circle().frame(width: height * 0.6, height: height * 0.6).offset(y: -height * 0.12)
            }
            .foregroundStyle(Palette.petal.gradient)
            .overlay {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(.white.opacity(0.7))
                        .frame(width: height * 0.05, height: height * 0.05)
                        .offset(x: (hash01(index, phase) - 0.5) * height * 0.6, y: (hash01(index, phase + 1) - 0.5) * height * 0.45)
                }
            }
            .rotationEffect(.degrees(sway), anchor: .bottom)
            .offset(y: -height * 0.38)
        }
        .frame(height: height)
    }
}

/// The bunnies' cottage, with windows that glow at night.
struct Cottage: View {
    let width: CGFloat
    let isNight: Bool

    var body: some View {
        let w = width
        let glow = isNight ? Palette.butter : Palette.sky

        VStack(spacing: -w * 0.02) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Palette.bark)
                    .frame(width: w * 0.1, height: w * 0.22)
                    .offset(x: -w * 0.2, y: w * 0.02)
                Triangle()
                    .fill(Palette.rose.gradient)
                    .frame(width: w * 1.05, height: w * 0.45)
                    .overlay(alignment: .center) {
                        Circle()
                            .fill(glow)
                            .frame(width: w * 0.13, height: w * 0.13)
                            .offset(y: w * 0.06)
                    }
            }
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(Palette.cream)
                HStack(spacing: w * 0.12) {
                    window(glow: glow, w: w)
                    UnevenRoundedRectangle(topLeadingRadius: w * 0.1, topTrailingRadius: w * 0.1)
                        .fill(Palette.bark)
                        .frame(width: w * 0.18, height: w * 0.3)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    window(glow: glow, w: w)
                }
            }
            .frame(width: w * 0.86, height: w * 0.48)
        }
        .shadow(color: isNight ? Palette.butter.opacity(0.5) : Palette.cocoa.opacity(0.15), radius: isNight ? 14 : 6, y: 3)
    }

    private func window(glow: Color, w: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: w * 0.02)
            .fill(glow)
            .frame(width: w * 0.16, height: w * 0.14)
            .overlay {
                Rectangle().fill(Palette.cream).frame(width: w * 0.015)
                Rectangle().fill(Palette.cream).frame(height: w * 0.015)
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Palette.petal)
                    .frame(width: w * 0.2, height: w * 0.035)
                    .offset(y: w * 0.02)
            }
    }
}

/// A miniature view of the farm plots, so you can watch crops grow from the top screen.
struct FarmField: View {
    let plots: [Plot]
    let t: Double

    var body: some View {
        GeometryReader { proxy in
            let columns = 4
            let rows = max(Int(ceil(Double(plots.count) / Double(columns))), 1)
            let cell = min(proxy.size.width / CGFloat(columns), proxy.size.height / CGFloat(rows))

            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<columns, id: \.self) { column in
                            let index = row * columns + column
                            if index < plots.count {
                                MiniPlot(plot: plots[index], size: cell, t: t, phase: Double(index))
                            } else {
                                Color.clear.frame(width: cell, height: cell)
                            }
                        }
                    }
                }
            }
            .padding(cell * 0.08)
            .background(Palette.soil, in: .rect(cornerRadius: cell * 0.25))
            .overlay {
                RoundedRectangle(cornerRadius: cell * 0.25)
                    .strokeBorder(Palette.bark.opacity(0.6), style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct MiniPlot: View {
    let plot: Plot
    let size: CGFloat
    let t: Double
    let phase: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(Palette.darkSoil)
                .padding(size * 0.07)
            if let id = plot.cropID {
                if plot.isReady {
                    ItemIcon(itemID: id, size: size * 0.55)
                        .offset(y: -abs(sin(t * 3 + phase)) * size * 0.08)
                } else {
                    Text(plot.progress < 0.5 ? "🌱" : "🌿")
                        .font(.system(size: size * (0.3 + 0.25 * plot.progress)))
                        .rotationEffect(.degrees(sin(t * 1.4 + phase) * 5), anchor: .bottom)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Weather

/// Rain streaks or drifting petals over the whole world.
struct WeatherOverlay: View {
    let weather: Weather
    let t: Double

    var body: some View {
        Canvas { context, size in
            switch weather {
            case .rainy:
                for index in 0..<70 {
                    let speed = 260 + 120 * hash01(index, 4)
                    let x = hash01(index, 5) * size.width
                    let y = (t * speed + hash01(index, 6) * size.height).truncatingRemainder(dividingBy: size.height + 20) - 10
                    var drop = Path()
                    drop.move(to: CGPoint(x: x, y: y))
                    drop.addLine(to: CGPoint(x: x - 2, y: y + 10))
                    context.stroke(drop, with: .color(Palette.sky.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
            case .breezy:
                for index in 0..<24 {
                    let speed = 30 + 30 * hash01(index, 8)
                    let x = (t * speed + hash01(index, 9) * size.width).truncatingRemainder(dividingBy: size.width + 20) - 10
                    let y = hash01(index, 10) * size.height + sin(t * 1.5 + Double(index)) * 12
                    let petal = CGRect(x: x, y: y, width: 7, height: 5)
                    context.fill(Path(ellipseIn: petal), with: .color(Palette.petal))
                }
            case .sunny, .cloudy:
                break
            }
        }
        .allowsHitTesting(false)
    }
}
