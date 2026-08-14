import Charts
import SwiftUI

struct MainDashboard: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                HeroStatusRow()
                if viewModel.mode == .scene {
                    SceneGallery()
                }
                FanControlSection()
                ThermalHistorySection()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .background(MFTheme.ink.opacity(0.35))
    }
}

private struct HeroStatusRow: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n

    var body: some View {
        MFPanel {
            HStack(alignment: .center, spacing: 22) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel.activeScene?.kind.title ?? viewModel.mode.title)
                            .font(MFTheme.displayFont(28))
                            .foregroundStyle(MFTheme.sand)
                        Text(viewModel.activeScene?.kind.blurb ?? viewModel.mode.subtitle)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(MFTheme.mist)
                    }

                    HStack(spacing: 0) {
                        MetricCell(title: l10n.t("metric.cpu"), value: String(format: "%.0f°", viewModel.thermal.cpuCelsius), tone: MFTheme.thermal(viewModel.thermal.cpuCelsius))
                        metricDivider
                        MetricCell(title: l10n.t("metric.gpu"), value: String(format: "%.0f°", viewModel.thermal.gpuCelsius), tone: MFTheme.thermal(viewModel.thermal.gpuCelsius))
                        metricDivider
                        MetricCell(title: l10n.t("metric.enclosure"), value: String(format: "%.0f°", viewModel.thermal.enclosureCelsius), tone: MFTheme.thermal(viewModel.thermal.enclosureCelsius))
                        metricDivider
                        MetricCell(title: l10n.t("metric.thermal"), value: viewModel.severity.title, tone: MFTheme.thermal(viewModel.thermal.peakCelsius))
                    }
                }
                Spacer(minLength: 8)
                TurbineGauge(progress: averageFanProgress)
                    .frame(width: 120, height: 120)
            }
        }
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(MFTheme.line)
            .frame(width: 1, height: 34)
            .padding(.horizontal, 16)
    }

    private var averageFanProgress: Double {
        guard !viewModel.fans.isEmpty else { return 0 }
        return viewModel.fans.map(\.normalizedSpeed).reduce(0, +) / Double(viewModel.fans.count)
    }
}

private struct MetricCell: View {
    let title: String
    let value: String
    let tone: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(MFTheme.mistDim)
            Text(value)
                .font(MFTheme.displayFont(20))
                .foregroundStyle(tone)
        }
        .frame(minWidth: 52, alignment: .leading)
    }
}

private struct TurbineGauge: View {
    let progress: Double
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(MFTheme.surfaceLift, lineWidth: 7)
            Circle()
                .trim(from: 0, to: max(0.02, progress))
                .stroke(
                    AngularGradient(
                        colors: [MFTheme.amber.opacity(0.85), MFTheme.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: "fan")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(MFTheme.accent)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(
                    .linear(duration: max(0.45, 2.8 - progress * 2.1)).repeatForever(autoreverses: false),
                    value: spin
                )
            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(MFTheme.mist)
                .offset(y: 48)
        }
        .onAppear { spin = true }
        .onChange(of: progress) { _, _ in
            spin = false
            DispatchQueue.main.async { spin = true }
        }
    }
}

private struct SceneGallery: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MFSectionHeader(title: l10n.t("section.scenes"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 10)], spacing: 10) {
                ForEach(viewModel.scenes) { scene in
                    SceneCard(
                        scene: scene,
                        selected: viewModel.selectedSceneID == scene.id
                    ) {
                        Task { await viewModel.selectScene(scene) }
                    }
                }
            }
        }
    }
}

private struct SceneCard: View {
    let scene: FanScene
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: scene.kind.symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selected ? MFTheme.ink : MFTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(selected ? MFTheme.accent : MFTheme.accent.opacity(0.12))
                        )
                    Spacer(minLength: 0)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(MFTheme.accent)
                    }
                }
                Text(scene.kind.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MFTheme.sand)
                Text(scene.kind.blurb)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(MFTheme.mist)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.14), value: hovering)
        .animation(.easeOut(duration: 0.14), value: selected)
        .onHover { hovering = $0 }
        .help(scene.kind.blurb)
    }

    private var cardFill: Color {
        if selected { return MFTheme.surfaceLift }
        if hovering { return MFTheme.surface.opacity(0.95) }
        return MFTheme.surface.opacity(0.72)
    }

    private var cardStroke: Color {
        if selected { return MFTheme.accent.opacity(0.4) }
        if hovering { return MFTheme.lineStrong }
        return MFTheme.line
    }
}

private struct FanControlSection: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MFSectionHeader(
                title: l10n.t("section.fans"),
                trailing: viewModel.mode == .maximum ? l10n.t("fan.maxLocked") : nil
            )

            VStack(spacing: 10) {
                ForEach(viewModel.fans) { fan in
                    FanRow(fan: fan) { rpm in
                        Task { await viewModel.setFanRPM(id: fan.id, rpm: rpm) }
                    }
                }
            }
        }
    }
}

private struct FanRow: View {
    let fan: FanInfo
    let onChange: (Double) -> Void
    @State private var draftRPM: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(fan.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MFTheme.sand)
                Spacer()
                Text("\(Int(fan.currentRPM))")
                    .font(MFTheme.mono(13, weight: .semibold))
                    .foregroundStyle(MFTheme.accent)
                Text("/ \(Int(fan.maxRPM)) RPM")
                    .font(MFTheme.mono(11))
                    .foregroundStyle(MFTheme.mistDim)
            }

            GeometryReader { geo in
                let pct = fan.maxRPM > fan.minRPM
                    ? (draftRPM - fan.minRPM) / (fan.maxRPM - fan.minRPM)
                    : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MFTheme.surfaceLift)
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [MFTheme.accentDeep, MFTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(5, geo.size.width * pct), height: 5)
                }
            }
            .frame(height: 5)

            Slider(
                value: $draftRPM,
                in: fan.minRPM...fan.maxRPM,
                onEditingChanged: { editing in
                    if !editing { onChange(draftRPM) }
                }
            )
            .tint(MFTheme.accent)

            HStack {
                Text("MIN \(Int(fan.minRPM))")
                Spacer()
                Text(fan.percentLabel)
                    .foregroundStyle(MFTheme.accent)
                Spacer()
                Text("MAX \(Int(fan.maxRPM))")
            }
            .font(MFTheme.mono(10))
            .foregroundStyle(MFTheme.mistDim)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MFTheme.surface.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MFTheme.line, lineWidth: 1)
        )
        .onAppear { draftRPM = fan.targetRPM }
        .onChange(of: fan.targetRPM) { _, newValue in
            draftRPM = newValue
        }
    }
}

private struct ThermalHistorySection: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MFSectionHeader(title: l10n.t("section.thermal"))
            Chart(viewModel.history) { sample in
                LineMark(
                    x: .value("时间", sample.timestamp),
                    y: .value("CPU", sample.cpuCelsius)
                )
                .foregroundStyle(MFTheme.accent)
                .interpolationMethod(.catmullRom)
                LineMark(
                    x: .value("时间", sample.timestamp),
                    y: .value("GPU", sample.gpuCelsius)
                )
                .foregroundStyle(MFTheme.amber)
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 30...100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(MFTheme.line)
                    AxisValueLabel()
                        .foregroundStyle(MFTheme.mistDim)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [40, 60, 80, 100]) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(MFTheme.line)
                    AxisValueLabel()
                        .foregroundStyle(MFTheme.mistDim)
                }
            }
            .frame(height: 168)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MFTheme.surface.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(MFTheme.line, lineWidth: 1)
            )

            HStack(spacing: 16) {
                legendDot(MFTheme.accent, l10n.t("chart.cpu"))
                legendDot(MFTheme.amber, l10n.t("chart.gpu"))
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(MFTheme.mist)
        }
        .padding(.bottom, 8)
    }

    private func legendDot(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
        }
    }
}
