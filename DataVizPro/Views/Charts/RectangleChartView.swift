import SwiftUI
import Charts

struct RectangleChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCell: (x: String, y: String)?
    @State private var chartStyle: ChartStyle = .standard
    @State private var showValues = true
    
    enum ChartStyle: String, CaseIterable {
        case standard = "표준"
        case rounded = "둥근"
        case gradient = "그라데이션"
    }
    
    // 사각형 차트용 데이터
    var rectangleData: [(x: String, y: String, value: Double)] {
        var data: [(String, String, Double)] = []
        let xCategories = ["Q1", "Q2", "Q3", "Q4"]
        let yCategories = ["제품 A", "제품 B", "제품 C", "제품 D"]
        
        for x in xCategories {
            for y in yCategories {
                let value = Double.random(in: 10...100)
                data.append((x, y, value))
            }
        }
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("사각형 차트")
                    .font(.title2)
                    .bold()
                
                Text("분기별 제품 성과 매트릭스")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let (x, y) = selectedCell,
                   let data = rectangleData.first(where: { $0.x == x && $0.y == y }) {
                    HStack {
                        Text("\(y) - \(x)")
                            .font(.caption)
                            .bold()
                        Text("값: \(Int(data.value))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal)
            
            // 차트
            Chart(rectangleData, id: \.0) { item in
                RectangleMark(
                    x: .value("분기", item.x),
                    y: .value("제품", item.y),
                    width: .ratio(0.8),
                    height: .ratio(0.8)
                )
                .foregroundStyle(by: .value("값", item.value))
                .cornerRadius(chartStyle == .rounded ? 8 : 0)
                .opacity(selectedCell == nil || (selectedCell?.x == item.x && selectedCell?.y == item.y) ? 1 : 0.3)
                .annotation(position: .overlay) {
                    if showValues {
                        Text("\(Int(item.value))")
                            .font(.caption)
                            .foregroundColor(item.value > 60 ? .white : .primary)
                    }
                }
            }
            .frame(height: 350)
            .chartForegroundStyleScale(
                range: Gradient(colors: [.blue.opacity(0.3), .blue])
            )
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onTapGesture { location in
                // 탭 위치에 따라 셀 선택 로직 구현
            }
            
            // 스타일 선택
            Picker("스타일", selection: $chartStyle) {
                ForEach(ChartStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Toggle("값 표시", isOn: $showValues)
                .padding(.horizontal)
        }
    }
}

struct RuleChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var thresholds: [Double] = [30, 60, 85]
    @State private var showAreas = true
    @State private var animationProgress: Double = 0
    
    // 시계열 데이터
    var timeSeriesData: [(date: Date, value: Double)] {
        let startDate = Date().addingTimeInterval(-86400 * 30)
        return (0..<30).map { day in
            let date = startDate.addingTimeInterval(Double(day) * 86400)
            let value = 50 + sin(Double(day) / 5) * 30 + Double.random(in: -10...10)
            return (date, value)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("규칙 차트")
                    .font(.title2)
                    .bold()
                
                Text("임계값과 기준선 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 임계값 범례
                HStack(spacing: 15) {
                    ForEach(Array(thresholds.enumerated()), id: \.offset) { index, threshold in
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(colorForThreshold(index))
                                .frame(width: 20, height: 2)
                            Text("Level \(index + 1): \(Int(threshold))")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // 차트
            Chart {
                // 임계값 영역
                if showAreas {
                    RectangleMark(
                        yStart: .value("시작", 0),
                        yEnd: .value("끝", thresholds[0])
                    )
                    .foregroundStyle(.green.opacity(0.1))
                    
                    RectangleMark(
                        yStart: .value("시작", thresholds[0]),
                        yEnd: .value("끝", thresholds[1])
                    )
                    .foregroundStyle(.yellow.opacity(0.1))
                    
                    RectangleMark(
                        yStart: .value("시작", thresholds[1]),
                        yEnd: .value("끝", thresholds[2])
                    )
                    .foregroundStyle(.orange.opacity(0.1))
                    
                    RectangleMark(
                        yStart: .value("시작", thresholds[2]),
                        yEnd: .value("끝", 100)
                    )
                    .foregroundStyle(.red.opacity(0.1))
                }
                
                // 데이터 라인
                ForEach(timeSeriesData, id: \.date) { item in
                    LineMark(
                        x: .value("날짜", item.date),
                        y: .value("값", item.value * animationProgress)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("날짜", item.date),
                        y: .value("값", item.value * animationProgress)
                    )
                    .foregroundStyle(colorForValue(item.value))
                    .symbolSize(30)
                }
                
                // 임계값 라인
                ForEach(Array(thresholds.enumerated()), id: \.offset) { index, threshold in
                    RuleMark(
                        y: .value("임계값", threshold)
                    )
                    .foregroundStyle(colorForThreshold(index))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("Level \(index + 1)")
                            .font(.caption2)
                            .foregroundColor(colorForThreshold(index))
                            .padding(.horizontal, 4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                
                // 평균선
                RuleMark(
                    y: .value("평균", timeSeriesData.map { $0.value }.reduce(0, +) / Double(timeSeriesData.count))
                )
                .foregroundStyle(.purple)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [10, 5]))
                .annotation(position: .topLeading) {
                    Text("평균")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            .frame(height: 350)
            .chartYScale(domain: 0...100)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 임계값 조정
            VStack(spacing: 12) {
                ForEach(0..<thresholds.count, id: \.self) { index in
                    HStack {
                        Text("Level \(index + 1)")
                            .font(.caption)
                            .frame(width: 60)
                        
                        Slider(
                            value: Binding(
                                get: { thresholds[index] },
                                set: { newValue in
                                    thresholds[index] = newValue
                                    // 임계값 순서 유지
                                    if index > 0 && newValue < thresholds[index - 1] {
                                        thresholds[index] = thresholds[index - 1] + 1
                                    }
                                    if index < thresholds.count - 1 && newValue > thresholds[index + 1] {
                                        thresholds[index] = thresholds[index + 1] - 1
                                    }
                                }
                            ),
                            in: 0...100
                        )
                        
                        Text("\(Int(thresholds[index]))")
                            .font(.caption)
                            .frame(width: 30)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Toggle("영역 표시", isOn: $showAreas)
                .padding(.horizontal)
        }
    }
    
    func colorForThreshold(_ index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        default: return .red
        }
    }
    
    func colorForValue(_ value: Double) -> Color {
        if value < thresholds[0] {
            return .green
        } else if value < thresholds[1] {
            return .yellow
        } else if value < thresholds[2] {
            return .orange
        } else {
            return .red
        }
    }
}