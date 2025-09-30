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
    
    // 히스토그램 데이터 생성 - 단순화
    var histogramData: [HistogramData] {
        let values = generateValues()
        guard !values.isEmpty else { return [] }
        
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let range = maxValue - minValue
        
        guard range > 0, binCount > 0 else { return [] }
        
        let binWidth = range / Double(binCount)
        
        var bins: [HistogramData] = []
        bins.reserveCapacity(binCount)
        
        for i in 0..<binCount {
            let rangeStart = minValue + Double(i) * binWidth
            let rangeEnd = rangeStart + binWidth
            let binRange = rangeStart...rangeEnd
            
            let frequency = values.filter { binRange.contains($0) }.count
            let normalizedFreq = values.isEmpty ? 0 : Double(frequency) / Double(values.count)
            
            bins.append(HistogramData(
                bin: String(format: "%.0f-%.0f", rangeStart, rangeEnd),
                frequency: frequency,
                range: binRange,
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
                let u1 = max(0.0001, Double.random(in: 0...1)) // log(0) 방지
                let u2 = Double.random(in: 0...1)
                let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
                return max(0, min(100, 50 + z * 15)) // 0-100 범위로 제한
            }
            
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
    
    // 정규분포 곡선 데이터 - 단순화
    var normalCurveData: [(x: Double, y: Double)] {
        let values = generateValues()
        guard !values.isEmpty else { return [] }
        
        let count = Double(values.count)
        let mean = values.reduce(0, +) / count
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / count
        let stdDev = max(0.1, sqrt(variance)) // 0 방지
        
        var result: [(x: Double, y: Double)] = []
        
        for x in stride(from: 0.0, through: 100.0, by: 2.0) {
            let xDiff = x - mean
            let xNorm = xDiff / stdDev
            let y = exp(-0.5 * xNorm * xNorm) / (stdDev * sqrt(2.0 * .pi))
            let scaledY = y * count * 100.0 / Double(max(binCount, 1))
            result.append((x: x, y: scaledY))
        }
        
        return result
    }
    
    // 통계 정보 - 단순화
    var statistics: (mean: Double, median: Double, mode: Double, stdDev: Double) {
        let values = generateValues()
        guard !values.isEmpty else {
            return (mean: 0, median: 0, mode: 0, stdDev: 0)
        }
        
        let count = Double(values.count)
        let mean = values.reduce(0, +) / count
        
        let sortedValues = values.sorted()
        let median = sortedValues[sortedValues.count / 2]
        
        let maxFrequencyBin = histogramData.max(by: { $0.frequency < $1.frequency })
        let mode = maxFrequencyBin?.range.lowerBound ?? 0
        
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / count
        let stdDev = sqrt(variance)
        
        return (mean: mean, median: median, mode: mode, stdDev: stdDev)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("히스토그램")
                    .font(.title2)
                    .bold()
                
                Text("데이터 분포 분석")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 통계 정보
            let stats = statistics
            HStack(spacing: 20) {
                StatisticBadge(label: "평균", value: String(format: "%.1f", stats.mean))
                StatisticBadge(label: "중앙값", value: String(format: "%.1f", stats.median))
                StatisticBadge(label: "표준편차", value: String(format: "%.1f", stats.stdDev))
                
                Spacer()
                
                if let selected = selectedBin {
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
            }
            .padding(.horizontal)
            
            // 차트 - 간단한 버전
            simpleChartView
                .frame(height: 350)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animationProgress = 1.0
                    }
                }
            
            // 데이터 소스 선택
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
            
            // 빈 개수 조절
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
                ), in: 5...30, step: 1)
                .onChange(of: binCount) { _ in
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 0.5)) {
                        animationProgress = 1.0
                    }
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            HStack {
                Toggle("정규분포 곡선", isOn: $showNormalCurve)
                
                Spacer()
                
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
    
    // 단순화된 차트 뷰
    @ViewBuilder
    private var simpleChartView: some View {
        Chart {
            // 히스토그램 막대 (연속형 X축)
            ForEach(histogramData) { bin in
                BarMark(
                    xStart: .value("구간 시작", bin.range.lowerBound),
                    xEnd: .value("구간 끝", bin.range.upperBound),
                    y: .value("빈도", Double(bin.frequency) * animationProgress)
                )
                .foregroundStyle(
                    selectedBin?.id == bin.id ? Color.blue : Color.blue.opacity(0.6)
                )
                .cornerRadius(2)
            }
            
            // 정규분포 곡선 (옵션)
            if showNormalCurve && !normalCurveData.isEmpty {
                ForEach(Array(normalCurveData.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("X", point.x),
                        y: .value("Y", point.y * animationProgress)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            
            // 평균선
            if !histogramData.isEmpty {
                let mean = statistics.mean
                RuleMark(
                    x: .value("평균", mean)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(binCount, 10))) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(.gray.opacity(0.2))
            }
        }
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
