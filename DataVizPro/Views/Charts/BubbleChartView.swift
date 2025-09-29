import SwiftUI
import Charts

struct BubbleChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCategory: String?
    @State private var zoomLevel: Double = 1.0
    @State private var showLabels = false
    @State private var animationProgress: Double = 0
    @State private var hoveredBubble: BubbleData?
    @State private var sizeBy: SizeMetric = .size
    
    enum SizeMetric: String, CaseIterable {
        case size = "크기"
        case growth = "성장률"
        case value = "값"
    }
    
    var filteredData: [BubbleData] {
        if let category = selectedCategory {
            return dataManager.bubbleData.filter { $0.category == category }
        }
        return dataManager.bubbleData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            BubbleChartHeader(hoveredBubble: hoveredBubble)
            
            // 버블 차트
            BubbleChartContent(
                filteredData: filteredData,
                selectedCategory: selectedCategory,
                showLabels: showLabels,
                zoomLevel: zoomLevel,
                animationProgress: $animationProgress,
                sizeBy: sizeBy
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            BubbleLegendView(
                bubbleData: dataManager.bubbleData,
                selectedCategory: $selectedCategory
            )
            
            // 컨트롤
            BubbleControlsView(
                sizeBy: $sizeBy,
                zoomLevel: $zoomLevel,
                showLabels: $showLabels,
                animationProgress: $animationProgress
            )
        }
    }
    
    func bubbleSize(for bubble: BubbleData) -> Double {
        switch sizeBy {
        case .size:
            return bubble.size * 30
        case .growth:
            return abs(bubble.growth) * 10
        case .value:
            return (bubble.x + bubble.y) / 2 * 0.5
        }
    }
}

// MARK: - Header Component
struct BubbleChartHeader: View {
    let hoveredBubble: BubbleData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("버블 차트")
                .font(.title2)
                .bold()
            
            Text("다차원 데이터 시각화")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 호버된 버블 정보
            if let bubble = hoveredBubble {
                HoveredBubbleInfo(bubble: bubble)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Hovered Bubble Info
struct HoveredBubbleInfo: View {
    let bubble: BubbleData
    
    var body: some View {
        HStack(spacing: 20) {
            Label(bubble.label, systemImage: "circle.fill")
                .foregroundColor(bubble.color)
            
            HStack(spacing: 15) {
                InfoBadge(label: "X", value: String(format: "%.1f", bubble.x))
                InfoBadge(label: "Y", value: String(format: "%.1f", bubble.y))
                InfoBadge(label: "크기", value: String(format: "%.1f", bubble.size))
                InfoBadge(
                    label: "성장",
                    value: String(format: "%+.1f%%", bubble.growth),
                    color: bubble.growth > 0 ? .green : .red
                )
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Chart Content
struct BubbleChartContent: View {
    let filteredData: [BubbleData]
    let selectedCategory: String?
    let showLabels: Bool
    let zoomLevel: Double
    @Binding var animationProgress: Double
    let sizeBy: BubbleChartView.SizeMetric
    
    var body: some View {
        ZStack {
            // 배경 그리드
            BubbleChartGrid()
            
            // 버블 차트
            Chart(filteredData) { bubble in
                createBubbleMark(for: bubble)
            }
            .frame(height: 450)
            .chartXScale(domain: 0...100)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisValueLabel()
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.1))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.1))
                }
            }
            .chartBackground { _ in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.02),
                                Color.purple.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    @ChartContentBuilder
    private func createBubbleMark(for bubble: BubbleData) -> some ChartContent {
        PointMark(
            x: .value("X", bubble.x),
            y: .value("Y", bubble.y)
        )
        .symbolSize(calculateBubbleSize(for: bubble))
        .foregroundStyle(bubbleStyle(for: bubble))
        .opacity(bubbleOpacity(for: bubble))
        .annotation(position: .overlay) {
            if showLabels && shouldShowLabel(for: bubble) {
                Text(bubble.label)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }
    
    private func calculateBubbleSize(for bubble: BubbleData) -> Double {
        let baseSize: Double
        switch sizeBy {
        case .size:
            baseSize = bubble.size * 30
        case .growth:
            baseSize = abs(bubble.growth) * 10
        case .value:
            baseSize = (bubble.x + bubble.y) / 2 * 0.5
        }
        return baseSize * animationProgress * zoomLevel
    }
    
    private func bubbleStyle(for bubble: BubbleData) -> LinearGradient {
        if bubble.growth > 0 {
            return LinearGradient(
                colors: [bubble.color, bubble.color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [bubble.color, bubble.color.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func bubbleOpacity(for bubble: BubbleData) -> Double {
        (selectedCategory == nil || selectedCategory == bubble.category) ? 0.8 : 0.2
    }
    
    private func shouldShowLabel(for bubble: BubbleData) -> Bool {
        selectedCategory == nil || selectedCategory == bubble.category
    }
}

// MARK: - Chart Grid
struct BubbleChartGrid: View {
    var body: some View {
        GeometryReader { geometry in
            // 사분면 구분선
            Path { path in
                // 수직선
                path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                
                // 수평선
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            
            // 사분면 라벨
            QuadrantLabels()
        }
    }
}

// MARK: - Quadrant Labels
struct QuadrantLabels: View {
    var body: some View {
        VStack {
            HStack {
                Text("Low X, High Y")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(8)
                Spacer()
                Text("High X, High Y")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(8)
            }
            Spacer()
            HStack {
                Text("Low X, Low Y")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(8)
                Spacer()
                Text("High X, Low Y")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
    }
}

// MARK: - Legend View
struct BubbleLegendView: View {
    let bubbleData: [BubbleData]
    @Binding var selectedCategory: String?
    
    var categories: [String] {
        Array(Set(bubbleData.map { $0.category })).sorted()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryLegendItem(
                        category: category,
                        color: colorForCategory(category),
                        count: bubbleData.filter { $0.category == category }.count,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring()) {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "A": return .blue
        case "B": return .green
        case "C": return .orange
        default: return .purple
        }
    }
}

// MARK: - Controls View
struct BubbleControlsView: View {
    @Binding var sizeBy: BubbleChartView.SizeMetric
    @Binding var zoomLevel: Double
    @Binding var showLabels: Bool
    @Binding var animationProgress: Double
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("크기 기준:")
                Picker("크기 기준", selection: $sizeBy) {
                    ForEach(BubbleChartView.SizeMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            HStack {
                Text("확대: \(Int(zoomLevel * 100))%")
                Slider(value: $zoomLevel, in: 0.5...2.0)
            }
            
            HStack {
                Toggle("레이블 표시", isOn: $showLabels)
                
                Spacer()
                
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.spring(response: 1.5, dampingFraction: 0.7)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views
// 정보 배지
struct InfoBadge: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .bold()
                .foregroundColor(color)
        }
    }
}

// 카테고리 범례 아이템
struct CategoryLegendItem: View {
    let category: String
    let color: Color
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 12, height: 12)
                    Text("카테고리 \(category)")
                        .font(.caption)
                        .bold()
                }
                Text("\(count)개")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}