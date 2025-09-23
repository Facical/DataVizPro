import SwiftUI
import Charts

struct SectorChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDepartment: String?
    @State private var innerRadius: Double = 0.5
    @State private var showValues = true
    
    var totalProfit: Double {
        dataManager.profitData
            .filter { $0.quarter == "Q4" }
            .map { $0.profit }
            .reduce(0, +)
    }
    
    var chartData: [ProfitData] {
        dataManager.profitData
            .filter { $0.quarter == "Q4" && $0.profit > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("부서별 수익 분포")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Chart(chartData) { item in
                SectorMark(
                    angle: .value("수익", abs(item.profit)),
                    innerRadius: .ratio(innerRadius),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("부서", item.department))
                .opacity(selectedDepartment == nil || selectedDepartment == item.department ? 1 : 0.3)
                .cornerRadius(5)
            }
            .frame(height: 350)
            // chartAngleScale 제거 - 이 메서드는 visionOS에서 사용 불가
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    let center = CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    
                    if innerRadius > 0 {
                        VStack {
                            Text("총 수익")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(totalProfit / 1000))K")
                                .font(.title2)
                                .bold()
                        }
                        .position(center)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 범례 및 값 표시
            if showValues {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                    ForEach(chartData) { item in
                        HStack {
                            Circle()
                                .fill(colorForDepartment(item.department))
                                .frame(width: 10, height: 10)
                            Text(item.department)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(item.profit / 1000))K")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedDepartment == item.department ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(5)
                        .onTapGesture {
                            withAnimation {
                                if selectedDepartment == item.department {
                                    selectedDepartment = nil
                                } else {
                                    selectedDepartment = item.department
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 컨트롤
            VStack(spacing: 12) {
                HStack {
                    Text("내부 반경")
                    Slider(value: $innerRadius, in: 0...0.8)
                    Text("\(Int(innerRadius * 100))%")
                        .frame(width: 40)
                }
                
                Toggle("값 표시", isOn: $showValues)
            }
            .padding(.horizontal)
        }
    }
    
    func colorForDepartment(_ department: String) -> Color {
        switch department {
        case "영업": return .blue
        case "마케팅": return .green
        case "개발": return .orange
        case "디자인": return .purple
        case "인사": return .pink
        default: return .gray
        }
    }
}
