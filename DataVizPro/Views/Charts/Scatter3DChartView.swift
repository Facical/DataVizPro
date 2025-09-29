import SwiftUI
import Charts
import RealityKit

// 3D 산점도 데이터 모델
struct Point3DEnhanced: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let z: Double
    let category: String
    let size: Double
    let temperature: Double // 추가 차원
}

struct Scatter3DChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var rotationAngle: Double = 0
    @State private var selectedPoint: Point3DEnhanced?
    @State private var viewAngle: Double = 45
    @State private var zoomLevel: Double = 1.0
    
    // 샘플 데이터 생성
    var data3D: [Point3DEnhanced] {
        (0..<200).map { _ in
            Point3DEnhanced(
                x: Double.random(in: -50...50),
                y: Double.random(in: -50...50),
                z: Double.random(in: -50...50),
                category: ["클러스터 A", "클러스터 B", "클러스터 C", "클러스터 D"].randomElement()!,
                size: Double.random(in: 5...20),
                temperature: Double.random(in: 0...100)
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("3D 산점도 - 다차원 데이터 시각화")
                .font(.title2)
                .bold()
            
            // 3D 시각화 영역
            GeometryReader { geometry in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    // 3D 투영 및 렌더링
                    for point in data3D.sorted(by: { $0.z < $1.z }) {
                        let projected = project3DPoint(
                            point: point,
                            center: center,
                            rotation: rotationAngle,
                            angle: viewAngle,
                            zoom: zoomLevel
                        )
                        
                        // 깊이에 따른 크기 조정
                        let depthScale = 1.0 + (point.z / 100)
                        let radius = point.size * depthScale * zoomLevel
                        
                        // 온도에 따른 색상
                        let color = colorForTemperature(point.temperature)
                        
                        // 포인트 그리기
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: projected.x - radius,
                                y: projected.y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )),
                            with: .color(color.opacity(0.7))
                        )
                        
                        // 선택된 포인트 강조
                        if point.id == selectedPoint?.id {
                            context.stroke(
                                Path(ellipseIn: CGRect(
                                    x: projected.x - radius - 2,
                                    y: projected.y - radius - 2,
                                    width: (radius + 2) * 2,
                                    height: (radius + 2) * 2
                                )),
                                with: .color(.white),
                                lineWidth: 2
                            )
                        }
                    }
                    
                    // 축 그리기
                    drawAxes(context: context, size: size, center: center)
                }
                .background(LinearGradient(
                    colors: [.black, .blue.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            rotationAngle += value.translation.width / 100
                            viewAngle += value.translation.height / 100
                            viewAngle = max(0, min(90, viewAngle))
                        }
                )
            }
            .frame(height: 500)
            .cornerRadius(12)
            .overlay(
                // 범례
                VStack(alignment: .leading) {
                    Text("온도")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    LinearGradient(
                        stops: [
                            .init(color: .blue, location: 0),
                            .init(color: .green, location: 0.25),
                            .init(color: .yellow, location: 0.5),
                            .init(color: .orange, location: 0.75),
                            .init(color: .red, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 100, height: 20)
                    .cornerRadius(4)
                    
                    HStack {
                        Text("0°C")
                        Spacer()
                        Text("100°C")
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .frame(width: 100)
                }
                .padding(10)
                .background(.black.opacity(0.5))
                .cornerRadius(8),
                alignment: .topTrailing
            )
            
            // 컨트롤
            VStack(spacing: 15) {
                HStack {
                    Text("줌 레벨")
                    Slider(value: $zoomLevel, in: 0.5...2.0)
                    Text("\(Int(zoomLevel * 100))%")
                        .frame(width: 50)
                }
                
                HStack {
                    Button("자동 회전") {
                        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                            rotationAngle += 360
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("초기화") {
                        withAnimation {
                            rotationAngle = 0
                            viewAngle = 45
                            zoomLevel = 1.0
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
    }
    
    func project3DPoint(point: Point3DEnhanced, center: CGPoint, rotation: Double, angle: Double, zoom: Double) -> CGPoint {
        let rad = rotation * .pi / 180
        let angleRad = angle * .pi / 180
        
        // 3D 회전 변환
        let x = point.x * cos(rad) - point.y * sin(rad)
        let y = point.x * sin(rad) * sin(angleRad) + point.y * cos(rad) * sin(angleRad) + point.z * cos(angleRad)
        
        // 2D 투영
        let scale = 3.0 * zoom
        return CGPoint(
            x: center.x + x * scale,
            y: center.y - y * scale
        )
    }
    
    func colorForTemperature(_ temp: Double) -> Color {
        let normalized = temp / 100
        
        if normalized < 0.25 {
            return .blue
        } else if normalized < 0.5 {
            return .green
        } else if normalized < 0.75 {
            return .yellow
        } else {
            return .red
        }
    }
    
    func drawAxes(context: GraphicsContext, size: CGSize, center: CGPoint) {
        let axisLength: CGFloat = 100
        
        // X축 (빨강)
        context.stroke(
            Path { path in
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x + axisLength, y: center.y))
            },
            with: .color(.red.opacity(0.5)),
            lineWidth: 2
        )
        
        // Y축 (초록)
        context.stroke(
            Path { path in
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x, y: center.y - axisLength))
            },
            with: .color(.green.opacity(0.5)),
            lineWidth: 2
        )
        
        // Z축 (파랑) - 대각선으로 표현
        context.stroke(
            Path { path in
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x - axisLength/2, y: center.y - axisLength/2))
            },
            with: .color(.blue.opacity(0.5)),
            lineWidth: 2
        )
    }
}
