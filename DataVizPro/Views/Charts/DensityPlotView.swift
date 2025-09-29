import SwiftUI
import Charts

struct DensityPlotView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var bandwidth: Double = 5.0
    @State private var showMultiple = false
    @State private var fillArea = true
    @State private var showRug = false
    @State private var selectedCategory: String?
    
    // 샘플 데이터 생성
    func generateDensityData(for category: String) -> [DensityData] {
        let count = 200
        var data: [DensityData] = []
        
        // 카테고리별로 다른 분포 생성
        let mean: Double
        let stdDev: Double
        
        switch category {
        case "그룹 A":
            mean = 30
            stdDev = 10
        case "그룹 B":
            mean = 50
            stdDev = 15
        case "그룹 C":
            mean = 70
            stdDev = 8
        default:
            mean = 50
            stdDev = 12
        }
        
        // KDE (Kernel Density Estimation) 계산
        for i in 0..<count {
            let x = Double(i) / Double(count - 1) * 100
            var density = 0.0
            var cumulativeDensity = 0.0
            
            // 가우시안 커널 사용
            for _ in 0..<100 {
                let sample = normalRandom(mean: mean, stdDev: stdDev)
                let kernel = gaussian(x: x, xi: sample, bandwidth: bandwidth)
                density += kernel
            }
            
            density /= 100.0
            
            // 누적 밀도 계산
            if i > 0 {
                cumulativeDensity = data[i - 1].cumulativeDensity + density / Double(count)
            }
            
            data.append(DensityData(
                x: x,
                density: density,
                cumulativeDensity: min(1.0, cumulativeDensity)
            ))
        }
        
        return data
    }
    
    func gaussian(x: Double, xi: Double, bandwidth: Double) -> Double {
        let diff = (x - xi) / bandwidth
        return (1.0 / (bandwidth * sqrt(2 * .pi))) * exp(-0.5 * diff * diff)
    }
    
    func normalRandom(mean: Double, stdDev: Double) -> Double {
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return z0 * stdDev + mean
    }
    
    var categories: [String] {
        ["그룹 A", "그룹 B", "그룹 C"]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("밀도 플롯")
                    .font(.title2)
                    .bold()
                
                Text("확률 밀도 분포 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 밀도 플롯 차트
            Chart {
                if showMultiple {
                    // 여러 그룹 동시 표시
                    ForEach(categories, id: \.self) { category in
                        let data = generateDensityData(for: category)
                        
                        ForEach(data) { point in
                            if fillArea {
                                AreaMark(
                                    x: .value("값", point.x),
                                    y: .value("밀도", point.density)
                                )
                                .foregroundStyle(by: .value("그룹", category))
                                .opacity(0.3)
                            }
                            
                            LineMark(
                                x: .value("값", point.x),
                                y: .value("밀도", point.density)
                            )
                            .foregroundStyle(by: .value("그룹", category))
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                } else {
                    // 단일 그룹 표시
                    let data = generateDensityData(for: selectedCategory ?? "그룹 A")
                    
                    ForEach(data) { point in
                        if fillArea {
                            AreaMark(
                                x: .value("값", point.x),
                                yStart: .value("시작", 0),
                                yEnd: .value("밀도", point.density)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.5)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                        }
                        
                        LineMark(
                            x: .value("값", point.x),
                            y: .value("밀도", point.density)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // Rug plot (데이터 포인트 표시)
                    if showRug {
                        ForEach(0..<30, id: \.self) { _ in
                            let xValue = normalRandom(
                                mean: selectedCategory == "그룹 A" ? 30 : selectedCategory == "그룹 B" ? 50 : 70,
                                stdDev: selectedCategory == "그룹 A" ? 10 : selectedCategory == "그룹 B" ? 15 : 8
                            )
                            
                            PointMark(
                                x: .value("값", xValue),
                                y: .value("밀도", -0.01)
                            )
                            .symbolSize(20)
                            .foregroundStyle(.blue.opacity(0.5))
                        }
                    }
                }
            }
            .frame(height: 350)
            .chartXScale(domain: 0...100)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .chartLegend(position: .top)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // 통계 정보
            if !showMultiple, let category = selectedCategory ?? categories.first {
                StatisticsPanel(category: category)
                    .padding(.horizontal)
            }
            
            // 그룹 선택 (단일 모드일 때)
            if !showMultiple {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            GroupButton(
                                title: category,
                                isSelected: (selectedCategory ?? "그룹 A") == category,
                                color: colorForCategory(category)
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 컨트롤
            VStack(spacing: 15) {
                HStack {
                    Text("대역폭: \(String(format: "%.1f", bandwidth))")
                    Slider(value: $bandwidth, in: 1...20)
                    Text("부드러움")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Toggle("여러 그룹", isOn: $showMultiple)
                    
                    Toggle("영역 채우기", isOn: $fillArea)
                    
                    if !showMultiple {
                        Toggle("Rug Plot", isOn: $showRug)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "그룹 A": return .blue
        case "그룹 B": return .green
        case "그룹 C": return .orange
        default: return .gray
        }
    }
}

// 통계 패널
struct StatisticsPanel: View {
    let category: String
    
    var statistics: (mean: Double, mode: Double, skewness: String) {
        switch category {
        case "그룹 A":
            return (30, 28, "약간 오른쪽")
        case "그룹 B":
            return (50, 50, "대칭")
        case "그룹 C":
            return (70, 71, "약간 왼쪽")
        default:
            return (50, 50, "대칭")
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            StatBox(label: "평균", value: String(format: "%.1f", statistics.mean))
            StatBox(label: "최빈값", value: String(format: "%.1f", statistics.mode))
            StatBox(label: "왜도", value: statistics.skewness)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("분포 특성")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(category == "그룹 A" ? "좁은 분포" : category == "그룹 B" ? "넓은 분포" : "집중 분포")
                    .font(.caption)
                    .bold()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// 통계 박스
struct StatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded))
                .bold()
        }
    }
}

// 그룹 버튼
struct GroupButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(title.last ?? "?"))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}