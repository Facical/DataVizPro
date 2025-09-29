import SwiftUI

struct StreamGraphView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedSeries: String?
    @State private var interpolation: InterpolationType = .smooth
    @State private var stackType: StackType = .silhouette
    @State private var animationProgress: Double = 0
    
    enum InterpolationType: String, CaseIterable {
        case smooth = "부드럽게"
        case linear = "직선"
        case step = "계단"
    }
    
    enum StackType: String, CaseIterable {
        case silhouette = "실루엣"
        case wiggle = "웨이브"
        case expand = "확장"
        case zero = "제로 베이스"
    }
    
    // 샘플 스트림 데이터 생성
    func generateStreamData() -> [StreamGraphData] {
        var data: [StreamGraphData] = []
        let series = ["소셜", "검색", "직접", "이메일", "광고"]
        let points = 50
        
        for seriesName in series {
            var baseline = 0.0
            
            for i in 0..<points {
                let date = Date().addingTimeInterval(Double(i - points) * 86400)
                var value: Double
                
                // 시리즈별 다른 패턴 생성
                switch seriesName {
                case "소셜":
                    value = 30 + sin(Double(i) * 0.3) * 10 + Double.random(in: -5...5)
                case "검색":
                    value = 40 + cos(Double(i) * 0.2) * 15 + Double.random(in: -5...5)
                case "직접":
                    value = 25 + sin(Double(i) * 0.4) * 8 + Double.random(in: -3...3)
                case "이메일":
                    value = 20 + cos(Double(i) * 0.25) * 12 + Double.random(in: -4...4)
                case "광고":
                    value = 35 + sin(Double(i) * 0.35) * 20 + Double.random(in: -6...6)
                default:
                    value = 30
                }
                
                // 스택 타입에 따른 베이스라인 계산
                switch stackType {
                case .silhouette:
                    baseline = -value / 2
                case .wiggle:
                    baseline = baseline + Double.random(in: -5...5)
                case .expand:
                    baseline = 0
                case .zero:
                    baseline = 0
                }
                
                data.append(StreamGraphData(
                    date: date,
                    series: seriesName,
                    value: max(5, value),
                    baseline: baseline
                ))
            }
        }
        
        return data
    }
    
    var streamData: [StreamGraphData] {
        if dataManager.streamGraphData.isEmpty {
            return generateStreamData()
        }
        return dataManager.streamGraphData
    }
    
    var series: [String] {
        Array(Set(streamData.map { $0.series })).sorted()
    }
    
    var dates: [Date] {
        Array(Set(streamData.map { $0.date })).sorted()
    }
    
    func colorForSeries(_ series: String) -> Color {
        switch series {
        case "소셜": return .blue
        case "검색": return .green
        case "직접": return .orange
        case "이메일": return .purple
        case "광고": return .pink
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("스트림 그래프")
                    .font(.title2)
                    .bold()
                
                Text("시간에 따른 흐름 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 선택된 시리즈 정보
                if let selected = selectedSeries {
                    HStack {
                        Circle()
                            .fill(colorForSeries(selected))
                            .frame(width: 12, height: 12)
                        
                        Text(selected)
                            .font(.headline)
                        
                        Text("트래픽 소스")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let total = streamData.filter({ $0.series == selected }).map({ $0.value }).reduce(0, +) {
                            Text("총 \(Int(total))")
                                .font(.caption)
                                .bold()
                        }
                    }
                    .padding()
                    .background(colorForSeries(selected).opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // 스트림 그래프
            GeometryReader { geometry in
                Canvas { context, size in
                    let width = size.width
                    let height = size.height
                    
                    // 시리즈별로 스트림 그리기
                    for (index, seriesName) in series.enumerated() {
                        let seriesData = streamData.filter { $0.series == seriesName }
                        
                        var path = Path()
                        var bottomPath: [CGPoint] = []
                        
                        // 상단 경로 그리기
                        for (i, data) in seriesData.enumerated() {
                            let x = (Double(i) / Double(seriesData.count - 1)) * width
                            let previousSum = getPreviousSum(for: data.date, before: seriesName)
                            let y = height / 2 - (previousSum + data.value) * 2 * animationProgress
                            
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                if interpolation == .smooth {
                                    let prevData = seriesData[i - 1]
                                    let prevX = (Double(i - 1) / Double(seriesData.count - 1)) * width
                                    let prevSum = getPreviousSum(for: prevData.date, before: seriesName)
                                    let prevY = height / 2 - (prevSum + prevData.value) * 2 * animationProgress
                                    
                                    let controlX1 = prevX + (x - prevX) / 3
                                    let controlX2 = prevX + (x - prevX) * 2 / 3
                                    
                                    path.addCurve(
                                        to: CGPoint(x: x, y: y),
                                        control1: CGPoint(x: controlX1, y: prevY),
                                        control2: CGPoint(x: controlX2, y: y)
                                    )
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            
                            // 하단 경로를 위한 포인트 저장
                            bottomPath.append(CGPoint(
                                x: x,
                                y: height / 2 - previousSum * 2 * animationProgress
                            ))
                        }
                        
                        // 하단 경로 그리기 (역순)
                        for point in bottomPath.reversed() {
                            path.addLine(to: point)
                        }
                        
                        path.closeSubpath()
                        
                        // 채우기
                        let color = colorForSeries(seriesName)
                        let isSelected = selectedSeries == seriesName
                        
                        context.fill(
                            path,
                            with: .color(color.opacity(isSelected ? 0.8 : (selectedSeries == nil ? 0.6 : 0.2)))
                        )
                        
                        // 선택된 경우 테두리
                        if isSelected {
                            context.stroke(
                                path,
                                with: .color(.white),
                                lineWidth: 2
                            )
                        }
                    }
                    
                    // X축 레이블
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM/dd"
                    
                    for i in stride(from: 0, to: dates.count, by: max(1, dates.count / 5)) {
                        let x = (Double(i) / Double(dates.count - 1)) * width
                        let date = dates[i]
                        
                        context.draw(
                            Text(dateFormatter.string(from: date))
                                .font(.caption2)
                                .foregroundColor(.secondary),
                            at: CGPoint(x: x, y: height - 10)
                        )
                    }
                }
                .onTapGesture { location in
                    // 탭 위치에서 시리즈 찾기
                    let x = location.x
                    let y = location.y
                    
                    // 간단한 히트 테스트 로직
                    for seriesName in series.reversed() {
                        let seriesData = streamData.filter { $0.series == seriesName }
                        
                        for (i, data) in seriesData.enumerated() {
                            let dataX = (Double(i) / Double(seriesData.count - 1)) * geometry.size.width
                            
                            if abs(dataX - x) < 20 {
                                withAnimation(.spring()) {
                                    if selectedSeries == seriesName {
                                        selectedSeries = nil
                                    } else {
                                        selectedSeries = seriesName
                                    }
                                }
                                return
                            }
                        }
                    }
                }
            }
            .frame(height: 350)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(series, id: \.self) { seriesName in
                        StreamLegendItem(
                            name: seriesName,
                            color: colorForSeries(seriesName),
                            isSelected: selectedSeries == seriesName,
                            value: Int(streamData.filter { $0.series == seriesName }.map { $0.value }.reduce(0, +))
                        ) {
                            withAnimation(.spring()) {
                                if selectedSeries == seriesName {
                                    selectedSeries = nil
                                } else {
                                    selectedSeries = seriesName
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            VStack(spacing: 15) {
                HStack {
                    Text("보간 방법:")
                    Picker("보간", selection: $interpolation) {
                        ForEach(InterpolationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                HStack {
                    Text("스택 타입:")
                    Picker("스택", selection: $stackType) {
                        ForEach(StackType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: stackType) { _ in
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 0.8)) {
                        animationProgress = 1.0
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    func getPreviousSum(for date: Date, before series: String) -> Double {
        let currentIndex = self.series.firstIndex(of: series) ?? 0
        var sum = 0.0
        
        for i in 0..<currentIndex {
            if let data = streamData.first(where: { $0.date == date && $0.series == self.series[i] }) {
                sum += data.value
            }
        }
        
        return sum
    }
}

// 스트림 범례 아이템
struct StreamLegendItem: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let value: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 20, height: 12)
                    
                    Text(name)
                        .font(.caption)
                        .bold()
                }
                
                Text("\(value)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}