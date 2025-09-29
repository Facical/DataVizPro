import SwiftUI

struct GaugeChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var animationProgress: Double = 0
    @State private var selectedGauge: GaugeData?
    @State private var gaugeStyle: GaugeStyle = .arc
    
    enum GaugeStyle: String, CaseIterable {
        case arc = "원형"
        case linear = "선형"
        case semicircle = "반원"
        case speedometer = "속도계"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("게이지 차트")
                    .font(.title2)
                    .bold()
                
                Text("실시간 성능 모니터링")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 게이지 그리드
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(dataManager.gaugeData) { gauge in
                    GaugeCard(
                        data: gauge,
                        style: gaugeStyle,
                        progress: animationProgress,
                        isSelected: selectedGauge?.id == gauge.id
                    ) {
                        withAnimation(.spring()) {
                            selectedGauge = selectedGauge?.id == gauge.id ? nil : gauge
                        }
                    }
                }
            }
            .padding()
            
            // 선택된 게이지 상세 정보
            if let gauge = selectedGauge {
                GaugeDetailView(gauge: gauge)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            // 스타일 선택
            Picker("스타일", selection: $gaugeStyle) {
                ForEach(GaugeStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: gaugeStyle) { _ in
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            
            // 컨트롤
            HStack {
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.5)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("값 갱신") {
                    dataManager.gaugeData = dataManager.gaugeData.map { gauge in
                        var newGauge = gauge
                        let range = gauge.max - gauge.min
                        let randomValue = gauge.min + Double.random(in: 0...range)
                        return GaugeData(
                            name: gauge.name,
                            value: randomValue,
                            min: gauge.min,
                            max: gauge.max,
                            thresholds: gauge.thresholds
                        )
                    }
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.0)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
}

// 게이지 카드
struct GaugeCard: View {
    let data: GaugeData
    let style: GaugeChartView.GaugeStyle
    let progress: Double
    let isSelected: Bool
    let action: () -> Void
    
    var currentValue: Double {
        data.value * progress
    }
    
    var percentage: Double {
        (currentValue - data.min) / (data.max - data.min)
    }
    
    var currentThreshold: GaugeData.Threshold? {
        data.thresholds.last(where: { currentValue >= $0.value })
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(data.name)
                    .font(.headline)
                
                ZStack {
                    switch style {
                    case .arc:
                        ArcGaugeView(
                            value: percentage,
                            thresholds: data.thresholds,
                            min: data.min,
                            max: data.max,
                            currentValue: currentValue
                        )
                        
                    case .linear:
                        LinearGaugeView(
                            value: percentage,
                            thresholds: data.thresholds,
                            min: data.min,
                            max: data.max,
                            currentValue: currentValue
                        )
                        
                    case .semicircle:
                        SemicircleGaugeView(
                            value: percentage,
                            thresholds: data.thresholds,
                            min: data.min,
                            max: data.max,
                            currentValue: currentValue
                        )
                        
                    case .speedometer:
                        SpeedometerGaugeView(
                            value: percentage,
                            thresholds: data.thresholds,
                            min: data.min,
                            max: data.max,
                            currentValue: currentValue
                        )
                    }
                }
                .frame(height: 150)
                
                // 현재 값과 상태
                VStack(spacing: 4) {
                    Text("\(Int(currentValue))")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                    
                    if let threshold = currentThreshold {
                        Label(threshold.label, systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(threshold.color)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? currentThreshold?.color.opacity(0.3) ?? .gray.opacity(0.1) : .gray.opacity(0.1),
                        radius: isSelected ? 15 : 5,
                        x: 0,
                        y: 5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? currentThreshold?.color ?? .blue : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// 원형 게이지
struct ArcGaugeView: View {
    let value: Double
    let thresholds: [GaugeData.Threshold]
    let min: Double
    let max: Double
    let currentValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 원호
                Circle()
                    .trim(from: 0.2, to: 0.8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .rotationEffect(.degrees(90))
                
                // 임계값 구간
                ForEach(Array(thresholds.enumerated()), id: \.offset) { index, threshold in
                    let startValue = index == 0 ? min : thresholds[index - 1].value
                    let startAngle = 0.2 + (startValue - min) / (max - min) * 0.6
                    let endAngle = 0.2 + (threshold.value - min) / (max - min) * 0.6
                    
                    Circle()
                        .trim(from: startAngle, to: endAngle)
                        .stroke(threshold.color.opacity(0.3), lineWidth: 20)
                        .rotationEffect(.degrees(90))
                }
                
                // 현재 값
                Circle()
                    .trim(from: 0.2, to: 0.2 + value * 0.6)
                    .stroke(
                        thresholds.last(where: { currentValue >= $0.value })?.color ?? .blue,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                
                // 중앙 텍스트
                VStack(spacing: 2) {
                    Text("\(Int(currentValue))")
                        .font(.system(.title, design: .rounded))
                        .bold()
                    Text("/ \(Int(max))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// 선형 게이지
struct LinearGaugeView: View {
    let value: Double
    let thresholds: [GaugeData.Threshold]
    let min: Double
    let max: Double
    let currentValue: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // 값 표시
            HStack {
                Text("\(Int(min))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(currentValue))")
                    .font(.system(.body, design: .rounded))
                    .bold()
                Spacer()
                Text("\(Int(max))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 게이지 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    // 임계값 구간
                    HStack(spacing: 0) {
                        ForEach(Array(thresholds.enumerated()), id: \.offset) { index, threshold in
                            let width = geometry.size.width * ((threshold.value - (index == 0 ? min : thresholds[index - 1].value)) / (max - min))
                            Rectangle()
                                .fill(threshold.color.opacity(0.3))
                                .frame(width: width)
                        }
                    }
                    .cornerRadius(8)
                    
                    // 현재 값
                    RoundedRectangle(cornerRadius: 8)
                        .fill(thresholds.last(where: { currentValue >= $0.value })?.color ?? .blue)
                        .frame(width: geometry.size.width * value)
                    
                    // 포인터
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(thresholds.last(where: { currentValue >= $0.value })?.color ?? .blue, lineWidth: 3)
                        )
                        .offset(x: geometry.size.width * value - 8)
                }
            }
            .frame(height: 16)
        }
    }
}

// 반원 게이지
struct SemicircleGaugeView: View {
    let value: Double
    let thresholds: [GaugeData.Threshold]
    let min: Double
    let max: Double
    let currentValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 반원
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                
                // 현재 값
                Circle()
                    .trim(from: 0.5, to: 0.5 + value * 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [
                                thresholds.first?.color ?? .blue,
                                thresholds.last(where: { currentValue >= $0.value })?.color ?? .blue
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                
                // 중앙 값
                VStack {
                    Spacer()
                    Text("\(Int(percentage * 100))%")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    var percentage: Double {
        (currentValue - min) / (max - min)
    }
}

// 속도계 스타일 게이지
struct SpeedometerGaugeView: View {
    let value: Double
    let thresholds: [GaugeData.Threshold]
    let min: Double
    let max: Double
    let currentValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.8)
            
            ZStack {
                // 눈금
                ForEach(0..<11, id: \.self) { tick in
                    let angle = Double(tick) / 10.0 * 180.0 - 90.0
                    let radian = angle * .pi / 180.0
                    let isMain = tick % 2 == 0
                    
                    Path { path in
                        let startRadius = geometry.size.width / 2 - 25
                        let endRadius = geometry.size.width / 2 - (isMain ? 15 : 20)
                        
                        path.move(to: CGPoint(
                            x: center.x + cos(radian) * startRadius,
                            y: center.y + sin(radian) * startRadius
                        ))
                        path.addLine(to: CGPoint(
                            x: center.x + cos(radian) * endRadius,
                            y: center.y + sin(radian) * endRadius
                        ))
                    }
                    .stroke(Color.gray.opacity(isMain ? 0.8 : 0.4), lineWidth: isMain ? 2 : 1)
                }
                
                // 바늘
                let needleAngle = -90 + value * 180
                let needleRadian = needleAngle * .pi / 180
                
                Path { path in
                    path.move(to: center)
                    path.addLine(to: CGPoint(
                        x: center.x + cos(needleRadian) * (geometry.size.width / 2 - 30),
                        y: center.y + sin(needleRadian) * (geometry.size.width / 2 - 30)
                    ))
                }
                .stroke(
                    thresholds.last(where: { currentValue >= $0.value })?.color ?? .blue,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                
                // 중심점
                Circle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 12)
                    .position(center)
            }
        }
    }
}

// 게이지 상세 정보
struct GaugeDetailView: View {
    let gauge: GaugeData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(gauge.name)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 값")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(gauge.value))")
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("범위")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(gauge.min)) - \(Int(gauge.max))")
                        .font(.title3)
                        .bold()
                }
            }
            
            Divider()
            
            Text("임계값")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(gauge.thresholds, id: \.value) { threshold in
                HStack {
                    Circle()
                        .fill(threshold.color)
                        .frame(width: 8, height: 8)
                    Text(threshold.label)
                        .font(.caption)
                    Spacer()
                    Text("≥ \(Int(threshold.value))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}