import SwiftUI
import Charts

struct CandlestickChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var dateRange = 30
    
    var filteredData: [StockData] {
        Array(dataManager.stockData.suffix(dateRange))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("캔들스틱 차트")
                    .font(.title2)
                    .bold()
                Text("주가 변동 상세")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Chart(filteredData) { item in
                // 고가-저가 선
                RectangleMark(
                    x: .value("날짜", item.date),
                    yStart: .value("저가", item.low),
                    yEnd: .value("고가", item.high),
                    width: 1
                )
                .foregroundStyle(.gray)
                
                // 시가-종가 캔들
                RectangleMark(
                    x: .value("날짜", item.date),
                    yStart: .value("시가", item.open),
                    yEnd: .value("종가", item.close),
                    width: .ratio(0.6)
                )
                .foregroundStyle(item.close >= item.open ? Color.green : Color.red)
            }
            .frame(height: 400)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(dateRange / 7, 1))) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                    AxisGridLine()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 기간 선택
            Picker("기간", selection: $dateRange) {
                Text("1주").tag(7)
                Text("1개월").tag(30)
                Text("3개월").tag(90)
                Text("6개월").tag(180)
                Text("1년").tag(365)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}
