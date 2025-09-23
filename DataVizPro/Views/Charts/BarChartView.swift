import SwiftUI
import Charts

struct BarChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedMonth: String?
    @State private var showAverage = true
    
    var averageSales: Double {
        let monthData = dataManager.salesData.filter { $0.month == (selectedMonth ?? "1월") }
        return monthData.map { $0.sales }.reduce(0, +) / Double(max(monthData.count, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 5) {
                Text("월별 매출 현황")
                    .font(.title2)
                    .bold()
                
                if let month = selectedMonth {
                    Text("\(month) 평균: \(Int(averageSales).formatted())원")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // 차트
            Chart(dataManager.salesData) { item in
                BarMark(
                    x: .value("월", item.month),
                    y: .value("매출", item.sales)
                )
                .foregroundStyle(by: .value("카테고리", item.category))
                .position(by: .value("카테고리", item.category))
                .opacity(selectedMonth == nil || selectedMonth == item.month ? 1.0 : 0.3)
                
                // 평균선 표시
                if showAverage && selectedMonth == item.month {
                    RuleMark(
                        y: .value("평균", averageSales)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("평균")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(height: 300)
            .chartXSelection(value: .constant(selectedMonth))
            .chartLegend(position: .bottom, alignment: .center, spacing: 10)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(Int(intValue / 1000))K")
                        }
                    }
                    AxisGridLine()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 컨트롤
            HStack {
                Toggle("평균 표시", isOn: $showAverage)
                Spacer()
                Button("초기화") {
                    selectedMonth = nil
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }
}
