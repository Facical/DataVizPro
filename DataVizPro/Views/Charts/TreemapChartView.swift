import SwiftUI

// 트리맵 데이터 모델
struct TreemapData: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let category: String
    let parent: String?
    let color: Color
    let growth: Double // 성장률
}

struct TreemapChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedItem: TreemapData?
    @State private var zoomLevel: String?
    @State private var showLabels = true
    @State private var colorBy: ColorMode = .category
    
    enum ColorMode: String, CaseIterable {
        case category = "카테고리"
        case value = "값"
        case growth = "성장률"
    }
    
    // 샘플 데이터 생성
    var treemapData: [TreemapData] {
        [
            // 기술 섹터
            TreemapData(name: "Apple", value: 3000, category: "기술", parent: nil, color: .blue, growth: 15.2),
            TreemapData(name: "Microsoft", value: 2800, category: "기술", parent: nil, color: .blue, growth: 12.5),
            TreemapData(name: "Google", value: 2000, category: "기술", parent: nil, color: .blue, growth: 18.7),
            TreemapData(name: "Amazon", value: 1800, category: "기술", parent: nil, color: .blue, growth: 22.3),
            TreemapData(name: "Meta", value: 900, category: "기술", parent: nil, color: .blue, growth: -5.2),
            
            // 금융 섹터
            TreemapData(name: "JP Morgan", value: 1500, category: "금융", parent: nil, color: .green, growth: 8.5),
            TreemapData(name: "Bank of America", value: 1200, category: "금융", parent: nil, color: .green, growth: 6.3),
            TreemapData(name: "Wells Fargo", value: 800, category: "금융", parent: nil, color: .green, growth: 4.2),
            
            // 헬스케어 섹터
            TreemapData(name: "Johnson & Johnson", value: 1100, category: "헬스케어", parent: nil, color: .purple, growth: 7.8),
            TreemapData(name: "Pfizer", value: 900, category: "헬스케어", parent: nil, color: .purple, growth: 12.1),
            TreemapData(name: "Moderna", value: 400, category: "헬스케어", parent: nil, color: .purple, growth: -25.3),
            
            // 소비재 섹터
            TreemapData(name: "Tesla", value: 1600, category: "소비재", parent: nil, color: .orange, growth: 45.6),
            TreemapData(name: "Nike", value: 700, category: "소비재", parent: nil, color: .orange, growth: 9.2),
            TreemapData(name: "Starbucks", value: 500, category: "소비재", parent: nil, color: .orange, growth: 11.5),
            
            // 에너지 섹터
            TreemapData(name: "ExxonMobil", value: 1300, category: "에너지", parent: nil, color: .red, growth: 35.2),
            TreemapData(name: "Chevron", value: 900, category: "에너지", parent: nil, color: .red, growth: 28.7),
        ]
    }
    
    var filteredData: [TreemapData] {
        if let zoom = zoomLevel {
            return treemapData.filter { $0.category == zoom }
        }
        return treemapData
    }
    
    var totalValue: Double {
        filteredData.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("트리맵 차트")
                    .font(.title2)
                    .bold()
                Text("시장 점유율 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let selected = selectedItem {
                    HStack {
                        Text(selected.name)
                            .font(.caption)
                            .bold()
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("₩\(Int(selected.value))B")
                            .font(.caption)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(selected.growth > 0 ? "+" : "")\(String(format: "%.1f", selected.growth))%")
                            .font(.caption)
                            .foregroundColor(selected.growth > 0 ? .green : .red)
                    }
                }
            }
            .padding(.horizontal)
            
            // 트리맵 차트
            GeometryReader { geometry in
                let rectangles = calculateTreemap(
                    data: filteredData,
                    in: CGRect(origin: .zero, size: geometry.size)
                )
                
                ZStack {
                    ForEach(Array(zip(filteredData, rectangles)), id: \.0.id) { item, rect in
                        TreemapRectangle(
                            item: item,
                            rect: rect,
                            isSelected: selectedItem?.id == item.id,
                            showLabel: showLabels,
                            colorMode: colorBy,
                            totalValue: totalValue
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                if selectedItem?.id == item.id {
                                    if zoomLevel == nil {
                                        zoomLevel = item.category
                                    } else {
                                        zoomLevel = nil
                                        selectedItem = nil
                                    }
                                } else {
                                    selectedItem = item
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 450)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .clipped()
            
            // 범례 - 카테고리별 집계
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(Set(treemapData.map { $0.category })).sorted(), id: \.self) { category in
                        let categoryData = treemapData.filter { $0.category == category }
                        let categoryValue = categoryData.reduce(0) { $0 + $1.value }
                        let categoryColor = categoryData.first?.color ?? .gray
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(categoryColor)
                                    .frame(width: 10, height: 10)
                                Text(category)
                                    .font(.caption)
                                    .bold()
                            }
                            Text("₩\(Int(categoryValue))B")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(
                            zoomLevel == category
                            ? categoryColor.opacity(0.2)
                            : Color.gray.opacity(0.1)
                        )
                        .cornerRadius(6)
                        .onTapGesture {
                            withAnimation {
                                if zoomLevel == category {
                                    zoomLevel = nil
                                } else {
                                    zoomLevel = category
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            VStack(spacing: 12) {
                HStack {
                    Text("색상 기준:")
                    Picker("색상 기준", selection: $colorBy) {
                        ForEach(ColorMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Toggle("레이블 표시", isOn: $showLabels)
            }
            .padding(.horizontal)
        }
    }
    
    // 트리맵 레이아웃 계산 (Squarify 알고리즘 간소화 버전)
    func calculateTreemap(data: [TreemapData], in rect: CGRect) -> [CGRect] {
        guard !data.isEmpty else { return [] }
        
        let sortedData = data.sorted { $0.value > $1.value }
        let totalValue = sortedData.reduce(0) { $0 + $1.value }
        
        var rectangles: [CGRect] = []
        var currentRect = rect
        var currentRow: [TreemapData] = []
        var currentRowValue: Double = 0
        
        for item in sortedData {
            currentRow.append(item)
            currentRowValue += item.value
            
            // 현재 행의 비율 계산
            let rowRatio = currentRowValue / totalValue
            let isHorizontal = currentRect.width > currentRect.height
            
            if currentRow.count == 1 || shouldAddToRow(currentRow, in: currentRect, totalValue: totalValue) {
                continue
            } else {
                // 현재 행 렌더링
                let rowRects = layoutRow(
                    currentRow.dropLast(),
                    value: currentRowValue - item.value,
                    in: currentRect,
                    totalValue: totalValue
                )
                rectangles.append(contentsOf: rowRects)
                
                // 다음 행을 위한 영역 업데이트
                if isHorizontal {
                    let usedWidth = currentRect.width * ((currentRowValue - item.value) / totalValue)
                    currentRect.origin.x += usedWidth
                    currentRect.size.width -= usedWidth
                } else {
                    let usedHeight = currentRect.height * ((currentRowValue - item.value) / totalValue)
                    currentRect.origin.y += usedHeight
                    currentRect.size.height -= usedHeight
                }
                
                currentRow = [item]
                currentRowValue = item.value
            }
        }
        
        // 마지막 행 처리
        if !currentRow.isEmpty {
            let rowRects = layoutRow(currentRow, value: currentRowValue, in: currentRect, totalValue: totalValue)
            rectangles.append(contentsOf: rowRects)
        }
        
        return rectangles
    }
    
    func shouldAddToRow(_ row: [TreemapData], in rect: CGRect, totalValue: Double) -> Bool {
        // 간단한 휴리스틱: 행의 종횡비가 개선되는지 확인
        return row.count < 4 // 최대 4개까지만 한 행에
    }
    
    func layoutRow(_ row: [TreemapData], value: Double, in rect: CGRect, totalValue: Double) -> [CGRect] {
        var rectangles: [CGRect] = []
        let isHorizontal = rect.width > rect.height
        
        var currentOffset: CGFloat = 0
        for item in row {
            let itemRatio = item.value / value
            
            let itemRect: CGRect
            if isHorizontal {
                let itemHeight = rect.height * CGFloat(itemRatio)
                itemRect = CGRect(
                    x: rect.minX,
                    y: rect.minY + currentOffset,
                    width: rect.width * CGFloat(value / totalValue),
                    height: itemHeight
                )
                currentOffset += itemHeight
            } else {
                let itemWidth = rect.width * CGFloat(itemRatio)
                itemRect = CGRect(
                    x: rect.minX + currentOffset,
                    y: rect.minY,
                    width: itemWidth,
                    height: rect.height * CGFloat(value / totalValue)
                )
                currentOffset += itemWidth
            }
            
            rectangles.append(itemRect)
        }
        
        return rectangles
    }
}

// 트리맵 사각형 컴포넌트
struct TreemapRectangle: View {
    let item: TreemapData
    let rect: CGRect
    let isSelected: Bool
    let showLabel: Bool
    let colorMode: TreemapChartView.ColorMode
    let totalValue: Double
    
    var color: Color {
        switch colorMode {
        case .category:
            return item.color
        case .value:
            let intensity = item.value / 3000 // 최대값 기준
            return Color.blue.opacity(0.3 + intensity * 0.7)
        case .growth:
            if item.growth > 0 {
                return Color.green.opacity(0.3 + min(abs(item.growth) / 50, 1) * 0.7)
            } else {
                return Color.red.opacity(0.3 + min(abs(item.growth) / 50, 1) * 0.7)
            }
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .overlay(
                Group {
                    if showLabel && rect.width > 50 && rect.height > 30 {
                        VStack(spacing: 2) {
                            Text(item.name)
                                .font(.caption)
                                .bold()
                                .lineLimit(1)
                            
                            if rect.height > 50 {
                                Text("\(Int(item.value / totalValue * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .position(x: rect.midX, y: rect.midY)
                    }
                }
            )
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 1)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            )
    }
}
