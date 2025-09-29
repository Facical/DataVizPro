import SwiftUI
import Charts

struct RidgelineChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedRidge: String?
    @State private var overlap: Double = 0.5
    @State private var animationProgress: Double = 0
    
    // 리지라인 데이터 생성
    var ridgelineData: [RidgelineData] {
        let categories = ["2020", "2021", "2022", "2023", "2024"]
        let colors = [Color.blue, Color.green, Color.orange, Color.purple, Color.red]
        
        return categories.enumerated().map { index, category in
            // 각 연도별로 다른 분포 생성
            var values: [Double] = []
            let mean = 50.0 + Double(index) * 5
            let stdDev = 15.0 - Double(index) * 2
            
            for _ in 0..<200 {
                let u1 = Double.random(in: 0...1)
                let u2 = Double.random(in: 0...1)
                let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
                let value = mean + z * stdDev
                values.append(max(0, min(100, value)))
            }
            
            return RidgelineData(
                category: category,
                values: values,
                offset: Double(index) * 50,
                color: colors[index]
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("리지라인 차트")
                    .font(.title2)
                    .bold()
                
                Text("시간별 분포 변화 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let selected = selectedRidge {
                    Text("\(selected) 데이터 선택됨")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            
            // 리지라인 차트
            GeometryReader { geometry in
                ZStack {
                    ForEach(ridgelineData.reversed()) { ridge in
                        RidgePath(
                            data: ridge,
                            width: geometry.size.width,
                            height: 100,
                            overlap: overlap,
                            isSelected: selectedRidge == ridge.category,
                            animationProgress: animationProgress
                        )
                        .offset(y: ridge.offset * (1 - overlap))
                        .onTapGesture {
                            withAnimation {
                                if selectedRidge == ridge.category {
                                    selectedRidge = nil
                                } else {
                                    selectedRidge = ridge.category
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
                withAnimation(.easeOut(duration: 1.5)) {
                    animationProgress = 1.0
                }
            }
            
            // 겹침 조절
            VStack(spacing: 8) {
                HStack {
                    Text("겹침 정도")
                        .font(.caption)
                    Slider(value: $overlap, in: 0...0.8)
                    Text("\(Int(overlap * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                }
            }
            .padding(.horizontal)
            
            // 범례
            HStack(spacing: 15) {
                ForEach(ridgelineData) { ridge in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(ridge.color)
                            .frame(width: 10, height: 10)
                        Text(ridge.category)
                            .font(.caption)
                            .foregroundColor(selectedRidge == ridge.category ? ridge.color : .primary)
                    }
                }
            }
            .padding(.horizontal)
            
            Button("애니메이션 재생") {
                animationProgress = 0
                withAnimation(.easeOut(duration: 2.0)) {
                    animationProgress = 1.0
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
    }
}

// 리지 경로 컴포넌트
struct RidgePath: View {
    let data: RidgelineData
    let width: CGFloat
    let height: CGFloat
    let overlap: Double
    let isSelected: Bool
    let animationProgress: Double
    
    var density: [Double] {
        // 간단한 밀도 계산
        let bins = 50
        var histogram = Array(repeating: 0.0, count: bins)
        
        for value in data.values {
            let bin = Int(value / 100 * Double(bins))
            if bin >= 0 && bin < bins {
                histogram[bin] += 1
            }
        }
        
        // 정규화
        let maxCount = histogram.max() ?? 1
        return histogram.map { $0 / maxCount }
    }
    
    var body: some View {
        ZStack {
            // 채우기
            Path { path in
                let binWidth = width / CGFloat(density.count)
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for (index, value) in density.enumerated() {
                    let x = CGFloat(index) * binWidth
                    let y = height - (value * height * animationProgress)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        data.color.opacity(0.6),
                        data.color.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // 윤곽선
            Path { path in
                let binWidth = width / CGFloat(density.count)
                
                for (index, value) in density.enumerated() {
                    let x = CGFloat(index) * binWidth
                    let y = height - (value * height * animationProgress)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(data.color, lineWidth: isSelected ? 3 : 1.5)
            
            // 카테고리 레이블
            Text(data.category)
                .font(.caption)
                .bold()
                .foregroundColor(isSelected ? data.color : .secondary)
                .position(x: 30, y: height - 10)
        }
        .frame(width: width, height: height)
    }
}

// StreamGraphView와 DensityPlotView는 별도 파일에 이미 존재하므로 제거됨