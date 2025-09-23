import SwiftUI
import Charts

struct ScatterPlotView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCategory: String?
    @State private var showTrendLine = false
    
    var filteredData: [Point3DData] {
        if let category = selectedCategory {
            return dataManager.point3DData.filter { $0.category == category }
        }
        return dataManager.point3DData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("3D 산점도")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Chart(filteredData.prefix(100)) { item in
                PointMark(
                    x: .value("X", item.x),
                    y: .value("Y", item.y)
                )
                .foregroundStyle(by: .value("카테고리", item.category))
                .symbolSize(item.size * 10)
                .opacity(0.7)
                
                // Z축 값을 색상 농도로 표현
                PointMark(
                    x: .value("X", item.x),
                    y: .value("Y", item.y)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue.opacity(item.z / 100), .red.opacity(item.z / 100)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .symbolSize(item.size * 10)
            }
            .frame(height: 400)
            .chartXScale(domain: 0...100)
            .chartYScale(domain: 0...100)
            .chartLegend(position: .trailing)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 카테고리 필터
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button(action: { selectedCategory = nil }) {
                        Text("전체")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == nil ? .white : .primary)
                            .cornerRadius(8)
                    }
                    
                    ForEach(["그룹 A", "그룹 B", "그룹 C", "그룹 D"], id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
