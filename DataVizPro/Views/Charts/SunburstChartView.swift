import SwiftUI

struct SunburstChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedSegment: SunburstData?
    @State private var animationProgress: Double = 0
    @State private var zoomLevel: String? = nil
    @State private var rotationAngle: Double = 0
    
    // 샘플 계층적 데이터 생성
    var sunburstData: [SunburstData] {
        var data: [SunburstData] = []
        
        // 루트 (중심)
        data.append(SunburstData(
            name: "전체",
            parent: nil,
            value: 100,
            level: 0,
            startAngle: 0,
            endAngle: 360,
            color: .gray
        ))
        
        // 레벨 1 - 주요 카테고리
        let categories = [
            ("기술", 40.0, Color.blue),
            ("금융", 25.0, Color.green),
            ("헬스케어", 20.0, Color.purple),
            ("소비재", 15.0, Color.orange)
        ]
        
        var currentAngle = 0.0
        for (name, value, color) in categories {
            let angleSize = (value / 100.0) * 360.0
            data.append(SunburstData(
                name: name,
                parent: "전체",
                value: value,
                level: 1,
                startAngle: currentAngle,
                endAngle: currentAngle + angleSize,
                color: color
            ))
            
            // 레벨 2 - 서브 카테고리
            if name == "기술" {
                let subCategories = [
                    ("소프트웨어", 20.0),
                    ("하드웨어", 15.0),
                    ("서비스", 5.0)
                ]
                var subAngle = currentAngle
                for (subName, subValue) in subCategories {
                    let subAngleSize = (subValue / 100.0) * 360.0
                    data.append(SunburstData(
                        name: subName,
                        parent: name,
                        value: subValue,
                        level: 2,
                        startAngle: subAngle,
                        endAngle: subAngle + subAngleSize,
                        color: color.opacity(0.8)
                    ))
                    
                    // 레벨 3 - 세부 항목
                    if subName == "소프트웨어" {
                        let details = [
                            ("클라우드", 10.0),
                            ("AI/ML", 7.0),
                            ("보안", 3.0)
                        ]
                        var detailAngle = subAngle
                        for (detailName, detailValue) in details {
                            let detailAngleSize = (detailValue / 100.0) * 360.0
                            data.append(SunburstData(
                                name: detailName,
                                parent: subName,
                                value: detailValue,
                                level: 3,
                                startAngle: detailAngle,
                                endAngle: detailAngle + detailAngleSize,
                                color: color.opacity(0.6)
                            ))
                            detailAngle += detailAngleSize
                        }
                    }
                    subAngle += subAngleSize
                }
            } else if name == "금융" {
                let subCategories = [
                    ("은행", 15.0),
                    ("보험", 7.0),
                    ("투자", 3.0)
                ]
                var subAngle = currentAngle
                for (subName, subValue) in subCategories {
                    let subAngleSize = (subValue / 100.0) * 360.0
                    data.append(SunburstData(
                        name: subName,
                        parent: name,
                        value: subValue,
                        level: 2,
                        startAngle: subAngle,
                        endAngle: subAngle + subAngleSize,
                        color: color.opacity(0.8)
                    ))
                    subAngle += subAngleSize
                }
            }
            
            currentAngle += angleSize
        }
        
        return data
    }
    
    var filteredData: [SunburstData] {
        if let zoom = zoomLevel {
            return sunburstData.filter { $0.parent == zoom || $0.name == zoom || hasParent($0, parent: zoom) }
        }
        return sunburstData
    }
    
    func hasParent(_ item: SunburstData, parent: String) -> Bool {
        if item.parent == parent { return true }
        if let parentItem = sunburstData.first(where: { $0.name == item.parent }) {
            return hasParent(parentItem, parent: parent)
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("선버스트 차트")
                    .font(.title2)
                    .bold()
                
                Text("계층적 데이터 시각화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 경로 표시
                if let selected = selectedSegment {
                    HStack(spacing: 5) {
                        ForEach(getPath(for: selected), id: \.self) { pathItem in
                            HStack(spacing: 3) {
                                if pathItem != "전체" {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Text(pathItem)
                                    .font(.caption)
                                    .foregroundColor(pathItem == selected.name ? .primary : .secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(Int(selected.value))%")
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selected.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // 선버스트 차트
            GeometryReader { geometry in
                ZStack {
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - 20
                    
                    ForEach(filteredData.filter { $0.level > 0 }) { segment in
                        SunburstSegment(
                            segment: segment,
                            center: center,
                            maxRadius: maxRadius,
                            animationProgress: animationProgress,
                            isSelected: selectedSegment?.id == segment.id,
                            rotationAngle: rotationAngle
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                if selectedSegment?.id == segment.id {
                                    // 더블 탭으로 줌
                                    if segment.level == 1 {
                                        zoomLevel = zoomLevel == segment.name ? nil : segment.name
                                    }
                                    selectedSegment = nil
                                } else {
                                    selectedSegment = segment
                                }
                            }
                        }
                    }
                    
                    // 중심 정보
                    VStack(spacing: 4) {
                        if let zoom = zoomLevel {
                            Text(zoom)
                                .font(.caption)
                                .bold()
                            
                            Button("초기화") {
                                withAnimation {
                                    zoomLevel = nil
                                }
                            }
                            .font(.caption2)
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        } else {
                            Text("전체")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("100%")
                                .font(.title3)
                                .bold()
                        }
                    }
                }
                .rotationEffect(.degrees(rotationAngle))
            }
            .frame(height: 400)
            .background(
                Circle()
                    .fill(Color.gray.opacity(0.05))
                    .padding(10)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 범례
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sunburstData.filter { $0.level == 1 }) { category in
                        LegendItem(
                            name: category.name,
                            value: category.value,
                            color: category.color,
                            isHighlighted: selectedSegment?.name == category.name || zoomLevel == category.name
                        ) {
                            withAnimation {
                                if zoomLevel == category.name {
                                    zoomLevel = nil
                                } else {
                                    zoomLevel = category.name
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // 컨트롤
            HStack {
                Button("회전") {
                    withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: false)) {
                        rotationAngle += 360
                    }
                }
                .buttonStyle(.bordered)
                
                Button("정지") {
                    withAnimation(.linear(duration: 0.1)) {
                        rotationAngle = 0
                    }
                }
                .buttonStyle(.bordered)
                
                Button("애니메이션 재생") {
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.5)) {
                        animationProgress = 1.0
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                if zoomLevel != nil || selectedSegment != nil {
                    Button("초기화") {
                        withAnimation {
                            zoomLevel = nil
                            selectedSegment = nil
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
        }
    }
    
    func getPath(for segment: SunburstData) -> [String] {
        var path: [String] = [segment.name]
        var current = segment
        
        while let parent = current.parent {
            path.insert(parent, at: 0)
            if let parentSegment = sunburstData.first(where: { $0.name == parent }) {
                current = parentSegment
            } else {
                break
            }
        }
        
        return path
    }
}

// 선버스트 세그먼트
struct SunburstSegment: View {
    let segment: SunburstData
    let center: CGPoint
    let maxRadius: CGFloat
    let animationProgress: Double
    let isSelected: Bool
    let rotationAngle: Double
    
    var innerRadius: CGFloat {
        maxRadius * CGFloat(segment.level - 1) / 3
    }
    
    var outerRadius: CGFloat {
        maxRadius * CGFloat(segment.level) / 3
    }
    
    var body: some View {
        Path { path in
            path.addArc(
                center: center,
                radius: (innerRadius + outerRadius) / 2,
                startAngle: .degrees(segment.startAngle * animationProgress - 90),
                endAngle: .degrees(segment.endAngle * animationProgress - 90),
                clockwise: false
            )
        }
        .stroke(
            segment.color,
            style: StrokeStyle(
                lineWidth: (outerRadius - innerRadius) * (isSelected ? 1.1 : 1.0),
                lineCap: .butt
            )
        )
        .shadow(color: isSelected ? segment.color.opacity(0.5) : .clear, radius: 10)
        .overlay(
            // 레이블 (레벨 1과 2만)
            Group {
                if segment.level <= 2 && segment.endAngle - segment.startAngle > 10 {
                    let midAngle = (segment.startAngle + segment.endAngle) / 2 * animationProgress - 90
                    let labelRadius = (innerRadius + outerRadius) / 2
                    let x = center.x + cos(midAngle * .pi / 180) * labelRadius
                    let y = center.y + sin(midAngle * .pi / 180) * labelRadius
                    
                    Text(segment.name)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(x: x, y: y)
                        .rotationEffect(.degrees(-rotationAngle))
                }
            }
        )
        .animation(.spring(response: 0.5), value: isSelected)
    }
}

// 범례 아이템
struct LegendItem: View {
    let name: String
    let value: Double
    let color: Color
    let isHighlighted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    Text(name)
                        .font(.caption)
                        .bold()
                }
                
                Text("\(Int(value))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHighlighted ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}