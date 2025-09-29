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
        
        for (index, category) in categories.enumerated() {
            for angle in stride(from: 0, to: 360, by: 5) {
                let radian = angle * .pi / 180
                
                // 각 카테고리별 다른 패턴
                let radius: Double
                switch index {
                case 0: // 꽃잎 패턴
                    radius = 50 + 30 * sin(4 * radian)
                case 1: // 나선형
                    radius = 30 + Double(angle) / 5
                case 2: // 심장 모양
                    let t = radian
                    radius = 40 * (1 + sin(t))
                default:
                    radius = 50
                }
                
                data.append(PolarData(
                    angle: Double(angle),
                    radius: max(0, radius),
                    category: category,
                    color: colors[index]
                ))
            }
        }
        
        return data
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
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - 40
                
                ZStack {
                    // 그리드
                    if showGrid {
                        PolarGrid(center: center, maxRadius: maxRadius)
                    }
                    
                    // 데이터 포인트/영역
                    ForEach(["패턴 A", "패턴 B", "패턴 C"], id: \.self) { category in
                        let categoryData = polarData.filter { $0.category == category }
                        
                        if showArea {
                            // 영역 채우기
                            Path { path in
                                for (index, point) in categoryData.enumerated() {
                                    let angle = (point.angle + rotationAngle) * .pi / 180
                                    let r = point.radius * maxRadius / 100 * animationProgress
                                    let x = center.x + cos(angle) * r
                                    let y = center.y + sin(angle) * r
                                    
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                                path.closeSubpath()
                            }
                            .fill(categoryData.first?.color.opacity(0.3) ?? .clear)
                        }
                        
                        // 선 그리기
                        Path { path in
                            for (index, point) in categoryData.enumerated() {
                                let angle = (point.angle + rotationAngle) * .pi / 180
                                let r = point.radius * maxRadius / 100 * animationProgress
                                let x = center.x + cos(angle) * r
                                let y = center.y + sin(angle) * r
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            if !categoryData.isEmpty {
                                // 마지막 점과 첫 점 연결
                                let firstPoint = categoryData[0]
                                let angle = (firstPoint.angle + rotationAngle) * .pi / 180
                                let r = firstPoint.radius * maxRadius / 100 * animationProgress
                                let x = center.x + cos(angle) * r
                                let y = center.y + sin(angle) * r
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(categoryData.first?.color ?? .clear, lineWidth: 2)
                        
                        // 데이터 포인트
                        ForEach(categoryData.filter { Int($0.angle) % 15 == 0 }) { point in
                            let angle = (point.angle + rotationAngle) * .pi / 180
                            let r = point.radius * maxRadius / 100 * animationProgress
                            let x = center.x + cos(angle) * r
                            let y = center.y + sin(angle) * r
                            
                            Circle()
                                .fill(point.color)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                                .onTapGesture {
                                    withAnimation {
                                        selectedPoint = point
                                    }
                                }
                        }
                    }
                    
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
            for angle in stride(from: 0, to: 360, by: 30) {
                let radian = CGFloat(angle) * .pi / 180
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