import SwiftUI
import Charts

struct MultiLineChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate: Date?
    @State private var showPoints = false
    @State private var showArea = false
    @State private var selectedSeries: Set<String> = []
    
    var uniqueSeries: [String] {
        Array(Set(dataManager.multiSeriesData.map { $0.series })).sorted()
    }
    
    var filteredData: [MultiSeriesData] {
        if selectedSeries.isEmpty {
            return dataManager.multiSeriesData.suffix(180)
        } else {
            return dataManager.multiSeriesData.suffix(180).filter { selectedSeries.contains($0.series) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("멀티 라인 차트")
                    .font(.title2)
                    .bold()
                
                Text("여러 시리즈 동시 비교")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 실시간 값 표시
                if let date = selectedDate {
                    HStack(spacing: 20) {
                        Text(date, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(uniqueSeries, id: \.self) { series in
                            if let value = dataManager.multiSeriesData
                                .first(where: { 
                                    Calendar.current.isDate($0.date, inSameDayAs: date) && 
                                    $0.series == series 
                                })?.value {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(colorForSeries(series))
                                        .frame(width: 8, height: 8)
                                    Text("\(series): \(Int(value))")
                                        .font(.caption)
                                        .foregroundColor(selectedSeries.isEmpty || selectedSeries.contains(series) ? .primary : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // 차트
            Chart(filteredData) { item in
                if showArea {
                    AreaMark(
                        x: .value("날짜", item.date),
                        y: .value("값", item.value),
                        series: .value("시리즈", item.series)
                    )
                    .foregroundStyle(by: .value("시리즈", item.series))
                    .opacity(0.2)
                    .interpolationMethod(.catmullRom)
                }
                
                LineMark(
                    x: .value("날짜", item.date),
                    y: .value("값", item.value),
                    series: .value("시리즈", item.series)
                )
                .foregroundStyle(by: .value("시리즈", item.series))
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                .opacity(animationOpacity(for: item.series))
                
                if showPoints {
                    PointMark(
                        x: .value("날짜", item.date),
                        y: .value("값", item.value)
                    )
                    .foregroundStyle(by: .value("시리즈", item.series))
                    .symbolSize(30)
                    .opacity(animationOpacity(for: item.series))
                }
                
                // 선택된 날짜 하이라이트
                if let selectedDate = selectedDate,
                   Calendar.current.isDate(item.date, inSameDayAs: selectedDate) {
                    RuleMark(
                        x: .value("선택", item.date)
                    )
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .frame(height: 400)
            .chartForegroundStyleScale([
                "시리즈 1": Color.blue,
                "시리즈 2": Color.green,
                "시리즈 3": Color.orange
            ])
            .chartXSelection(value: .constant(selectedDate))
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(.gray.opacity(0.2))
                }
            }
            .chartLegend(position: .top, alignment: .leading)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.gray.opacity(0.03), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 날짜 선택 제스처 구현 가능
                    }
            )
            
            // 시리즈 선택 버튼
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button("전체") {
                        withAnimation(.spring()) {
                            selectedSeries.removeAll()
                        }
                    }
                    .buttonStyle(SeriesButtonStyle(isSelected: selectedSeries.isEmpty))
                    
                    ForEach(uniqueSeries, id: \.self) { series in
                        Button(series) {
                            withAnimation(.spring()) {
                                if selectedSeries.contains(series) {
                                    selectedSeries.remove(series)
                                } else {
                                    selectedSeries.insert(series)
                                }
                            }
                        }
                        .buttonStyle(SeriesButtonStyle(
                            isSelected: selectedSeries.contains(series),
                            color: colorForSeries(series)
                        ))
                    }
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            HStack(spacing: 20) {
                Toggle("포인트 표시", isOn: $showPoints)
                Toggle("영역 표시", isOn: $showArea)
                
                Spacer()
                
                Button("모든 시리즈 표시") {
                    withAnimation {
                        selectedSeries.removeAll()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(selectedSeries.isEmpty)
            }
            .padding(.horizontal)
        }
    }
    
    private func animationOpacity(for series: String) -> Double {
        if selectedSeries.isEmpty {
            return 1.0
        }
        return selectedSeries.contains(series) ? 1.0 : 0.2
    }
    
    private func colorForSeries(_ series: String) -> Color {
        switch series {
        case "시리즈 1": return .blue
        case "시리즈 2": return .green
        case "시리즈 3": return .orange
        default: return .gray
        }
    }
}

// 시리즈 버튼 스타일
struct SeriesButtonStyle: ButtonStyle {
    let isSelected: Bool
    var color: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? color : .primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}