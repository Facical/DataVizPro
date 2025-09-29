import SwiftUI
import Charts

// 박스 플롯 데이터 모델
struct BoxPlotData: Identifiable {
    let id = UUID()
    let category: String
    let min: Double
    let q1: Double      // 1사분위수
    let median: Double  // 중앙값
    let q3: Double      // 3사분위수
    let max: Double
    let outliers: [Double]
    let mean: Double
}

struct BoxPlotChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showOutliers = true
    @State private var showMean = true
    @State private var selectedCategory: String?
    
    // 샘플 데이터는 한 번만 생성해 보관하여 타입 추론 부담을 줄입니다.
    private let boxPlotData: [BoxPlotData] = BoxPlotChartView.generateSampleBoxPlotData()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("박스 플롯")
                    .font(.title2)
                    .bold()
                Text("데이터 분포 및 이상치 분석")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Chart(boxPlotData) { item in
                boxPlotMarks(
                    for: item,
                    showOutliers: showOutliers,
                    showMean: showMean,
                    selectedCategory: selectedCategory
                )
            }
            .frame(height: 400)
            .chartYScale(domain: -10.0...110.0)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 통계 정보
            if let selected = selectedCategory,
               let data = boxPlotData.first(where: { $0.category == selected }) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(selected) 통계")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatBox(label: "최소값", value: String(format: "%.1f", data.min))
                        StatBox(label: "Q1", value: String(format: "%.1f", data.q1))
                        StatBox(label: "중앙값", value: String(format: "%.1f", data.median))
                        StatBox(label: "Q3", value: String(format: "%.1f", data.q3))
                        StatBox(label: "최대값", value: String(format: "%.1f", data.max))
                        StatBox(label: "평균", value: String(format: "%.1f", data.mean))
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // 카테고리 선택
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button("전체") {
                        selectedCategory = nil
                    }
                    .buttonStyle(CategoryButtonStyle(isSelected: selectedCategory == nil))
                    
                    ForEach(boxPlotData) { item in
                        Button(item.category) {
                            selectedCategory = item.category
                        }
                        .buttonStyle(CategoryButtonStyle(isSelected: selectedCategory == item.category))
                    }
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            HStack {
                Toggle("이상치 표시", isOn: $showOutliers)
                Spacer()
                Toggle("평균 표시", isOn: $showMean)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Data Generation
extension BoxPlotChartView {
    // 사분위수 계산 보조 함수 (정렬된 값 가정)
    private static func quartiles(from sortedValues: [Double]) -> (q1: Double, median: Double, q3: Double) {
        let count = sortedValues.count
        let q1Index = count / 4
        let medianIndex = count / 2
        let q3Index = (count * 3) / 4
        
        let q1 = sortedValues[q1Index]
        let median = sortedValues[medianIndex]
        let q3 = sortedValues[q3Index]
        return (q1, median, q3)
    }
    
    static func generateSampleBoxPlotData() -> [BoxPlotData] {
        let categories: [String] = ["제품 A", "제품 B", "제품 C", "제품 D", "제품 E"]
        var result: [BoxPlotData] = []
        result.reserveCapacity(categories.count)
        
        for category in categories {
            // 0...100 범위의 랜덤 값 100개 생성 후 정렬
            let valuesUnsorted: [Double] = (0..<100).map { _ in Double.random(in: 0...100) }
            let values: [Double] = valuesUnsorted.sorted()
            
            // 사분위수
            let (q1, median, q3) = quartiles(from: values)
            
            // IQR 및 이상치 경계
            let iqr: Double = q3 - q1
            let lowerBound: Double = q1 - 1.5 * iqr
            let upperBound: Double = q3 + 1.5 * iqr
            
            // 이상치 및 필터링 값
            let outliers: [Double] = values.filter { $0 < lowerBound || $0 > upperBound }
            let filteredValues: [Double] = values.filter { $0 >= lowerBound && $0 <= upperBound }
            
            let minValue: Double = filteredValues.first ?? 0.0
            let maxValue: Double = filteredValues.last ?? 100.0
            
            // 평균
            let sum: Double = values.reduce(0.0, +)
            let mean: Double = sum / Double(values.count)
            
            let item = BoxPlotData(
                category: category,
                min: minValue,
                q1: q1,
                median: median,
                q3: q3,
                max: maxValue,
                outliers: outliers,
                mean: mean
            )
            result.append(item)
        }
        
        return result
    }
}

// MARK: - Chart Marks Helper
extension BoxPlotChartView {
    @ChartContentBuilder
    private func boxPlotMarks(
        for item: BoxPlotData,
        showOutliers: Bool,
        showMean: Bool,
        selectedCategory: String?
    ) -> some ChartContent {
        let isHighlighted: Bool = (selectedCategory == nil || selectedCategory == item.category)
        let baseOpacity: Double = isHighlighted ? 1.0 : 0.3
        
        // 수염 (Whiskers)
        RuleMark(
            x: .value("카테고리", item.category),
            yStart: .value("최소", item.min),
            yEnd: .value("최대", item.max)
        )
        .foregroundStyle(.gray)
        .lineStyle(StrokeStyle(lineWidth: 1))
        .opacity(baseOpacity)
        
        // 박스 (IQR)
        RectangleMark(
            x: .value("카테고리", item.category),
            yStart: .value("Q1", item.q1),
            yEnd: .value("Q3", item.q3),
            width: .ratio(0.5)
        )
        .foregroundStyle(
            LinearGradient(
                colors: [.blue.opacity(0.3), .blue.opacity(0.6)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .opacity(baseOpacity)
        
        // 평균 표시
        if showMean {
            PointMark(
                x: .value("카테고리", item.category),
                y: .value("평균", item.mean)
            )
            .foregroundStyle(.red)
            .symbolSize(60)
            .opacity(baseOpacity)
        }
        
        // 이상치 표시
        if showOutliers {
            ForEach(item.outliers, id: \.self) { outlier in
                PointMark(
                    x: .value("카테고리", item.category),
                    y: .value("이상치", outlier)
                )
                .foregroundStyle(.orange)
                .symbolSize(30)
                .opacity(baseOpacity)
            }
        }
        
    }
    
    struct StatBox: View {
        let label: String
        let value: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.white)
            .cornerRadius(6)
        }
    }
    
    struct CategoryButtonStyle: ButtonStyle {
        let isSelected: Bool
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
    }
}
