import SwiftUI
import Charts

struct ViolinPlotView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCategory: String?
    @State private var showBoxPlot = true
    @State private var showKernel = false
    @State private var animationProgress: Double = 0
    
    // 바이올린 플롯 데이터 생성
    var violinData: [ViolinPlotData] {
        let categories = ["그룹 A", "그룹 B", "그룹 C", "그룹 D"]
        
        return categories.map { category in
            // 각 그룹별로 다른 분포 생성
            var values: [Double] = []
            switch category {
            case "그룹 A":
                // 정규분포
                values = (0..<100).map { _ in
                    let u1 = Double.random(in: 0...1)
                    let u2 = Double.random(in: 0...1)
                    let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
                    return 50 + z * 15
                }.map { max(0, min(100, $0)) }
                
            case "그룹 B":
                // 이봉분포
                values = (0..<100).map { _ in
                    if Bool.random() {
                        return Double.random(in: 20...40)
                    } else {
                        return Double.random(in: 60...80)
                    }
                }
                
            case "그룹 C":
                // 치우친 분포
                values = (0..<100).map { _ in
                    pow(Double.random(in: 0...1), 2) * 100
                }
                
            default:
                // 균등분포
                values = (0..<100).map { _ in Double.random(in: 10...90) }
            }
            
            let sorted = values.sorted()
            let quartiles = [
                sorted[25],  // Q1
                sorted[50],  // Median
                sorted[75]   // Q3
            ]
            
            // 밀도 곡선 계산 (간단한 커널 밀도 추정)
            let densityCurve = calculateDensityCurve(for: values)
            
            return ViolinPlotData(
                category: category,
                values: values,
                quartiles: quartiles,
                densityCurve: densityCurve
            )
        }
    }
    
    func calculateDensityCurve(for values: [Double]) -> [(x: Double, y: Double)] {
        let bandwidth = 5.0
        var curve: [(Double, Double)] = []
        
        for x in stride(from: 0.0, through: 100.0, by: 2.0) {
            var density = 0.0
            for value in values {
                let diff = (x - value) / bandwidth
                density += exp(-0.5 * diff * diff) / sqrt(2 * .pi)
            }
            density /= (Double(values.count) * bandwidth)
            curve.append((x, density))
        }
        
        return curve
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("바이올린 플롯")
                    .font(.title2)
                    .bold()
                
                Text("데이터 분포와 밀도 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let category = selectedCategory,
                   let data = violinData.first(where: { $0.category == category }) {
                    HStack(spacing: 20) {
                        Text(category)
                            .font(.caption)
                            .bold()
                        
                        HStack(spacing: 15) {
                            StatLabel(label: "Q1", value: String(format: "%.1f", data.quartiles[0]))
                            StatLabel(label: "중앙값", value: String(format: "%.1f", data.quartiles[1]))
                            StatLabel(label: "Q3", value: String(format: "%.1f", data.quartiles[2]))
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // 바이올린 플롯
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(violinData) { data in
                        ViolinShape(
                            data: data,
                            showBoxPlot: showBoxPlot,
                            isSelected: selectedCategory == data.category,
                            animationProgress: animationProgress,
                            height: geometry.size.height
                        )
                        .frame(width: geometry.size.width / CGFloat(violinData.count))
                        .onTapGesture {
                            withAnimation {
                                if selectedCategory == data.category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = data.category
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 400)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 컨트롤
            HStack {
                Toggle("박스플롯 표시", isOn: $showBoxPlot)
                
                Spacer()
                
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.5)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
    }
    
    struct StatLabel: View {
        let label: String
        let value: String
        
        var body: some View {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .bold()
            }
        }
    }
}

// 바이올린 모양 뷰
struct ViolinShape: View {
    let data: ViolinPlotData
    let showBoxPlot: Bool
    let isSelected: Bool
    let animationProgress: Double
    let height: CGFloat
    
    var maxDensity: Double {
        data.densityCurve.map { $0.y }.max() ?? 1.0
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2
            
            ZStack {
                // 바이올린 모양 (밀도 곡선)
                Path { path in
                    // 왼쪽 면
                    for (index, point) in data.densityCurve.enumerated() {
                        let y = height * (1 - point.x / 100)
                        let x = centerX - (point.y / maxDensity) * width * 0.4 * animationProgress
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    // 오른쪽 면
                    for point in data.densityCurve.reversed() {
                        let y = height * (1 - point.x / 100)
                        let x = centerX + (point.y / maxDensity) * width * 0.4 * animationProgress
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            colorForCategory(data.category).opacity(0.3),
                            colorForCategory(data.category).opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Path { path in
                        // 왼쪽 윤곽선
                        for (index, point) in data.densityCurve.enumerated() {
                            let y = height * (1 - point.x / 100)
                            let x = centerX - (point.y / maxDensity) * width * 0.4 * animationProgress
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        
                        // 오른쪽 윤곽선
                        for point in data.densityCurve.reversed() {
                            let y = height * (1 - point.x / 100)
                            let x = centerX + (point.y / maxDensity) * width * 0.4 * animationProgress
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        path.closeSubpath()
                    }
                    .stroke(colorForCategory(data.category), lineWidth: isSelected ? 3 : 1.5)
                )
                
                // 박스플롯 요소
                if showBoxPlot {
                    // IQR 박스
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 20, height: height * (data.quartiles[2] - data.quartiles[0]) / 100)
                        .position(
                            x: centerX,
                            y: height * (1 - (data.quartiles[0] + data.quartiles[2]) / 200)
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 1)
                                .frame(width: 20, height: height * (data.quartiles[2] - data.quartiles[0]) / 100)
                                .position(
                                    x: centerX,
                                    y: height * (1 - (data.quartiles[0] + data.quartiles[2]) / 200)
                                )
                        )
                    
                    // 중앙값 선
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 20, height: 2)
                        .position(
                            x: centerX,
                            y: height * (1 - data.quartiles[1] / 100)
                        )
                }
                
                // 카테고리 레이블
                Text(data.category)
                    .font(.caption)
                    .bold()
                    .position(x: centerX, y: height - 10)
            }
        }
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "그룹 A": return .blue
        case "그룹 B": return .green
        case "그룹 C": return .orange
        case "그룹 D": return .purple
        default: return .gray
        }
    }
}