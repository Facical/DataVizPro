import SwiftUI
import Charts

struct AreaChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedSeries: String?
    @State private var stacked = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("멀티 시리즈 영역 차트")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Chart(dataManager.multiSeriesData.suffix(180)) { item in
                AreaMark(
                    x: .value("날짜", item.date),
                    y: .value("값", item.value),
                    series: .value("시리즈", item.series),
                    stacking: stacked ? .standard : .unstacked
                )
                .foregroundStyle(by: .value("시리즈", item.series))
                .interpolationMethod(.catmullRom)
                .opacity(selectedSeries == nil || selectedSeries == item.series ? 0.7 : 0.2)
                
                LineMark(
                    x: .value("날짜", item.date),
                    y: .value("값", item.value),
                    series: .value("시리즈", item.series)
                )
                .foregroundStyle(by: .value("시리즈", item.series))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                .opacity(selectedSeries == nil || selectedSeries == item.series ? 1.0 : 0.2)
            }
            .frame(height: 350)
            .chartLegend(position: .top)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                    AxisGridLine()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 컨트롤
            HStack {
                Toggle("누적 표시", isOn: $stacked)
                
                Spacer()
                
                Picker("시리즈", selection: $selectedSeries) {
                    Text("전체").tag(String?.none)
                    ForEach(["시리즈 1", "시리즈 2", "시리즈 3"], id: \.self) { series in
                        Text(series).tag(String?.some(series))
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
        }
    }
}
