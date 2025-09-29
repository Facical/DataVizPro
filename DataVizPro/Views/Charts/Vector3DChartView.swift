import SwiftUI

struct Vector3DChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var rotationX: Double = 30
    @State private var rotationZ: Double = 45
    @State private var zoomLevel: Double = 1.0
    @State private var showArrows = true
    @State private var showGrid = true
    @State private var animationProgress: Double = 0
    @State private var selectedVector: Vector3DData?
    
    // 3D 벡터 데이터 생성
    var vectorData: [Vector3DData] {
        var vectors: [Vector3DData] = []
        
        // 벡터 필드 생성 (예: 유체 흐름 시뮬레이션)
        for i in stride(from: -1.0, through: 1.0, by: 0.4) {
            for j in stride(from: -1.0, through: 1.0, by: 0.4) {
                for k in stride(from: -1.0, through: 1.0, by: 0.4) {
                    let origin = SIMD3<Float>(Float(i), Float(j), Float(k))
                    
                    // 벡터 방향 계산 (소용돌이 패턴)
                    let angle = atan2(j, i)
                    let radius = sqrt(i*i + j*j)
                    let dirX = -sin(angle) * radius
                    let dirY = cos(angle) * radius
                    let dirZ = k * 0.5
                    
                    let direction = SIMD3<Float>(Float(dirX), Float(dirY), Float(dirZ))
                    let magnitude = simd_length(direction)
                    
                    let category = magnitude > 1.0 ? "강함" : magnitude > 0.5 ? "중간" : "약함"
                    let color = magnitude > 1.0 ? Color.red : magnitude > 0.5 ? Color.orange : Color.blue
                    
                    vectors.append(Vector3DData(
                        origin: origin,
                        direction: direction,
                        magnitude: magnitude,
                        category: category,
                        color: color
                    ))
                }
            }
        }
        
        return vectors
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("3D 벡터 필드")
                    .font(.title2)
                    .bold()
                
                Text("유체 역학 시뮬레이션")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let vector = selectedVector {
                    HStack(spacing: 15) {
                        Text("위치: (\(String(format: "%.1f", vector.origin.x)), \(String(format: "%.1f", vector.origin.y)), \(String(format: "%.1f", vector.origin.z)))")
                            .font(.caption)
                        
                        Text("크기: \(String(format: "%.2f", vector.magnitude))")
                            .font(.caption)
                            .bold()
                        
                        Text("분류: \(vector.category)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(vector.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // 3D 벡터 필드 렌더링
            GeometryReader { geometry in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let scale = min(size.width, size.height) / 6 * zoomLevel
                    
                    // 그리드 그리기
                    if showGrid {
                        drawGrid(context: context, center: center, scale: scale)
                    }
                    
                    // 벡터 그리기
                    for vector in vectorData {
                        let isSelected = selectedVector?.id == vector.id
                        drawVector(
                            context: context,
                            vector: vector,
                            center: center,
                            scale: scale,
                            isSelected: isSelected
                        )
                    }
                    
                    // 축 그리기
                    drawAxes(context: context, center: center, scale: scale)
                }
                .background(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.05), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: min(geometry.size.width, geometry.size.height) / 2
                    )
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            rotationZ += value.translation.width / 2
                            rotationX += value.translation.height / 2
                            rotationX = max(-90, min(90, rotationX))
                        }
                )
                .onTapGesture { location in
                    // 가장 가까운 벡터 선택
                    let tappedPoint = CGPoint(x: location.x, y: location.y)
                    selectedVector = findNearestVector(at: tappedPoint, center: center, scale: scale)
                }
            }
            .frame(height: 450)
            .background(Color.black.opacity(0.02))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            HStack(spacing: 20) {
                ForEach(["약함", "중간", "강함"], id: \.self) { category in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForCategory(category))
                            .frame(width: 10, height: 10)
                        Text(category)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text("벡터 개수: \(vectorData.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 컨트롤
            VStack(spacing: 15) {
                HStack {
                    Text("확대/축소")
                        .font(.caption)
                    Slider(value: $zoomLevel, in: 0.5...2.0)
                    Text("\(Int(zoomLevel * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                HStack {
                    Toggle("화살표 표시", isOn: $showArrows)
                    Toggle("그리드 표시", isOn: $showGrid)
                    
                    Spacer()
                    
                    Button("자동 회전") {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            rotationZ += 720
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("초기화") {
                        withAnimation {
                            rotationX = 30
                            rotationZ = 45
                            zoomLevel = 1.0
                            selectedVector = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 3D 점을 2D로 투영
    func project3D(point: SIMD3<Float>, center: CGPoint, scale: CGFloat) -> CGPoint {
        let radX = rotationX * .pi / 180
        let radZ = rotationZ * .pi / 180
        
        // Z축 회전
        let x1 = Double(point.x) * cos(radZ) - Double(point.y) * sin(radZ)
        let y1 = Double(point.x) * sin(radZ) + Double(point.y) * cos(radZ)
        let z1 = Double(point.z)
        
        // X축 회전
        let x2 = x1
        let y2 = y1 * cos(radX) - z1 * sin(radX)
        let z2 = y1 * sin(radX) + z1 * cos(radX)
        
        // 원근 투영
        let perspective = 1.0 / (4.0 + z2)
        let projX = x2 * perspective * scale
        let projY = y2 * perspective * scale
        
        return CGPoint(
            x: center.x + projX * animationProgress,
            y: center.y - projY * animationProgress
        )
    }
    
    // 벡터 그리기
    func drawVector(context: GraphicsContext, vector: Vector3DData, center: CGPoint, scale: CGFloat, isSelected: Bool) {
        let start = project3D(point: vector.origin, center: center, scale: scale)
        let end = project3D(
            point: vector.origin + vector.direction * 0.3,
            center: center,
            scale: scale
        )
        
        // 벡터 선
        context.stroke(
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            },
            with: .color(isSelected ? .yellow : vector.color),
            lineWidth: isSelected ? 3 : 1.5
        )
        
        // 시작점
        context.fill(
            Path { path in
                path.addEllipse(in: CGRect(x: start.x - 3, y: start.y - 3, width: 6, height: 6))
            },
            with: .color(vector.color)
        )
        
        // 화살표 머리
        if showArrows {
            let angle = atan2(end.y - start.y, end.x - start.x)
            let arrowLength: CGFloat = 8
            let arrowAngle: CGFloat = .pi / 6
            
            let arrow1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            let arrow2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )
            
            context.stroke(
                Path { path in
                    path.move(to: arrow1)
                    path.addLine(to: end)
                    path.addLine(to: arrow2)
                },
                with: .color(isSelected ? .yellow : vector.color),
                lineWidth: isSelected ? 2 : 1
            )
        }
    }
    
    // 그리드 그리기
    func drawGrid(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        let gridLines = 5
        let gridSpacing: Float = 2.0 / Float(gridLines - 1)
        
        for i in 0..<gridLines {
            let coord = -1.0 + Float(i) * gridSpacing
            
            // XY 평면 그리드
            let xyStart1 = project3D(point: SIMD3<Float>(-1, coord, 0), center: center, scale: scale)
            let xyEnd1 = project3D(point: SIMD3<Float>(1, coord, 0), center: center, scale: scale)
            
            context.stroke(
                Path { path in
                    path.move(to: xyStart1)
                    path.addLine(to: xyEnd1)
                },
                with: .color(.gray.opacity(0.2)),
                lineWidth: 0.5
            )
            
            let xyStart2 = project3D(point: SIMD3<Float>(coord, -1, 0), center: center, scale: scale)
            let xyEnd2 = project3D(point: SIMD3<Float>(coord, 1, 0), center: center, scale: scale)
            
            context.stroke(
                Path { path in
                    path.move(to: xyStart2)
                    path.addLine(to: xyEnd2)
                },
                with: .color(.gray.opacity(0.2)),
                lineWidth: 0.5
            )
        }
    }
    
    // 축 그리기
    func drawAxes(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        // X축 (빨강)
        let xStart = project3D(point: SIMD3<Float>(-1.5, 0, 0), center: center, scale: scale)
        let xEnd = project3D(point: SIMD3<Float>(1.5, 0, 0), center: center, scale: scale)
        
        context.stroke(
            Path { path in
                path.move(to: xStart)
                path.addLine(to: xEnd)
            },
            with: .color(.red),
            lineWidth: 2
        )
        
        // Y축 (초록)
        let yStart = project3D(point: SIMD3<Float>(0, -1.5, 0), center: center, scale: scale)
        let yEnd = project3D(point: SIMD3<Float>(0, 1.5, 0), center: center, scale: scale)
        
        context.stroke(
            Path { path in
                path.move(to: yStart)
                path.addLine(to: yEnd)
            },
            with: .color(.green),
            lineWidth: 2
        )
        
        // Z축 (파랑)
        let zStart = project3D(point: SIMD3<Float>(0, 0, -1.5), center: center, scale: scale)
        let zEnd = project3D(point: SIMD3<Float>(0, 0, 1.5), center: center, scale: scale)
        
        context.stroke(
            Path { path in
                path.move(to: zStart)
                path.addLine(to: zEnd)
            },
            with: .color(.blue),
            lineWidth: 2
        )
    }
    
    // 가장 가까운 벡터 찾기
    func findNearestVector(at point: CGPoint, center: CGPoint, scale: CGFloat) -> Vector3DData? {
        var nearest: Vector3DData?
        var minDistance: CGFloat = .infinity
        
        for vector in vectorData {
            let projectedPoint = project3D(point: vector.origin, center: center, scale: scale)
            let distance = sqrt(pow(projectedPoint.x - point.x, 2) + pow(projectedPoint.y - point.y, 2))
            
            if distance < minDistance && distance < 20 {
                minDistance = distance
                nearest = vector
            }
        }
        
        return nearest
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "강함": return .red
        case "중간": return .orange
        case "약함": return .blue
        default: return .gray
        }
    }
}