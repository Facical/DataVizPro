import SwiftUI
import Charts

struct PopulationPyramidView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedAge: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("인구 피라미드")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Chart(dataManager.populationData) { item in
                BarMark(
                    x: .value("인구", item.gender == "남성" ? -item.count : item.count),
                    y: .value("연령", item.age)
                )
                .foregroundStyle(by: .value("성별", item.gender))
                .opacity(selectedAge == nil || selectedAge == item.age ? 1 : 0.3)
            }
            .frame(height: 500)
            .chartXScale(domain: -100000...100000)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(abs(intValue / 1000))K")
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: 10)) { value in
                    AxisValueLabel {
                        if let age = value.as(Int.self) {
                            Text("\(age)세")
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "남성": .blue,
                "여성": .pink
            ])
            .chartLegend(position: .top)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}
