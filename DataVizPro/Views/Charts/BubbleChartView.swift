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
    
    // 분리된 계산 프로퍼티
    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("버블 차트")
                .font(.title2)
                .bold()
            
            Text("다차원 데이터 시각화")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 호버된 버블 정보
            if let bubble = hoveredBubble {
                hoveredBubbleInfo(bubble: bubble)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func hoveredBubbleInfo(bubble: BubbleData) -> some View {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            headerView
            
            // 버블 차트
            ZStack {
                // 배경 그리드
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
                
                // 버블 차트
                Chart(filteredData) { bubble in
                    PointMark(
                        x: .value("X", bubble.x),
                        y: .value("Y", bubble.y)
                    )
                    .symbolSize(bubbleSize(for: bubble) * animationProgress * zoomLevel)
                    .foregroundStyle(
                        bubble.growth > 0
                        ? bubble.color.gradient
                        : LinearGradient(
                            colors: [bubble.color, bubble.color.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(selectedCategory == nil || selectedCategory == bubble.category ? 0.8 : 0.2)
                    .annotation(position: .overlay) {
                        if showLabels && (selectedCategory == nil || selectedCategory == bubble.category) {
                            Text(bubble.label)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
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
                .chartBackground { chartProxy in
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
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(Set(dataManager.bubbleData.map { $0.category })).sorted(), id: \.self) { category in
                        CategoryLegendItem(
                            category: category,
                            color: colorForCategory(category),
                            count: dataManager.bubbleData.filter { $0.category == category }.count,
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
            
            // 컨트롤
            VStack(spacing: 15) {
                HStack {
                    Text("크기 기준:")
                    Picker("크기 기준", selection: $sizeBy) {
                        ForEach(SizeMetric.allCases, id: \.self) { metric in
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
    
    private func bubbleSize(for bubble: BubbleData) -> Double {
        switch sizeBy {
        case .size:
            return bubble.size * 30
        case .growth:
            return abs(bubble.growth) * 10
        case .value:
            return (bubble.x + bubble.y) / 2 * 0.5
        }
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