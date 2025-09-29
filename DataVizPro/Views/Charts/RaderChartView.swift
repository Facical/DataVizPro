import SwiftUI

// 레이더 차트 데이터 모델
struct RadarData: Identifiable {
    let id = UUID()
    let category: String
    let axes: [String]
    let values: [Double]
    let color: Color
}

struct RadarChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCategories: Set<String> = []
    @State private var animationProgress: Double = 0
    @State private var showDataPoints = true
    @State private var fillArea = true
    
    // 샘플 데이터 생성
    var radarData: [RadarData] {
        let axes = ["속도", "내구성", "디자인", "가격", "연비", "안전성", "편의성", "기술"]
        
        return [
            RadarData(
                category: "모델 A",
                axes: axes,
                values: [85, 70, 90, 60, 75, 88, 82, 95],
                color: .blue
            ),
            RadarData(
                category: "모델 B",
                axes: axes,
                values: [70, 85, 75, 80, 90, 75, 88, 70],
                color: .green
            ),
            RadarData(
                category: "모델 C",
                axes: axes,
                values: [95, 60, 85, 70, 65, 92, 75, 88],
                color: .orange
            ),
            RadarData(
                category: "업계 평균",
                axes: axes,
                values: [75, 75, 75, 75, 75, 75, 75, 75],
                color: .gray
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            headerView
            
            // 레이더 차트
            GeometryReader { geometry in
                let size = geometry.size
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 40
                
                ZStack {
                    // 배경 그리드
                    RadarGrid(
                        center: center,
                        radius: radius,
                        axes: radarData.first?.axes ?? [],
                        levels: 5
                    )
                    
                    // 데이터 영역
                    ForEach(radarData) { data in
                        if shouldShowData(data) {
                            radarDataView(for: data, center: center, radius: radius)
                        }
                    }
                    
                    // 축 레이블
                    axisLabelsView(center: center, radius: radius)
                }
            }
            .frame(height: 400)
            .background(
                LinearGradient(
                    colors: [Color.gray.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            legendView
            
            // 컨트롤
            controlsView
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("레이더 차트")
                .font(.title2)
                .bold()
            Text("다차원 성능 비교")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private func shouldShowData(_ data: RadarData) -> Bool {
        selectedCategories.isEmpty || selectedCategories.contains(data.category)
    }
    
    @ViewBuilder
    private func radarDataView(for data: RadarData, center: CGPoint, radius: CGFloat) -> some View {
        // 데이터 영역 폴리곤
        RadarShape(
            center: center,
            radius: radius,
            values: animatedValues(for: data),
            axesCount: data.axes.count
        )
        .fill(fillColor(for: data))
        .overlay(
            RadarShape(
                center: center,
                radius: radius,
                values: animatedValues(for: data),
                axesCount: data.axes.count
            )
            .stroke(data.color, lineWidth: 2)
        )
        
        // 데이터 포인트
        if showDataPoints {
            dataPointsView(for: data, center: center, radius: radius)
        }
    }
    
    private func animatedValues(for data: RadarData) -> [Double] {
        // animationProgress는 0...1 범위로 사용
        data.values.map { $0 * animationProgress }
    }
    
    private func fillColor(for data: RadarData) -> Color {
        fillArea ? data.color.opacity(0.3) : Color.clear
    }
    
    @ViewBuilder
    private func dataPointsView(for data: RadarData, center: CGPoint, radius: CGFloat) -> some View {
        ForEach(Array(data.values.enumerated()), id: \.offset) { index, value in
            let position = calculatePointPosition(
                index: index,
                value: value,
                center: center,
                radius: radius,
                axesCount: data.axes.count
            )
            
            Circle()
                .fill(data.color)
                .frame(width: 8, height: 8)
                .position(position)
        }
    }
    
    private func calculatePointPosition(index: Int, value: Double, center: CGPoint, radius: CGFloat, axesCount: Int) -> CGPoint {
        let angle = Double(index) * 2.0 * .pi / Double(axesCount) - (.pi / 2.0)
        let distance = radius * CGFloat(value * animationProgress / 100.0)
        let cosA = CGFloat(cos(angle))
        let sinA = CGFloat(sin(angle))
        return CGPoint(
            x: center.x + cosA * distance,
            y: center.y + sinA * distance
        )
    }
    
    @ViewBuilder
    private func axisLabelsView(center: CGPoint, radius: CGFloat) -> some View {
        if let axes = radarData.first?.axes {
            ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                let position = calculateLabelPosition(
                    index: index,
                    center: center,
                    radius: radius,
                    axesCount: axes.count
                )
                
                Text(axis)
                    .font(.caption)
                    .position(position)
            }
        }
    }
    
    private func calculateLabelPosition(index: Int, center: CGPoint, radius: CGFloat, axesCount: Int) -> CGPoint {
        let angle = Double(index) * 2.0 * .pi / Double(axesCount) - (.pi / 2.0)
        let labelDistance: CGFloat = radius + 25
        let cosA = CGFloat(cos(angle))
        let sinA = CGFloat(sin(angle))
        return CGPoint(
            x: center.x + cosA * labelDistance,
            y: center.y + sinA * labelDistance
        )
    }
    
    private var legendView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(radarData) { data in
                legendItem(for: data)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func legendItem(for data: RadarData) -> some View {
        let average = calculateAverage(for: data)
        let isSelected = selectedCategories.contains(data.category) || selectedCategories.isEmpty
        
        HStack {
            Circle()
                .fill(data.color)
                .frame(width: 12, height: 12)
            
            Text(data.category)
                .font(.caption)
            
            Spacer()
            
            Text("\(Int(average))점")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(isSelected ? data.color.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(6)
        .onTapGesture {
            toggleSelection(for: data.category)
        }
    }
    
    private func calculateAverage(for data: RadarData) -> Double {
        let sum = data.values.reduce(0, +)
        return sum / Double(data.values.count)
    }
    
    private func toggleSelection(for category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 12) {
            HStack {
                Toggle("영역 채우기", isOn: $fillArea)
                Spacer()
                Toggle("데이터 포인트", isOn: $showDataPoints)
            }
            
            HStack {
                Button("전체 선택") {
                    selectedCategories.removeAll()
                }
                .buttonStyle(.bordered)
                
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.5)) {
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

// 레이더 차트 그리드
struct RadarGrid: View {
    let center: CGPoint
    let radius: CGFloat
    let axes: [String]
    let levels: Int
    
    var body: some View {
        Canvas { context, _ in
            let axesCount = axes.count
            
            // 동심원 그리기
            for level in 1...levels {
                let levelRadius = radius * CGFloat(level) / CGFloat(levels)
                
                var path = Path()
                for i in 0..<axesCount {
                    let angle = Double(i) * 2.0 * .pi / Double(axesCount) - (.pi / 2.0)
                    let cosA = CGFloat(cos(angle))
                    let sinA = CGFloat(sin(angle))
                    let x = center.x + cosA * levelRadius
                    let y = center.y + sinA * levelRadius
                    
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
                
                context.stroke(
                    path,
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 1
                )
                
                // 레벨 레이블
                if level == levels {
                    let labelX = center.x + 5
                    let labelY = center.y - levelRadius - 5
                    let label = Text(verbatim: "\(level * 20)")
                    context.draw(
                        label,
                        at: CGPoint(x: labelX, y: labelY)
                    )
                }
            }
            
            // 축 선 그리기
            for i in 0..<axesCount {
                let angle = Double(i) * 2.0 * .pi / Double(axesCount) - (.pi / 2.0)
                let cosA = CGFloat(cos(angle))
                let sinA = CGFloat(sin(angle))
                let endX = center.x + cosA * radius
                let endY = center.y + sinA * radius
                
                context.stroke(
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(x: endX, y: endY))
                    },
                    with: .color(.gray.opacity(0.3)),
                    lineWidth: 1
                )
            }
        }
    }
}

// 레이더 차트 도형
struct RadarShape: Shape {
    let center: CGPoint
    let radius: CGFloat
    let values: [Double]
    let axesCount: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (index, value) in values.enumerated() {
            let angle = Double(index) * 2.0 * .pi / Double(axesCount) - (.pi / 2.0)
            let distance = radius * CGFloat(value) / 100.0
            let cosA = CGFloat(cos(angle))
            let sinA = CGFloat(sin(angle))
            let x = center.x + cosA * distance
            let y = center.y + sinA * distance
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}
