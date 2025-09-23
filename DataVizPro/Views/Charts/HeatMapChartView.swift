import SwiftUI
import Charts

struct HeatMapChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCell: HeatMapData?
    @State private var colorScheme: ColorScheme = .heat
    
    enum ColorScheme: String, CaseIterable {
        case heat = "열"
        case cool = "차가운"
        case gradient = "그라데이션"
        
        func color(for value: Double) -> Color {
            let normalizedValue = value / 100.0
            switch self {
            case .heat:
                return Color(red: normalizedValue, green: normalizedValue * 0.3, blue: 0)
            case .cool:
                return Color(red: 0, green: normalizedValue * 0.5, blue: normalizedValue)
            case .gradient:
                return Color(hue: (1.0 - normalizedValue) * 0.7, saturation: 1, brightness: 1)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("히트맵 - 시간대별 활동량")
                    .font(.title2)
                    .bold()
                
                if let selected = selectedCell {
                    Text("\(selected.x) \(selected.y): \(Int(selected.value))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // 히트맵 차트
            Chart(dataManager.heatMapData) { item in
                RectangleMark(
                    x: .value("요일", item.x),
                    y: .value("시간", item.y)
                )
                .foregroundStyle(colorScheme.color(for: item.value))
                .opacity(selectedCell == nil || selectedCell?.id == item.id ? 1 : 0.3)
                .cornerRadius(2)
            }
            .frame(height: 500)
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 컬러 스케일 범례
            HStack {
                Text("0")
                    .font(.caption)
                
                LinearGradient(
                    stops: (0...10).map { i in
                        Gradient.Stop(
                            color: colorScheme.color(for: Double(i) * 10),
                            location: Double(i) / 10
                        )
                    },
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 20)
                .cornerRadius(4)
                
                Text("100")
                    .font(.caption)
            }
            .padding(.horizontal)
            
            // 색상 스킴 선택
            Picker("색상 테마", selection: $colorScheme) {
                ForEach(ColorScheme.allCases, id: \.self) { scheme in
                    Text(scheme.rawValue).tag(scheme)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}
