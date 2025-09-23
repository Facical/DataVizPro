import SwiftUI
import Charts

struct LineChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate: Date?
    @State private var showPoints = false
    @State private var interpolationMethod: ChartInterpolationMethod = .catmullRom
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("주가 변동 추이")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Chart(dataManager.stockData.suffix(90)) { item in
                LineMark(
                    x: .value("날짜", item.date),
                    y: .value("종가", item.close)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(interpolationMethod.value)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                if showPoints {
                    PointMark(
                        x: .value("날짜", item.date),
                        y: .value("종가", item.close)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
                
                // 선택된 날짜 하이라이트
                if let selectedDate = selectedDate,
                   Calendar.current.isDate(item.date, inSameDayAs: selectedDate) {
                    PointMark(
                        x: .value("날짜", item.date),
                        y: .value("종가", item.close)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(100)
                    .annotation(position: .top) {
                        VStack(spacing: 4) {
                            Text(item.date, format: .dateTime.month().day())
                                .font(.caption2)
                            Text("₩\(Int(item.close))")
                                .font(.caption)
                                .bold()
                        }
                        .padding(4)
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(radius: 2)
                    }
                }
            }
            .frame(height: 300)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel(format: .dateTime.month().day())
                    AxisGridLine()
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXSelection(value: .constant(selectedDate))
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 컨트롤
            VStack(spacing: 12) {
                Toggle("포인트 표시", isOn: $showPoints)
                
                Picker("보간 방법", selection: $interpolationMethod) {
                    ForEach(ChartInterpolationMethod.allCases) { method in
                        Text(method.name).tag(method)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
        }
    }
}

enum ChartInterpolationMethod: String, CaseIterable, Identifiable {
    case linear = "직선"
    case catmullRom = "곡선"
    case cardinal = "카디널"
    case monotone = "모노톤"
    case stepStart = "계단(시작)"
    case stepCenter = "계단(중앙)"
    case stepEnd = "계단(끝)"
    
    var id: String { rawValue }
    var name: String { rawValue }
    
    var value: InterpolationMethod {
        switch self {
        case .linear: return .linear
        case .catmullRom: return .catmullRom
        case .cardinal: return .cardinal
        case .monotone: return .monotone
        case .stepStart: return .stepStart
        case .stepCenter: return .stepCenter
        case .stepEnd: return .stepEnd
        }
    }
}
