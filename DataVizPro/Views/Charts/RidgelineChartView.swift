import SwiftUI

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

struct StreamGraphView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedStream: String?
    @State private var smoothing: Double = 0.5
    @State private var animationProgress: Double = 0
    
    // 스트림 그래프 데이터
    var streamData: [[Double]] {
        let categories = 5
        let timePoints = 20
        var data: [[Double]] = []
        
        for _ in 0..<categories {
            var stream: [Double] = []
            var value = Double.random(in: 20...40)
            
            for _ in 0..<timePoints {
                value += Double.random(in: -10...10)
                value = max(10, min(50, value))
                stream.append(value)
            }
            
            data.append(stream)
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("스트림 그래프")
                    .font(.title2)
                    .bold()
                
                Text("시계열 영역 흐름 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 스트림 그래프
            GeometryReader { geometry in
                Canvas { context, size in
                    let width = size.width
                    let height = size.height
                    let timePoints = streamData.first?.count ?? 0
                    let xStep = width / CGFloat(timePoints - 1)
                    
                    var baseline = Array(repeating: height / 2, count: timePoints)
                    let colors = [Color.blue, Color.green, Color.orange, Color.purple, Color.red]
                    
                    for (streamIndex, stream) in streamData.enumerated() {
                        var path = Path()
                        
                        // 상단 경로
                        for (index, value) in stream.enumerated() {
                            let x = CGFloat(index) * xStep
                            let y = baseline[index] - value * animationProgress
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                let prevX = CGFloat(index - 1) * xStep
                                let prevY = baseline[index - 1] - stream[index - 1] * animationProgress
                                let controlX = (prevX + x) / 2
                                path.addCurve(
                                    to: CGPoint(x: x, y: y),
                                    control1: CGPoint(x: controlX, y: prevY),
                                    control2: CGPoint(x: controlX, y: y)
                                )
                            }
                        }
                        
                        // 하단 경로
                        for index in (0..<timePoints).reversed() {
                            let x = CGFloat(index) * xStep
                            let y = baseline[index]
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        path.closeSubpath()
                        
                        context.fill(
                            path,
                            with: .color(colors[streamIndex % colors.count].opacity(0.7))
                        )
                        
                        // 다음 스트림을 위한 baseline 업데이트
                        for index in 0..<timePoints {
                            baseline[index] -= stream[index] * animationProgress
                        }
                    }
                }
            }
            .frame(height: 350)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    animationProgress = 1.0
                }
            }
            
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

struct DensityPlotView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var bandwidth: Double = 5.0
    @State private var showFill = true
    @State private var selectedDataset: Int = 0
    @State private var animationProgress: Double = 0
    
    // 밀도 데이터 생성
    var densityData: [(x: Double, density: Double)] {
        let values = generateDataset(selectedDataset)
        return calculateKernelDensity(values: values, bandwidth: bandwidth)
    }
    
    func generateDataset(_ index: Int) -> [Double] {
        switch index {
        case 0: // 정규분포
            return (0..<200).map { _ in
                let u1 = Double.random(in: 0...1)
                let u2 = Double.random(in: 0...1)
                let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
                return 50 + z * 15
            }.map { max(0, min(100, $0)) }
            
        case 1: // 이봉분포
            return (0..<200).map { _ in
                if Bool.random() {
                    return Double.random(in: 20...40)
                } else {
                    return Double.random(in: 60...80)
                }
            }
            
        default: // 치우친 분포
            return (0..<200).map { _ in
                pow(Double.random(in: 0...1), 2) * 100
            }
        }
    }
    
    func calculateKernelDensity(values: [Double], bandwidth: Double) -> [(x: Double, density: Double)] {
        var result: [(Double, Double)] = []
        
        for x in stride(from: 0, through: 100, by: 1) {
            var density = 0.0
            
            for value in values {
                let diff = (x - value) / bandwidth
                density += exp(-0.5 * diff * diff) / sqrt(2 * .pi)
            }
            
            density /= (Double(values.count) * bandwidth)
            result.append((x, density))
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("밀도 플롯")
                    .font(.title2)
                    .bold()
                
                Text("확률 밀도 함수 추정")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 밀도 플롯
            Chart(densityData, id: \.x) { item in
                if showFill {
                    AreaMark(
                        x: .value("X", item.x),
                        y: .value("밀도", item.density * animationProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                LineMark(
                    x: .value("X", item.x),
                    y: .value("밀도", item.density * animationProgress)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 350)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 데이터셋 선택
            Picker("데이터셋", selection: $selectedDataset) {
                Text("정규분포").tag(0)
                Text("이봉분포").tag(1)
                Text("치우친 분포").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedDataset) { _ in
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            
            // 대역폭 조절
            VStack(spacing: 8) {
                HStack {
                    Text("대역폭 (Bandwidth)")
                        .font(.caption)
                    Slider(value: $bandwidth, in: 1...20)
                    Text(String(format: "%.1f", bandwidth))
                        .font(.caption)
                        .frame(width: 40)
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            HStack {
                Toggle("영역 채우기", isOn: $showFill)
                
                Spacer()
                
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.2)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
    }
}