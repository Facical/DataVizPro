import SwiftUI
import Charts

struct PopulationPyramidView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedAge: Int?
    
    // 안전한 데이터 접근
    var chartData: [PopulationData] {
        // 데이터가 비어있는지 확인
        guard !dataManager.populationData.isEmpty else {
            // 기본 데이터 반환
            return generateDefaultData()
        }
        return dataManager.populationData
    }
    
    // 안전한 도메인 계산
    var xDomain: ClosedRange<Int> {
        let maxCount = chartData.map { $0.count }.max() ?? 100000
        return -maxCount...maxCount
    }
    
    // 기본 데이터 생성
    private func generateDefaultData() -> [PopulationData] {
        var defaultData: [PopulationData] = []
        let genders = ["남성", "여성"]
        
        for age in stride(from: 0, to: 100, by: 10) {
            for gender in genders {
                defaultData.append(PopulationData(
                    age: age,
                    count: Int.random(in: 10000...50000),
                    gender: gender
                ))
            }
        }
        return defaultData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("인구 피라미드")
                    .font(.title2)
                    .bold()
                
                Text("연령별 성별 인구 분포")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let age = selectedAge {
                    HStack {
                        Text("\(age)세 선택됨")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                        
                        Button("초기화") {
                            selectedAge = nil
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.horizontal)
            
            // 데이터가 있는지 확인 후 차트 렌더링
            if !chartData.isEmpty {
                Chart(chartData) { item in
                    let xValue = calculateXValue(for: item)
                    
                    BarMark(
                        x: .value("인구", xValue),
                        y: .value("연령", item.age)
                    )
                    .foregroundStyle(by: .value("성별", item.gender))
                    .opacity(selectedAge == nil || selectedAge == item.age ? 1.0 : 0.3)
                    // 클릭 이벤트를 위한 annotation
                    .annotation(position: .overlay) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    if selectedAge == item.age {
                                        selectedAge = nil
                                    } else {
                                        selectedAge = item.age
                                    }
                                }
                            }
                    }
                }
                .frame(height: 500)
                .chartXScale(domain: xDomain)
                .chartXAxis {
                    AxisMarks(preset: .automatic) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                let absValue = abs(intValue)
                                if absValue >= 1000 {
                                    Text("\(absValue / 1000)K")
                                } else {
                                    Text("\(absValue)")
                                }
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let age = value.as(Int.self) {
                                if age % 10 == 0 {  // 10세 단위로만 표시
                                    Text("\(age)세")
                                        .font(.caption)
                                }
                            }
                        }
                        if let age = value.as(Int.self), age % 10 == 0 {
                            AxisGridLine()
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "남성": Color.blue,
                    "여성": Color.pink
                ])
                .chartLegend(position: .top, alignment: .center) {
                    HStack(spacing: 20) {
                        ForEach(["남성", "여성"], id: \.self) { gender in
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(gender == "남성" ? Color.blue : Color.pink)
                                    .frame(width: 10, height: 10)
                                Text(gender)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // 총계 정보
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("남성 인구")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPopulation(getTotalByGender("남성")))
                            .font(.body)
                            .bold()
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("여성 인구")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPopulation(getTotalByGender("여성")))
                            .font(.body)
                            .bold()
                            .foregroundColor(.pink)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("총 인구")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPopulation(getTotalPopulation()))
                            .font(.body)
                            .bold()
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
            } else {
                // 데이터가 없을 때 표시
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("데이터를 불러오는 중...")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Button("데이터 새로고침") {
                        dataManager.refreshAllData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 500)
            }
        }
    }
    
    // 안전한 X값 계산
    private func calculateXValue(for item: PopulationData) -> Int {
        if item.gender == "남성" {
            // 음수 변환 시 오버플로우 방지
            return min(-1, -item.count)
        } else {
            return max(1, item.count)
        }
    }
    
    // 성별 총 인구 계산
    private func getTotalByGender(_ gender: String) -> Int {
        chartData
            .filter { $0.gender == gender }
            .map { $0.count }
            .reduce(0, +)
    }
    
    // 전체 인구 계산
    private func getTotalPopulation() -> Int {
        chartData
            .map { $0.count }
            .reduce(0, +)
    }
    
    // 인구 수 포맷팅
    private func formatPopulation(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: count)) ?? "0"
    }
}

// PopulationData가 DataModels.swift에 없다면 여기에 정의
#if !DEBUG
struct PopulationData: Identifiable {
    let id = UUID()
    let age: Int
    let count: Int
    let gender: String
}
#endif
