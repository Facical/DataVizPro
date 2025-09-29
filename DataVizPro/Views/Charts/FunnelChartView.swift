import SwiftUI

struct FunnelChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var animationProgress: Double = 0
    @State private var selectedStage: FunnelData?
    @State private var funnelStyle: FunnelStyle = .standard
    @State private var showPercentages = true
    @State private var show3D = false
    
    enum FunnelStyle: String, CaseIterable {
        case standard = "표준"
        case curved = "곡선"
        case stepped = "계단"
        case pyramid = "피라미드"
    }
    
    var totalValue: Double {
        dataManager.funnelData.first?.value ?? 1
    }
    
    // 평균 전환율 계산을 별도 프로퍼티로 분리
    var averageConversionRate: Int {
        let rates = dataManager.funnelData.compactMap { $0.conversionRate }
        let sum = rates.reduce(0, +)
        let count = Double(max(dataManager.funnelData.count, 1))
        return Int((sum / count) * 100)
    }
    
    // 전체 전환율 계산
    var overallConversionRate: Int {
        guard let firstValue = dataManager.funnelData.first?.value,
              let lastValue = dataManager.funnelData.last?.value,
              firstValue > 0 else { return 0 }
        return Int((lastValue / firstValue) * 100)
    }
    
    // 총 이탈값 계산
    var totalDropoff: Int {
        let firstValue = dataManager.funnelData.first?.value ?? 0
        let lastValue = dataManager.funnelData.last?.value ?? 0
        return Int(firstValue - lastValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("퍼널 차트")
                    .font(.title2)
                    .bold()
                
                Text("전환율 분석")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 전체 전환율
                if let firstValue = dataManager.funnelData.first?.value,
                   let lastValue = dataManager.funnelData.last?.value {
                    let conversionRatio = lastValue / firstValue
                    
                    HStack(spacing: 20) {
                        ConversionMetric(
                            label: "전체 전환율",
                            value: "\(overallConversionRate)%",
                            trend: conversionRatio > 0.1 ? .up : .down
                        )
                        
                        ConversionMetric(
                            label: "총 이탈",
                            value: "\(totalDropoff)",
                            trend: .down
                        )
                        
                        ConversionMetric(
                            label: "평균 전환",
                            value: "\(averageConversionRate)%",
                            trend: .neutral
                        )
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            // 메인 퍼널 차트
            GeometryReader { geometry in
                ZStack {
                    switch funnelStyle {
                    case .standard:
                        StandardFunnelView(
                            data: dataManager.funnelData,
                            selectedStage: selectedStage,
                            animationProgress: animationProgress,
                            showPercentages: showPercentages,
                            show3D: show3D,
                            geometry: geometry
                        ) { stage in
                            withAnimation(.spring()) {
                                selectedStage = selectedStage?.id == stage.id ? nil : stage
                            }
                        }
                        
                    case .curved:
                        CurvedFunnelView(
                            data: dataManager.funnelData,
                            selectedStage: selectedStage,
                            animationProgress: animationProgress,
                            showPercentages: showPercentages,
                            geometry: geometry
                        ) { stage in
                            withAnimation(.spring()) {
                                selectedStage = selectedStage?.id == stage.id ? nil : stage
                            }
                        }
                        
                    case .stepped:
                        SteppedFunnelView(
                            data: dataManager.funnelData,
                            selectedStage: selectedStage,
                            animationProgress: animationProgress,
                            showPercentages: showPercentages,
                            geometry: geometry
                        ) { stage in
                            withAnimation(.spring()) {
                                selectedStage = selectedStage?.id == stage.id ? nil : stage
                            }
                        }
                        
                    case .pyramid:
                        PyramidFunnelView(
                            data: dataManager.funnelData,
                            selectedStage: selectedStage,
                            animationProgress: animationProgress,
                            showPercentages: showPercentages,
                            geometry: geometry
                        ) { stage in
                            withAnimation(.spring()) {
                                selectedStage = selectedStage?.id == stage.id ? nil : stage
                            }
                        }
                    }
                }
            }
            .frame(height: 400)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 선택된 단계 상세 정보
            if let stage = selectedStage {
                StageDetailView(stage: stage, totalValue: totalValue)
                    .padding()
                    .background(stage.color.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            // 스타일 선택
            Picker("스타일", selection: $funnelStyle) {
                ForEach(FunnelStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: funnelStyle) { _ in
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            
            // 컨트롤
            HStack {
                Toggle("백분율 표시", isOn: $showPercentages)
                
                Toggle("3D 효과", isOn: $show3D)
                    .disabled(funnelStyle == .pyramid)
                
                Spacer()
                
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.5)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
    }
}

// 표준 퍼널 뷰
struct StandardFunnelView: View {
    let data: [FunnelData]
    let selectedStage: FunnelData?
    let animationProgress: Double
    let showPercentages: Bool
    let show3D: Bool
    let geometry: GeometryProxy
    let onSelect: (FunnelData) -> Void
    
    var body: some View {
        VStack(spacing: show3D ? -5 : 2) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, stage in
                let widthRatio = stage.value / (data.first?.value ?? 1)
                let width = geometry.size.width * widthRatio * animationProgress
                
                Button(action: { onSelect(stage) }) {
                    ZStack {
                        // 메인 바
                        FunnelSegment(
                            width: width,
                            height: geometry.size.height / CGFloat(data.count) - 10,
                            color: stage.color,
                            isSelected: selectedStage?.id == stage.id,
                            show3D: show3D
                        )
                        
                        // 레이블
                        HStack {
                            Text(stage.stage)
                                .font(.system(.body, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(stage.value))")
                                    .font(.system(.caption, design: .rounded))
                                    .bold()
                                    .foregroundColor(.white)
                                
                                if showPercentages {
                                    Text("\(Int(stage.conversionRate * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(width: width)
                    }
                    .frame(width: width, height: geometry.size.height / CGFloat(data.count) - 10)
                }
                .buttonStyle(.plain)
                
                // 전환 화살표
                if index < data.count - 1 {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .opacity(animationProgress)
                }
            }
        }
    }
}

// 곡선 퍼널 뷰
struct CurvedFunnelView: View {
    let data: [FunnelData]
    let selectedStage: FunnelData?
    let animationProgress: Double
    let showPercentages: Bool
    let geometry: GeometryProxy
    let onSelect: (FunnelData) -> Void
    
    var body: some View {
        Canvas { context, size in
            let segmentHeight = size.height / CGFloat(data.count)
            
            for (index, stage) in data.enumerated() {
                let y = CGFloat(index) * segmentHeight
                let topWidth = size.width * (stage.value / (data.first?.value ?? 1)) * animationProgress
                let bottomWidth = index < data.count - 1
                    ? size.width * (data[index + 1].value / (data.first?.value ?? 1)) * animationProgress
                    : topWidth * 0.3
                
                // 곡선 경로 생성
                var path = Path()
                path.move(to: CGPoint(x: (size.width - topWidth) / 2, y: y))
                
                // 베지어 곡선으로 연결
                path.addCurve(
                    to: CGPoint(x: (size.width - bottomWidth) / 2, y: y + segmentHeight),
                    control1: CGPoint(x: (size.width - topWidth) / 2 - 20, y: y + segmentHeight * 0.3),
                    control2: CGPoint(x: (size.width - bottomWidth) / 2 - 20, y: y + segmentHeight * 0.7)
                )
                
                path.addLine(to: CGPoint(x: (size.width + bottomWidth) / 2, y: y + segmentHeight))
                
                path.addCurve(
                    to: CGPoint(x: (size.width + topWidth) / 2, y: y),
                    control1: CGPoint(x: (size.width + bottomWidth) / 2 + 20, y: y + segmentHeight * 0.7),
                    control2: CGPoint(x: (size.width + topWidth) / 2 + 20, y: y + segmentHeight * 0.3)
                )
                
                path.closeSubpath()
                
                // 그라데이션 채우기 (Canvas용)
                let gradient = Gradient(colors: [stage.color, stage.color.opacity(0.7)])
                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: size.width / 2, y: y),
                        endPoint: CGPoint(x: size.width / 2, y: y + segmentHeight)
                    )
                )
                
                if selectedStage?.id == stage.id {
                    context.stroke(path, with: .color(.white), lineWidth: 3)
                }
                
                // 텍스트 레이블
                let text = Text(stage.stage)
                    .font(.system(.body, weight: .medium))
                    .foregroundColor(.white)
                
                context.draw(
                    text,
                    at: CGPoint(x: size.width / 2, y: y + segmentHeight / 2)
                )
                
                if showPercentages {
                    let percentText = Text("\(Int(stage.conversionRate * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    context.draw(
                        percentText,
                        at: CGPoint(x: size.width / 2, y: y + segmentHeight / 2 + 20)
                    )
                }
            }
        }
    }
}

// 계단식 퍼널 뷰
struct SteppedFunnelView: View {
    let data: [FunnelData]
    let selectedStage: FunnelData?
    let animationProgress: Double
    let showPercentages: Bool
    let geometry: GeometryProxy
    let onSelect: (FunnelData) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, stage in
                let height = geometry.size.height * (stage.value / (data.first?.value ?? 1)) * animationProgress
                
                Button(action: { onSelect(stage) }) {
                    VStack {
                        Spacer()
                        
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [stage.color, stage.color.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: height)
                                .overlay(
                                    Rectangle()
                                        .stroke(selectedStage?.id == stage.id ? Color.white : Color.clear, lineWidth: 2)
                                )
                            
                            VStack(spacing: 4) {
                                Text(stage.stage)
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(-45))
                                
                                if showPercentages {
                                    Text("\(Int(stage.value))")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(width: geometry.size.width / CGFloat(data.count))
                
                // 화살표
                if index < data.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .opacity(animationProgress)
                }
            }
        }
    }
}

// 피라미드 퍼널 뷰
struct PyramidFunnelView: View {
    let data: [FunnelData]
    let selectedStage: FunnelData?
    let animationProgress: Double
    let showPercentages: Bool
    let geometry: GeometryProxy
    let onSelect: (FunnelData) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, stage in
                let widthRatio = stage.value / (data.first?.value ?? 1)
                let width = geometry.size.width * widthRatio * animationProgress
                
                Button(action: { onSelect(stage) }) {
                    PyramidSegment(
                        topWidth: width,
                        bottomWidth: index < data.count - 1
                            ? geometry.size.width * (data[index + 1].value / (data.first?.value ?? 1)) * animationProgress
                            : width * 0.5,
                        height: geometry.size.height / CGFloat(data.count),
                        color: stage.color,
                        label: stage.stage,
                        value: Int(stage.value),
                        percentage: Int(stage.conversionRate * 100),
                        showPercentage: showPercentages,
                        isSelected: selectedStage?.id == stage.id
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 퍼널 세그먼트
struct FunnelSegment: View {
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let isSelected: Bool
    let show3D: Bool
    
    var body: some View {
        ZStack {
            if show3D {
                // 3D 효과
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width, height: height)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: width, height: height)
            }
            
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: width, height: height)
            }
        }
    }
}

// 피라미드 세그먼트
struct PyramidSegment: View {
    let topWidth: CGFloat
    let bottomWidth: CGFloat
    let height: CGFloat
    let color: Color
    let label: String
    let value: Int
    let percentage: Int
    let showPercentage: Bool
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 사다리꼴 모양
                Path { path in
                    let centerX = geometry.size.width / 2
                    path.move(to: CGPoint(x: centerX - topWidth / 2, y: 0))
                    path.addLine(to: CGPoint(x: centerX + topWidth / 2, y: 0))
                    path.addLine(to: CGPoint(x: centerX + bottomWidth / 2, y: height))
                    path.addLine(to: CGPoint(x: centerX - bottomWidth / 2, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                if isSelected {
                    Path { path in
                        let centerX = geometry.size.width / 2
                        path.move(to: CGPoint(x: centerX - topWidth / 2, y: 0))
                        path.addLine(to: CGPoint(x: centerX + topWidth / 2, y: 0))
                        path.addLine(to: CGPoint(x: centerX + bottomWidth / 2, y: height))
                        path.addLine(to: CGPoint(x: centerX - bottomWidth / 2, y: height))
                        path.closeSubpath()
                    }
                    .stroke(Color.white, lineWidth: 3)
                }
                
                // 레이블
                VStack(spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                    
                    if showPercentage {
                        Text("\(value) (\(percentage)%)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("\(value)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .frame(height: height)
    }
}

// 전환 지표
struct ConversionMetric: View {
    let label: String
    let value: String
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .bold()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
        }
    }
}

// 단계 상세 정보
struct StageDetailView: View {
    let stage: FunnelData
    let totalValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(stage.color)
                    .frame(width: 12, height: 12)
                Text(stage.stage)
                    .font(.headline)
            }
            
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("절대값")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(stage.value))")
                        .font(.title3)
                        .bold()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("전환율")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(stage.conversionRate * 100))%")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("이탈률")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(stage.dropoffRate * 100))%")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("전체 대비")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(stage.value / totalValue * 100))%")
                        .font(.title3)
                        .bold()
                }
            }
        }
    }
}
