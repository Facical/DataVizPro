import SwiftUI
import Charts

// 워터폴 차트 데이터 모델
struct WaterfallData: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let type: WaterfallType
    let runningTotal: Double
    
    enum WaterfallType {
        case start
        case increase
        case decrease
        case subtotal
        case end
        
        var color: Color {
            switch self {
            case .start, .end, .subtotal:
                return .blue
            case .increase:
                return .green
            case .decrease:
                return .red
            }
        }
    }
}

struct WaterfallChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showValues = true
    @State private var showConnectors = true
    @State private var animationProgress: CGFloat = 1.0
    
    // 샘플 데이터 생성
    var waterfallData: [WaterfallData] {
        var data: [WaterfallData] = []
        var runningTotal = 10000.0
        
        data.append(WaterfallData(
            category: "시작 잔액",
            value: runningTotal,
            type: .start,
            runningTotal: runningTotal
        ))
        
        let changes: [(String, Double, WaterfallData.WaterfallType)] = [
            ("매출", 5000, .increase),
            ("비용", -3000, .decrease),
            ("투자수익", 2000, .increase),
            ("운영비", -1500, .decrease),
            ("기타수익", 800, .increase)
        ]
        
        for (category, value, type) in changes {
            runningTotal += value
            data.append(WaterfallData(
                category: category,
                value: abs(value),
                type: type,
                runningTotal: runningTotal
            ))
        }
        
        // 중간 합계
        data.append(WaterfallData(
            category: "중간 합계",
            value: runningTotal,
            type: .subtotal,
            runningTotal: runningTotal
        ))
        
        // 추가 변경사항
        let additionalChanges: [(String, Double, WaterfallData.WaterfallType)] = [
            ("세금", -2000, .decrease),
            ("보너스", 1000, .increase)
        ]
        
        for (category, value, type) in additionalChanges {
            runningTotal += value
            data.append(WaterfallData(
                category: category,
                value: abs(value),
                type: type,
                runningTotal: runningTotal
            ))
        }
        
        data.append(WaterfallData(
            category: "최종 잔액",
            value: runningTotal,
            type: .end,
            runningTotal: runningTotal
        ))
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("워터폴 차트")
                    .font(.title2)
                    .bold()
                Text("재무 흐름 분석")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Chart(Array(waterfallData.enumerated()), id: \.element.id) { index, item in
                // 막대 그리기
                if item.type == .start || item.type == .end || item.type == .subtotal {
                    // 전체 막대 (시작, 끝, 소계)
                    BarMark(
                        x: .value("카테고리", item.category),
                        y: .value("값", item.runningTotal * Double(animationProgress))
                    )
                    .foregroundStyle(item.type.color.gradient)
                    .annotation(position: .top) {
                        if showValues {
                            Text(formatCurrency(item.runningTotal))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    // 변화량 막대
                    let prevTotal = index > 0 ? waterfallData[index - 1].runningTotal : 0
                    let startY = item.type == .increase ? prevTotal : item.runningTotal
                    
                    BarMark(
                        x: .value("카테고리", item.category),
                        yStart: .value("시작", startY * Double(animationProgress)),
                        yEnd: .value("끝", (startY + (item.type == .increase ? item.value : -item.value)) * Double(animationProgress))
                    )
                    .foregroundStyle(item.type.color.gradient)
                    .annotation(position: item.type == .increase ? .top : .bottom) {
                        if showValues {
                            Text((item.type == .increase ? "+" : "-") + formatCurrency(item.value))
                                .font(.caption)
                                .foregroundColor(item.type.color)
                        }
                    }
                }
                
                // 연결선
                if showConnectors && index < waterfallData.count - 1 {
                    let nextItem = waterfallData[index + 1]
                    if nextItem.type != .start && nextItem.type != .end && nextItem.type != .subtotal {
                        RuleMark(
                            y: .value("연결", item.runningTotal * Double(animationProgress))
                        )
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .offset(x: 20)
                    }
                }
            }
            .frame(height: 400)
            .chartYScale(domain: 0...20000)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(orientation: .vertical)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            HStack(spacing: 20) {
                ForEach([
                    ("증가", Color.green),
                    ("감소", Color.red),
                    ("합계", Color.blue)
                ], id: \.0) { label, color in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                        Text(label)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            VStack(spacing: 12) {
                Toggle("값 표시", isOn: $showValues)
                Toggle("연결선 표시", isOn: $showConnectors)
                
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
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
