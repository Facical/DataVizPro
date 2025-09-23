import SwiftUI
import Charts

struct RangeChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showVolume = true
    @State private var showMovingAverage = true
    
    var movingAverageData: [(date: Date, value: Double)] {
        let period = 7
        var result: [(Date, Double)] = []
        
        for i in period..<dataManager.stockData.count {
            let slice = dataManager.stockData[(i-period)..<i]
            let average = slice.map { $0.close }.reduce(0, +) / Double(period)
            result.append((dataManager.stockData[i].date, average))
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("주가 범위 차트")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Chart {
                // 거래량 (배경)
                if showVolume {
                    ForEach(dataManager.stockData.suffix(60)) { item in
                        BarMark(
                            x: .value("날짜", item.date),
                            y: .value("거래량", Double(item.volume))
                        )
                        .foregroundStyle(.gray.opacity(0.3))
                    }
                }
                
                // 고가-저가 범위
                ForEach(dataManager.stockData.suffix(60)) { item in
                    RectangleMark(
                        x: .value("날짜", item.date),
                        yStart: .value("저가", item.low),
                        yEnd: .value("고가", item.high)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                    
                    // 시가-종가 라인
                    LineMark(
                        x: .value("날짜", item.date),
                        y: .value("종가", item.close)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                
                // 이동평균선
                if showMovingAverage {
                    ForEach(movingAverageData.suffix(60), id: \.date) { item in
                        LineMark(
                            x: .value("날짜", item.date),
                            y: .value("이동평균", item.value)
                        )
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .frame(height: 400)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartForegroundStyleScale([
                "종가": .blue,
                "이동평균": .red,
                "거래량": .gray
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 10)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                    AxisGridLine()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 컨트롤
            HStack {
                Toggle("거래량 표시", isOn: $showVolume)
                Spacer()
                Toggle("이동평균선", isOn: $showMovingAverage)
            }
            .padding(.horizontal)
        }
    }
}
