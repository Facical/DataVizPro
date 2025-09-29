import SwiftUI
import Charts

struct HeatMapChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCell: HeatMapData?
    @State private var colorScheme: ColorScheme = .viridis
    @State private var showGrid = true
    @State private var interpolation = true
    
    enum ColorScheme: String, CaseIterable {
        case viridis = "Viridis"
        case magma = "Magma"
        case plasma = "Plasma"
        case inferno = "Inferno"
        case turbo = "Turbo"
        case rainbow = "Rainbow"
        
        func color(for value: Double) -> Color {
            let normalized = value / 100.0
            
            switch self {
            case .viridis:
                // Scientific color scale - Viridis
                let r = 0.267004 + normalized * (0.993248 - 0.267004)
                let g = 0.004874 + normalized * (0.906157 - 0.004874)
                let b = 0.329415 + normalized * (0.143936 - 0.329415)
                return Color(red: r, green: g, blue: b)
                
            case .magma:
                // Magma colormap
                let r = normalized
                let g = normalized < 0.5 ? normalized * 2 : 1.0
                let b = normalized < 0.5 ? 0.5 : (1.0 - normalized) * 2
                return Color(red: r, green: g * 0.3, blue: b * 0.8)
                
            case .plasma:
                // Plasma colormap
                let r = 0.050383 + normalized * (0.984288 - 0.050383)
                let g = 0.029803 + normalized * (0.813566 - 0.029803)
                let b = 0.527975 + normalized * (0.070722 - 0.527975)
                return Color(red: r, green: g, blue: b)
                
            case .inferno:
                // Inferno colormap
                if normalized < 0.5 {
                    return Color(red: normalized * 2, green: 0, blue: normalized)
                } else {
                    return Color(red: 1, green: (normalized - 0.5) * 2, blue: 1 - normalized)
                }
                
            case .turbo:
                // Turbo colormap (Google's improved rainbow)
                let r = normalized < 0.5 ? 0.14 + normalized * 1.6 : 1.0
                let g = normalized < 0.5 ? normalized * 2 : 2.0 - normalized * 2
                let b = normalized > 0.5 ? 0.14 + (1 - normalized) * 1.6 : 1.0
                return Color(red: r, green: g, blue: b)
                
            case .rainbow:
                // Classic rainbow
                return Color(hue: (1.0 - normalized) * 0.8, saturation: 1, brightness: 1)
            }
        }
    }
    
    // 데이터를 매트릭스 형태로 변환
    var heatMapMatrix: [[Double]] {
        let xLabels = ["월", "화", "수", "목", "금", "토", "일"]
        let yLabels = Array(0..<24).map { "\($0)시" }
        
        var matrix: [[Double]] = []
        for y in yLabels {
            var row: [Double] = []
            for x in xLabels {
                let value = dataManager.heatMapData.first(where: { $0.x == x && $0.y == y })?.value ?? 0
                row.append(value)
            }
            matrix.append(row)
        }
        return matrix
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("활동량 히트맵")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 20) {
                    if let selected = selectedCell {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorScheme.color(for: selected.value))
                                .frame(width: 12, height: 12)
                            Text("\(selected.x) \(selected.y)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(Int(selected.value))")
                                .font(.subheadline)
                                .bold()
                        }
                    } else {
                        Text("셀을 선택하여 상세 정보 확인")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 통계 정보
                    HStack(spacing: 15) {
                        StatBadge(label: "최대", value: "\(Int(dataManager.heatMapData.map { $0.value }.max() ?? 0))")
                        StatBadge(label: "평균", value: "\(Int(dataManager.heatMapData.map { $0.value }.reduce(0, +) / Double(dataManager.heatMapData.count)))")
                        StatBadge(label: "최소", value: "\(Int(dataManager.heatMapData.map { $0.value }.min() ?? 0))")
                    }
                }
            }
            .padding(.horizontal)
            
            // 메인 히트맵
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Y축 레이블과 히트맵
                    HStack(spacing: 0) {
                        // Y축 레이블
                        VStack(spacing: 0) {
                            ForEach(Array(stride(from: 0, to: 24, by: 3)), id: \.self) { hour in
                                Text("\(hour)시")
                                    .font(.caption2)
                                    .frame(width: 40, height: geometry.size.height / 8)
                            }
                        }
                        
                        // 히트맵 그리드
                        ZStack {
                            // 배경
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.02))
                            
                            // 히트맵 셀들
                            VStack(spacing: showGrid ? 1 : 0) {
                                ForEach(Array(heatMapMatrix.enumerated()), id: \.offset) { yIndex, row in
                                    HStack(spacing: showGrid ? 1 : 0) {
                                        ForEach(Array(row.enumerated()), id: \.offset) { xIndex, value in
                                            let xLabels = ["월", "화", "수", "목", "금", "토", "일"]
                                            let yLabels = Array(0..<24).map { "\($0)시" }
                                            let cellData = HeatMapData(
                                                x: xLabels[xIndex],
                                                y: yLabels[yIndex],
                                                value: value
                                            )
                                            
                                            HeatMapCell(
                                                data: cellData,
                                                color: colorScheme.color(for: value),
                                                isSelected: selectedCell?.x == cellData.x && selectedCell?.y == cellData.y,
                                                interpolation: interpolation
                                            )
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3)) {
                                                    if selectedCell?.x == cellData.x && selectedCell?.y == cellData.y {
                                                        selectedCell = nil
                                                    } else {
                                                        selectedCell = cellData
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(4)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                    
                    // X축 레이블
                    HStack(spacing: 0) {
                        Text("")
                            .frame(width: 40)
                        
                        HStack(spacing: 0) {
                            ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                                Text(day)
                                    .font(.caption)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(["토", "일"].contains(day) ? .red : .primary)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(height: 500)
            
            // 컬러 스케일 범례
            VStack(spacing: 12) {
                HStack {
                    Text("낮음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            ForEach(0..<100, id: \.self) { i in
                                Rectangle()
                                    .fill(colorScheme.color(for: Double(i)))
                                    .frame(width: geometry.size.width / 100)
                            }
                        }
                    }
                    .frame(height: 24)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    Text("높음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 색상 스킴 선택
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ColorScheme.allCases, id: \.self) { scheme in
                            ColorSchemeButton(
                                scheme: scheme,
                                isSelected: colorScheme == scheme
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    colorScheme = scheme
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 컨트롤
            HStack(spacing: 20) {
                Toggle("그리드 표시", isOn: $showGrid)
                Toggle("부드러운 전환", isOn: $interpolation)
                
                Spacer()
                
                Button("초기화") {
                    withAnimation {
                        selectedCell = nil
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }
}

// 히트맵 셀 컴포넌트
struct HeatMapCell: View {
    let data: HeatMapData
    let color: Color
    let isSelected: Bool
    let interpolation: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: interpolation ? 4 : 2)
            .fill(color)
            .overlay(
                RoundedRectangle(cornerRadius: interpolation ? 4 : 2)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: isSelected ? 8 : 0)
            .animation(.spring(response: 0.3), value: isSelected)
    }
}

// 색상 스킴 버튼
struct ColorSchemeButton: View {
    let scheme: HeatMapChartView.ColorScheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { i in
                        Rectangle()
                            .fill(scheme.color(for: Double(i) * 5))
                            .frame(width: 3, height: 20)
                    }
                }
                .cornerRadius(4)
                
                Text(scheme.rawValue)
                    .font(.caption2)
                    .bold()
            }
            .padding(8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// 통계 배지
struct StatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}