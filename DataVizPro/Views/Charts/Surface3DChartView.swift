import SwiftUI

struct Surface3DChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var rotationX: Double = 30
    @State private var rotationZ: Double = 45
    @State private var zoomLevel: Double = 1.0
    @State private var wireframe = false
    @State private var colorScheme: ColorScheme = .gradient
    @State private var animationProgress: Double = 0
    
    enum ColorScheme: String, CaseIterable {
        case gradient = "그라데이션"
        case height = "높이맵"
        case temperature = "온도맵"
        
        func color(for value: Double) -> Color {
            let normalized = (value + 1) / 2 // -1 to 1 범위를 0 to 1로 정규화
            
            switch self {
            case .gradient:
                return Color(hue: normalized * 0.8, saturation: 1, brightness: 1)
            case .height:
                if normalized < 0.25 {
                    return .blue
                } else if normalized < 0.5 {
                    return .green
                } else if normalized < 0.75 {
                    return .yellow
                } else {
                    return .red
                }
            case .temperature:
                return Color(red: normalized, green: 0.5, blue: 1 - normalized)
            }
        }
    }
    
    // 3D 표면 데이터 생성 (함수: z = sin(x) * cos(y))
    var surfaceData: [[Double]] {
        let gridSize = 30
        var data: [[Double]] = []
        
        for i in 0..<gridSize {
            var row: [Double] = []
            for j in 0..<gridSize {
                let x = Double(i) / Double(gridSize) * 4 * .pi - 2 * .pi
                let y = Double(j) / Double(gridSize) * 4 * .pi - 2 * .pi
                let z = sin(x) * cos(y) * exp(-sqrt(x*x + y*y) / 5)
                row.append(z)
            }
            data.append(row)
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("3D 표면 차트")
                    .font(.title2)
                    .bold()
                
                Text("수학적 함수 시각화: z = sin(x) × cos(y) × e^(-r/5)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Label("X 회전: \(Int(rotationX))°", systemImage: "rotate.left")
                        .font(.caption)
                    Label("Z 회전: \(Int(rotationZ))°", systemImage: "rotate.3d")
                        .font(.caption)
                    Label("줌: \(Int(zoomLevel * 100))%", systemImage: "magnifyingglass")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 3D 표면 렌더링
            GeometryReader { geometry in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let scale = min(size.width, size.height) / 4 * zoomLevel
                    
                    // 표면 그리드 그리기
                    let data = surfaceData
                    let gridSize = data.count
                    
                    for i in 0..<gridSize-1 {
                        for j in 0..<gridSize-1 {
                            // 각 셀의 4개 꼭지점
                            let p1 = project3D(x: i, y: j, z: data[i][j], 
                                             gridSize: gridSize, center: center, scale: scale)
                            let p2 = project3D(x: i+1, y: j, z: data[i+1][j], 
                                             gridSize: gridSize, center: center, scale: scale)
                            let p3 = project3D(x: i+1, y: j+1, z: data[i+1][j+1], 
                                             gridSize: gridSize, center: center, scale: scale)
                            let p4 = project3D(x: i, y: j+1, z: data[i][j+1], 
                                             gridSize: gridSize, center: center, scale: scale)
                            
                            // 평균 높이로 색상 결정
                            let avgZ = (data[i][j] + data[i+1][j] + data[i+1][j+1] + data[i][j+1]) / 4
                            
                            // 면 그리기
                            var path = Path()
                            path.move(to: p1)
                            path.addLine(to: p2)
                            path.addLine(to: p3)
                            path.addLine(to: p4)
                            path.closeSubpath()
                            
                            if wireframe {
                                context.stroke(
                                    path,
                                    with: .color(colorScheme.color(for: avgZ)),
                                    lineWidth: 0.5
                                )
                            } else {
                                context.fill(
                                    path,
                                    with: .color(colorScheme.color(for: avgZ).opacity(0.8 * animationProgress))
                                )
                                context.stroke(
                                    path,
                                    with: .color(.gray.opacity(0.2)),
                                    lineWidth: 0.5
                                )
                            }
                        }
                    }
                    
                    // 축 그리기
                    drawAxes(context: context, center: center, scale: scale)
                }
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.05), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
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
                .onTapGesture(count: 2) {
                    withAnimation {
                        rotationX = 30
                        rotationZ = 45
                        zoomLevel = 1.0
                    }
                }
            }
            .frame(height: 400)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animationProgress = 1.0
                }
            }
            
            // 색상 범례
            HStack {
                Text("최소")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(0..<50, id: \.self) { i in
                            Rectangle()
                                .fill(colorScheme.color(for: Double(i) / 25 - 1))
                                .frame(width: geometry.size.width / 50)
                        }
                    }
                }
                .frame(height: 20)
                .cornerRadius(10)
                
                Text("최대")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 컨트롤
            VStack(spacing: 15) {
                // 색상 스킴
                Picker("색상 스킴", selection: $colorScheme) {
                    ForEach(ColorScheme.allCases, id: \.self) { scheme in
                        Text(scheme.rawValue).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                
                // 줌 슬라이더
                HStack {
                    Text("확대/축소")
                        .font(.caption)
                    Slider(value: $zoomLevel, in: 0.5...2.0)
                    Text("\(Int(zoomLevel * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                // 옵션
                HStack {
                    Toggle("와이어프레임", isOn: $wireframe)
                    
                    Spacer()
                    
                    Button("초기화") {
                        withAnimation {
                            rotationX = 30
                            rotationZ = 45
                            zoomLevel = 1.0
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("애니메이션") {
                        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                            rotationZ += 360
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 3D 점을 2D로 투영
    func project3D(x: Int, y: Int, z: Double, gridSize: Int, center: CGPoint, scale: CGFloat) -> CGPoint {
        // 정규화된 좌표 (-1 to 1)
        let nx = (Double(x) / Double(gridSize) - 0.5) * 2
        let ny = (Double(y) / Double(gridSize) - 0.5) * 2
        let nz = z
        
        // 회전 변환
        let radX = rotationX * .pi / 180
        let radZ = rotationZ * .pi / 180
        
        // Z축 회전
        let x1 = nx * cos(radZ) - ny * sin(radZ)
        let y1 = nx * sin(radZ) + ny * cos(radZ)
        let z1 = nz
        
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
    
    // 축 그리기
    func drawAxes(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        let axisLength: CGFloat = 1.5
        
        // X축 (빨강)
        let xStart = project3D(x: 0, y: 15, z: 0, gridSize: 30, center: center, scale: scale)
        let xEnd = project3D(x: 30, y: 15, z: 0, gridSize: 30, center: center, scale: scale)
        
        context.stroke(
            Path { path in
                path.move(to: xStart)
                path.addLine(to: xEnd)
            },
            with: .color(.red.opacity(0.5)),
            lineWidth: 2
        )
        
        // Y축 (초록)
        let yStart = project3D(x: 15, y: 0, z: 0, gridSize: 30, center: center, scale: scale)
        let yEnd = project3D(x: 15, y: 30, z: 0, gridSize: 30, center: center, scale: scale)
        
        context.stroke(
            Path { path in
                path.move(to: yStart)
                path.addLine(to: yEnd)
            },
            with: .color(.green.opacity(0.5)),
            lineWidth: 2
        )
    }
}