import SwiftUI
import Charts

struct StackedBarChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedMonth: String?
    @State private var showPercentage = false
    @State private var animationProgress: Double = 0
    @State private var chartStyle: ChartStyle = .stacked
    
    enum ChartStyle: String, CaseIterable {
        case stacked = "누적"
        case grouped = "그룹"
        case percentage = "비율"
    }
    
    // 카테고리별 월 데이터 집계
    var aggregatedData: [(month: String, category: String, value: Double, percentage: Double)] {
        var result: [(String, String, Double, Double)] = []
        
        let months = Array(Set(dataManager.salesData.map { $0.month })).sorted()
        let categories = Array(Set(dataManager.salesData.map { $0.category })).sorted()
        
        for month in months {
            let monthData = dataManager.salesData.filter { $0.month == month }
            let monthTotal = monthData.map { $0.sales }.reduce(0, +)
            
            for category in categories {
                let categoryValue = monthData
                    .filter { $0.category == category }
                    .map { $0.sales }
                    .reduce(0, +)
                let percentage = monthTotal > 0 ? (categoryValue / monthTotal) * 100 : 0
                
                result.append((month, category, categoryValue, percentage))
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("누적 막대 차트")
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("카테고리별 매출 분포")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let month = selectedMonth {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(month)
                                .font(.caption)
                                .bold()
                            Text(formatTotal(for: month))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal)
            
            // 차트
            Chart(aggregatedData) { item in
                switch chartStyle {
                case .stacked:
                    BarMark(
                        x: .value("월", item.month),
                        y: .value("매출", item.value * animationProgress)
                    )
                    .foregroundStyle(by: .value("카테고리", item.category))
                    .position(by: .value("카테고리", item.category))
                    .cornerRadius(2)
                    .opacity(selectedMonth == nil || selectedMonth == item.month ? 1.0 : 0.3)
                    
                case .grouped:
                    BarMark(
                        x: .value("월", item.month),
                        y: .value("매출", item.value * animationProgress)
                    )
                    .foregroundStyle(by: .value("카테고리", item.category))
                    .position(by: .value("카테고리", item.category), axis: .horizontal)
                    .cornerRadius(3)
                    .opacity(selectedMonth == nil || selectedMonth == item.month ? 1.0 : 0.3)
                    
                case .percentage:
                    BarMark(
                        x: .value("월", item.month),
                        y: .value("비율", item.percentage * animationProgress)
                    )
                    .foregroundStyle(by: .value("카테고리", item.category))
                    .position(by: .value("카테고리", item.category))
                    .cornerRadius(2)
                    .opacity(selectedMonth == nil || selectedMonth == item.month ? 1.0 : 0.3)
                }
                
                // 선택된 월 강조
                if selectedMonth == item.month {
                    RuleMark(
                        x: .value("선택", item.month)
                    )
                    .foregroundStyle(.gray.opacity(0.1))
                    .offset(x: -20)
                    .zIndex(-1)
                }
            }
            .frame(height: 400)
            .chartForegroundStyleScale([
                "온라인": Color.blue,
                "오프라인": Color.green,
                "모바일": Color.orange
            ])
            .chartXSelection(value: .constant(selectedMonth))
            .chartLegend(position: .top, alignment: .center, spacing: 20)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if chartStyle == .percentage {
                            if let intValue = value.as(Double.self) {
                                Text("\(Int(intValue))%")
                            }
                        } else {
                            if let intValue = value.as(Double.self) {
                                Text("\(Int(intValue / 1000))K")
                            }
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(.gray.opacity(0.2))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
            
            // 카테고리별 합계 표시
            if let month = selectedMonth {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(["온라인", "오프라인", "모바일"], id: \.self) { category in
                        CategorySummaryCard(
                            category: category,
                            value: getCategoryValue(for: month, category: category),
                            percentage: getCategoryPercentage(for: month, category: category),
                            color: colorForCategory(category)
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 차트 스타일 선택
            Picker("스타일", selection: $chartStyle) {
                ForEach(ChartStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: chartStyle) { _ in
                animationProgress = 0
                withAnimation(.easeOut(duration: 0.5)) {
                    animationProgress = 1.0
                }
            }
            
            // 월 선택
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button("전체") {
                        withAnimation {
                            selectedMonth = nil
                        }
                    }
                    .buttonStyle(MonthButtonStyle(isSelected: selectedMonth == nil))
                    
                    ForEach(Array(Set(dataManager.salesData.map { $0.month })).sorted(), id: \.self) { month in
                        Button(month) {
                            withAnimation {
                                selectedMonth = selectedMonth == month ? nil : month
                            }
                        }
                        .buttonStyle(MonthButtonStyle(isSelected: selectedMonth == month))
                    }
                }
            }
            .padding(.horizontal)
            
            // 애니메이션 재생 버튼
            HStack {
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.2)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    private func formatTotal(for month: String) -> String {
        let total = dataManager.salesData
            .filter { $0.month == month }
            .map { $0.sales }
            .reduce(0, +)
        return "총 ₩\(Int(total / 1000))K"
    }
    
    private func getCategoryValue(for month: String, category: String) -> Double {
        dataManager.salesData
            .filter { $0.month == month && $0.category == category }
            .map { $0.sales }
            .reduce(0, +)
    }
    
    private func getCategoryPercentage(for month: String, category: String) -> Double {
        let categoryValue = getCategoryValue(for: month, category: category)
        let monthTotal = dataManager.salesData
            .filter { $0.month == month }
            .map { $0.sales }
            .reduce(0, +)
        return monthTotal > 0 ? (categoryValue / monthTotal) * 100 : 0
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "온라인": return .blue
        case "오프라인": return .green
        case "모바일": return .orange
        default: return .gray
        }
    }
}

// 카테고리 요약 카드
struct CategorySummaryCard: View {
    let category: String
    let value: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("₩\(Int(value / 1000))K")
                .font(.system(.body, design: .rounded))
                .bold()
            
            HStack(spacing: 4) {
                Image(systemName: percentage > 33 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                    .foregroundColor(percentage > 33 ? .green : .red)
                Text("\(Int(percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// 월 선택 버튼 스타일
struct MonthButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}