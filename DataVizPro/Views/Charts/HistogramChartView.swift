import SwiftUI
import Charts

struct HistogramChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var binCount: Int = 10
    @State private var showNormalCurve = false
    @State private var selectedBin: HistogramData?
    @State private var dataSource: DataSource = .random
    @State private var animationProgress: Double = 0
    
    enum DataSource: String, CaseIterable {
        case random = "랜덤 분포"
        case normal = "정규 분포"
        case bimodal = "이봉 분포"
        case skewed = "치우친 분포"
    }
    
    // 히스토그램 데이터 생성
    var histogramData: [HistogramData] {
        let values = generateValues()
        let min = values.min() ?? 0
        let max = values.max() ?? 100
        let binWidth = (max - min) / Double(binCount)
        
        var bins: [HistogramData] = []
        
        for i in 0..<binCount {
            let rangeStart = min + Double(i) * binWidth
            let rangeEnd = rangeStart + binWidth
            let range = rangeStart...rangeEnd
            
            let frequency = values.filter { range.contains($0) }.count
            let normalizedFreq = Double(frequency) / Double(values.count)
            
            bins.append(HistogramData(
                bin: String(format: "%.0f-%.0f", rangeStart, rangeEnd),
                frequency: frequency,
                range: range,
                normalizedFrequency: normalizedFreq
            ))
        }
        
        return bins
    }
    
    func generateValues() -> [Double] {
        switch dataSource {
        case .random:
            return (0..<1000).map { _ in Double.random(in: 0...100) }
            
        case .normal:
            // Box-Muller 변환을 사용한 정규분포
            return (0..<1000).map { _ in
                let u1 = Double.random(in: 0...1)
                let u2 = Double.random(in: 0...1)
                let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
                return 50 + z * 15 // 평균 50, 표준편차 15
            }.map { max(0, min(100, $0)) } // 0-100 범위로 제한
            
        case .bimodal:
            // 두 개의 정규분포 혼합
            return (0..<1000).map { _ in
                if Bool.random() {
                    return Double.random(in: 20...40)
                } else {
                    return Double.random(in: 60...80)
                }
            }
            
        case .skewed:
            // 치우친 분포
            return (0..<1000).map { _ in
                let value = Double.random(in: 0...1)
                return value * value * 100 // 제곱으로 오른쪽으로 치우침
            }
        }
    }
    
    // 정규분포 곡선 데이터
    var normalCurveData: [(x: Double, y: Double)] {
        let values = generateValues()
        let count = Double(values.count)
        let mean = values.reduce(0, +) / count
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / count
        let stdDev = sqrt(variance)
        
        // stride를 먼저 Array로 변환하여 타입 추론 부담 감소
        let xValues: [Double] = Array(stride(from: 0, to: 100, by: 1))
        
        // map 대신 별도의 배열 생성
        var result: [(x: Double, y: Double)] = []
        result.reserveCapacity(xValues.count)
        
        for x in xValues {
            // 각 계산을 개별 변수로 분리
            let xDiff: Double = x - mean
            let xNorm: Double = xDiff / stdDev
            let exponent: Double = -0.5 * xNorm * xNorm
            let expValue: Double = exp(exponent)
            
            let sqrtTwoPi: Double = sqrt(2.0 * .pi)
            let normalizer: Double = 1.0 / (stdDev * sqrtTwoPi)
            let y: Double = normalizer * expValue
            
            // 스케일 조정
            let binCountDouble: Double = Double(binCount)
            let scaleFactor: Double = count * 100.0 / binCountDouble
            let scaledY: Double = y * scaleFactor
            
            result.append((x: x, y: scaledY))
        }
        
        return result
    }
    
    // 통계 정보
    var statistics: (mean: Double, median: Double, mode: Double, stdDev: Double) {
        let values = generateValues()
        let count = Double(values.count)
        
        // 평균 계산
        let sum = values.reduce(0, +)
        let mean = sum / count
        
        // 중앙값 계산
        let sortedValues = values.sorted()
        let middleIndex = sortedValues.count / 2
        let median = sortedValues[middleIndex]
        
        // 최빈값 계산 (가장 빈번한 구간의 중간값)
        let maxFrequencyBin = histogramData.max(by: { $0.frequency < $1.frequency })
        let mode = maxFrequencyBin?.range.lowerBound ?? 0
        
        // 표준편차 계산
        var squaredDiffs: [Double] = []
        squaredDiffs.reserveCapacity(values.count)
        for value in values {
            let diff = value - mean
            squaredDiffs.append(diff * diff)
        }
        let variance = squaredDiffs.reduce(0, +) / count
        let stdDev = sqrt(variance)
        
        return (mean: mean, median: median, mode: mode, stdDev: stdDev)
    }
    
    var body: some View {
        // 통계 정보를 한 번만 계산
        let stats = statistics
        
        return VStack(alignment: .leading, spacing: 20) {
            // 헤더
            headerView(stats: stats)
            
            // 메인 히스토그램
            chartView(stats: stats)
            
            // 데이터 소스 선택
            dataSourcePicker
            
            // 빈 개수 조절
            binCountControl
            
            // 컨트롤
            controlsView
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func headerView(stats: (mean: Double, median: Double, mode: Double, stdDev: Double)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("히스토그램")
                .font(.title2)
                .bold()
            
            Text("데이터 분포 분석")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 통계 정보 표시
            HStack(spacing: 20) {
                StatisticBadge(label: "평균", value: String(format: "%.1f", stats.mean))
                StatisticBadge(label: "중앙값", value: String(format: "%.1f", stats.median))
                StatisticBadge(label: "표준편차", value: String(format: "%.1f", stats.stdDev))
                
                Spacer()
                
                if let selected = selectedBin {
                    selectedBinView(selected: selected)
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func selectedBinView(selected: HistogramData) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("선택된 구간")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(selected.bin)")
                .font(.caption)
                .bold()
            Text("빈도: \(selected.frequency)")
                .font(.caption2)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func chartView(stats: (mean: Double, median: Double, mode: Double, stdDev: Double)) -> some View {
        Chart {
            // 히스토그램 막대
            histogramBars()
            
            // 정규분포 곡선
            if showNormalCurve {
                normalCurveLine()
            }
            
            // 평균선
            averageLine(mean: stats.mean)
            
            // 중앙값선
            medianLine(median: stats.median)
        }
        .frame(height: 350)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(binCount, 10))) { _ in
                AxisValueLabel(orientation: .vertical)
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(.gray.opacity(0.2))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    handleDragGesture(value: value)
                }
        )
    }
    
    @ChartContentBuilder
    private func histogramBars() -> some ChartContent {
        ForEach(histogramData) { bin in
            BarMark(
                x: .value("구간", bin.bin),
                y: .value("빈도", Double(bin.frequency) * animationProgress)
            )
            .foregroundStyle(barStyle(for: bin))
            .cornerRadius(2)
            .annotation(position: .top) {
                if shouldShowAnnotation(for: bin) {
                    Text("\(bin.frequency)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func barStyle(for bin: HistogramData) -> LinearGradient {
        if selectedBin?.id == bin.id {
            return LinearGradient(
                colors: [Color.blue, Color.blue],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func shouldShowAnnotation(for bin: HistogramData) -> Bool {
        return selectedBin?.id == bin.id && bin.frequency > 0
    }
    
    @ChartContentBuilder
    private func normalCurveLine() -> some ChartContent {
        ForEach(normalCurveData, id: \.x) { point in
            LineMark(
                x: .value("X", point.x),
                y: .value("Y", point.y * animationProgress)
            )
            .foregroundStyle(.red)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    private func averageLine(mean: Double) -> some ChartContent {
        RuleMark(
            x: .value("평균", mean)
        )
        .foregroundStyle(.green)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
        .annotation(position: .top) {
            Text("평균")
                .font(.caption2)
                .foregroundColor(.green)
        }
    }
    
    @ChartContentBuilder
    private func medianLine(median: Double) -> some ChartContent {
        RuleMark(
            x: .value("중앙값", median)
        )
        .foregroundStyle(.orange)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
        .annotation(position: .bottom) {
            Text("중앙값")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }
    
    private func handleDragGesture(value: DragGesture.Value) {
        // 드래그로 빈 개수 조정
        if abs(value.translation.width) > 50 {
            withAnimation {
                if value.translation.width > 0 {
                    binCount = min(30, binCount + 2)
                } else {
                    binCount = max(5, binCount - 2)
                }
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.5)) {
                    animationProgress = 1.0
                }
            }
        }
    }
    
    @ViewBuilder
    private var dataSourcePicker: some View {
        Picker("데이터 분포", selection: $dataSource) {
            ForEach(DataSource.allCases, id: \.self) { source in
                Text(source.rawValue).tag(source)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: dataSource) { _ in
            animationProgress = 0
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1.0
            }
        }
    }
    
    @ViewBuilder
    private var binCountControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("구간 개수: \(binCount)")
                    .font(.caption)
                
                Spacer()
                
                Text("← 드래그로 조절 →")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: Binding(
                get: { Double(binCount) },
                set: { binCount = Int($0) }
            ), in: 5...30, step: 1) {
                Text("구간")
            }
            .onChange(of: binCount) { _ in
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.5)) {
                    animationProgress = 1.0
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var controlsView: some View {
        HStack {
            Toggle("정규분포 곡선", isOn: $showNormalCurve)
            
            Spacer()
            
            Button("데이터 새로고침") {
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            .buttonStyle(.bordered)
            
            Button("애니메이션 재생") {
                animationProgress = 0
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }
}

// 통계 배지
struct StatisticBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.caption, design: .rounded))
                .bold()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}