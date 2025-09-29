import SwiftUI

struct PolarChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedPoint: PolarData?
    @State private var animationProgress: Double = 0
    @State private var showGrid = true
    @State private var showArea = false
    @State private var rotationAngle: Double = 0
    
    // Polar 데이터 생성 (꽃잎 모양 패턴)
    var polarData: [PolarData] {
        var data: [PolarData] = []
        let categories = ["패턴 A", "패턴 B", "패턴 C"]
        let colors = [Color.blue, Color.purple, Color.orange]
        
        // stride를 먼저 Array로 변환
        let angles: [Double] = Array(stride(from: 0.0, to: 360.0, by: 5.0))
        
        for (index, category) in categories.enumerated() {
            let categoryColor = colors[index]
            
            for angle in angles {
                let radius = calculateRadius(for: angle, categoryIndex: index)
                
                let polarPoint = PolarData(
                    angle: angle,
                    radius: max(0, radius),
                    category: category,
                    color: categoryColor
                )
                data.append(polarPoint)
            }
        }
        
        return data
    }
    
    // 별도 함수로 반경 계산 분리
    private func calculateRadius(for angle: Double, categoryIndex: Int) -> Double {
        let radian = angle * .pi / 180
        
        switch categoryIndex {
        case 0: // 꽃잎 패턴
            return 50 + 30 * sin(4 * radian)
        case 1: // 나선형
            return 30 + angle / 5
        case 2: // 심장 모양
            return 40 * (1 + sin(radian))
        default:
            return 50
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("극좌표 차트")
                    .font(.title2)
                    .bold()
                
                Text("각도와 거리 기반 데이터 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let point = selectedPoint {
                    HStack(spacing: 20) {
                        Label("각도: \(Int(point.angle))°", systemImage: "arrow.clockwise")
                            .font(.caption)
                        Label("반경: \(Int(point.radius))", systemImage: "ruler")
                            .font(.caption)
                        Text(point.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(point.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal)
            
            // 극좌표 차트
            GeometryReader { geometry in
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                let center = CGPoint(x: centerX, y: centerY)
                let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - 40
                
                ZStack {
                    // 그리드
                    if showGrid {
                        PolarGrid(center: center, maxRadius: maxRadius)
                    }
                    
                    // 데이터 포인트/영역 - 미리 계산된 카테고리별로 그룹화
                    PolarDataView(
                        polarData: polarData,
                        center: center,
                        maxRadius: maxRadius,
                        showArea: showArea,
                        rotationAngle: rotationAngle,
                        animationProgress: animationProgress,
                        selectedPoint: $selectedPoint
                    )
                    
                    // 중심점
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .position(center)
                }
                .rotationEffect(.degrees(rotationAngle))
            }
            .frame(height: 400)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            HStack(spacing: 20) {
                ForEach(["패턴 A", "패턴 B", "패턴 C"], id: \.self) { category in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForCategory(category))
                            .frame(width: 12, height: 12)
                        Text(category)
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // 컨트롤
            VStack(spacing: 15) {
                HStack {
                    Text("회전 각도: \(Int(rotationAngle))°")
                        .font(.caption)
                    Slider(value: $rotationAngle, in: 0...360)
                }
                
                HStack {
                    Toggle("그리드 표시", isOn: $showGrid)
                    Toggle("영역 채우기", isOn: $showArea)
                    
                    Spacer()
                    
                    Button("자동 회전") {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            rotationAngle += 360
                        }
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
    
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "패턴 A": return .blue
        case "패턴 B": return .purple
        case "패턴 C": return .orange
        default: return .gray
        }
    }
}

// 데이터 렌더링을 위한 별도 뷰
struct PolarDataView: View {
    let polarData: [PolarData]
    let center: CGPoint
    let maxRadius: CGFloat
    let showArea: Bool
    let rotationAngle: Double
    let animationProgress: Double
    @Binding var selectedPoint: PolarData?
    
    // 카테고리별로 그룹화된 데이터
    var groupedData: [String: [PolarData]] {
        Dictionary(grouping: polarData, by: { $0.category })
    }
    
    var body: some View {
        ForEach(["패턴 A", "패턴 B", "패턴 C"], id: \.self) { category in
            if let categoryData = groupedData[category] {
                ZStack {
                    if showArea {
                        // 영역 채우기
                        PolarAreaPath(
                            data: categoryData,
                            center: center,
                            maxRadius: maxRadius,
                            rotationAngle: rotationAngle,
                            animationProgress: animationProgress
                        )
                        .fill(categoryData.first?.color.opacity(0.3) ?? .clear)
                    }
                    
                    // 선 그리기
                    PolarLinePath(
                        data: categoryData,
                        center: center,
                        maxRadius: maxRadius,
                        rotationAngle: rotationAngle,
                        animationProgress: animationProgress
                    )
                    .stroke(categoryData.first?.color ?? .clear, lineWidth: 2)
                    
                    // 데이터 포인트
                    ForEach(categoryData.filter { Int($0.angle) % 15 == 0 }) { point in
                        PolarPointView(
                            point: point,
                            center: center,
                            maxRadius: maxRadius,
                            rotationAngle: rotationAngle,
                            animationProgress: animationProgress
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedPoint = point
                            }
                        }
                    }
                }
            }
        }
    }
}

// 영역 Path 생성
struct PolarAreaPath: Shape {
    let data: [PolarData]
    let center: CGPoint
    let maxRadius: CGFloat
    let rotationAngle: Double
    let animationProgress: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (index, point) in data.enumerated() {
            let coords = calculateCoordinates(for: point)
            
            if index == 0 {
                path.move(to: coords)
            } else {
                path.addLine(to: coords)
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func calculateCoordinates(for point: PolarData) -> CGPoint {
        let angle = (point.angle + rotationAngle) * .pi / 180
        let r = point.radius * maxRadius / 100 * animationProgress
        return CGPoint(
            x: center.x + cos(angle) * r,
            y: center.y + sin(angle) * r
        )
    }
}

// 선 Path 생성
struct PolarLinePath: Shape {
    let data: [PolarData]
    let center: CGPoint
    let maxRadius: CGFloat
    let rotationAngle: Double
    let animationProgress: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (index, point) in data.enumerated() {
            let coords = calculateCoordinates(for: point)
            
            if index == 0 {
                path.move(to: coords)
            } else {
                path.addLine(to: coords)
            }
        }
        
        // 마지막 점과 첫 점 연결
        if let firstPoint = data.first {
            let coords = calculateCoordinates(for: firstPoint)
            path.addLine(to: coords)
        }
        
        return path
    }
    
    private func calculateCoordinates(for point: PolarData) -> CGPoint {
        let angle = (point.angle + rotationAngle) * .pi / 180
        let r = point.radius * maxRadius / 100 * animationProgress
        return CGPoint(
            x: center.x + cos(angle) * r,
            y: center.y + sin(angle) * r
        )
    }
}

// 데이터 포인트 뷰
struct PolarPointView: View {
    let point: PolarData
    let center: CGPoint
    let maxRadius: CGFloat
    let rotationAngle: Double
    let animationProgress: Double
    
    var position: CGPoint {
        let angle = (point.angle + rotationAngle) * .pi / 180
        let r = point.radius * maxRadius / 100 * animationProgress
        return CGPoint(
            x: center.x + cos(angle) * r,
            y: center.y + sin(angle) * r
        )
    }
    
    var body: some View {
        Circle()
            .fill(point.color)
            .frame(width: 6, height: 6)
            .position(position)
    }
}

// 극좌표 그리드
struct PolarGrid: View {
    let center: CGPoint
    let maxRadius: CGFloat
    
    var body: some View {
        Canvas { context, size in
            // 동심원
            for i in 1...5 {
                let radius = maxRadius * CGFloat(i) / 5
                context.stroke(
                    Path { path in
                        path.addEllipse(in: CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        ))
                    },
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 0.5
                )
                
                // 거리 레이블
                context.draw(
                    Text("\(i * 20)")
                        .font(.caption2)
                        .foregroundColor(.gray),
                    at: CGPoint(x: center.x + radius + 5, y: center.y)
                )
            }
            
            // 방사선
            let angles: [Int] = Array(stride(from: 0, to: 360, by: 30))
            for angle in angles {
                let angleDouble = CGFloat(angle)
                let radian = angleDouble * .pi / 180
                let x = center.x + cos(radian) * maxRadius
                let y = center.y + sin(radian) * maxRadius
                
                context.stroke(
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(x: x, y: y))
                    },
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 0.5
                )
                
                // 각도 레이블
                let labelX = center.x + cos(radian) * (maxRadius + 20)
                let labelY = center.y + sin(radian) * (maxRadius + 20)
                context.draw(
                    Text("\(angle)°")
                        .font(.caption2)
                        .foregroundColor(.gray),
                    at: CGPoint(x: labelX, y: labelY)
                )
            }
        }
    }
}