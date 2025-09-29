import SwiftUI
import Charts

struct CorrelationMatrixView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCell: (row: Int, col: Int)?
    @State private var colorScheme: ColorScheme = .diverging
    @State private var showValues = true
    @State private var threshold: Double = 0.3
    @State private var animationProgress: Double = 0
    
    enum ColorScheme: String, CaseIterable {
        case diverging = "분기형"
        case sequential = "순차형"
        case spectral = "스펙트럼"
        
        func color(for value: Double) -> Color {
            switch self {
            case .diverging:
                // -1 (파랑) -> 0 (흰색) -> 1 (빨강)
                if value < 0 {
                    return Color.blue.opacity(abs(value))
                } else {
                    return Color.red.opacity(value)
                }
                
            case .sequential:
                // 0 (흰색) -> 1 (진한 파랑)
                return Color.blue.opacity(abs(value))
                
            case .spectral:
                // 무지개 색상
                let hue = (1.0 - abs(value)) * 0.8
                return Color(hue: hue, saturation: 1.0, brightness: 1.0)
            }
        }
    }
    
    // 변수명들
    let variables = ["매출", "비용", "수익", "고객수", "만족도", "재구매율", "광고비", "인력", "시장점유율", "성장률"]
    
    // 상관계수 매트릭스 (더미 데이터)
    var correlationMatrix: [[Double]] {
        if dataManager.correlationData.isEmpty {
            // 대칭 매트릭스 생성
            var matrix: [[Double]] = []
            for i in 0..<variables.count {
                var row: [Double] = []
                for j in 0..<variables.count {
                    if i == j {
                        row.append(1.0)
                    } else if i < j {
                        row.append(Double.random(in: -1...1))
                    } else {
                        row.append(matrix[j][i]) // 대칭 요소 복사
                    }
                }
                matrix.append(row)
            }
            return matrix
        }
        return dataManager.correlationData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("상관관계 매트릭스")
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("변수 간 상관관계 분석")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let (row, col) = selectedCell {
                        let value = correlationMatrix[row][col]
                        HStack(spacing: 12) {
                            Text("\(variables[row]) ↔ \(variables[col])")
                                .font(.caption)
                                .bold()
                            
                            Text(String(format: "%.3f", value))
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colorScheme.color(for: value).opacity(0.3))
                                .cornerRadius(4)
                            
                            Text(correlationStrength(value))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // 매트릭스 그리드
            GeometryReader { geometry in
                let cellSize = min(geometry.size.width, geometry.size.height) / CGFloat(variables.count + 1)
                
                ZStack {
                    // 배경
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                    
                    VStack(spacing: 0) {
                        // 상단 변수명 레이블
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: cellSize, height: cellSize)
                            
                            ForEach(0..<variables.count, id: \.self) { col in
                                Text(variables[col])
                                    .font(.caption2)
                                    .rotationEffect(.degrees(-45))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                        
                        // 매트릭스 본체
                        ForEach(0..<variables.count, id: \.self) { row in
                            HStack(spacing: 0) {
                                // 왼쪽 변수명 레이블
                                Text(variables[row])
                                    .font(.caption2)
                                    .frame(width: cellSize, height: cellSize)
                                    .lineLimit(1)
                                
                                // 상관계수 셀들
                                ForEach(0..<variables.count, id: \.self) { col in
                                    let value = correlationMatrix[row][col] * animationProgress
                                    let isSelected = selectedCell?.row == row && selectedCell?.col == col
                                    let isSignificant = abs(value) > threshold
                                    
                                    ZStack {
                                        Rectangle()
                                            .fill(colorScheme.color(for: value))
                                            .opacity(row == col ? 0.3 : 0.8)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(isSelected ? Color.white : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 0.5)
                                            )
                                        
                                        if showValues && (row != col || isSelected) {
                                            Text(String(format: row == col ? "1.00" : "%.2f", value))
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(abs(value) > 0.7 ? .white : .primary)
                                                .bold(isSignificant)
                                        }
                                        
                                        // 대각선 요소 표시
                                        if row == col {
                                            Image(systemName: "checkmark")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(width: cellSize, height: cellSize)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            if selectedCell?.row == row && selectedCell?.col == col {
                                                selectedCell = nil
                                            } else {
                                                selectedCell = (row, col)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 450)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
            
            // 색상 범례
            VStack(spacing: 12) {
                HStack {
                    Text("-1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("강한 음의 상관")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            ForEach(Array(stride(from: -1.0, through: 1.0, by: 0.02)), id: \.self) { value in
                                Rectangle()
                                    .fill(colorScheme.color(for: value))
                                    .frame(width: geometry.size.width / 100)
                            }
                        }
                    }
                    .frame(height: 20)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text("강한 양의 상관")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("+1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 색상 스킴 선택
                Picker("색상 스킴", selection: $colorScheme) {
                    ForEach(ColorScheme.allCases, id: \.self) { scheme in
                        Text(scheme.rawValue).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 임계값 설정
            VStack(spacing: 8) {
                HStack {
                    Text("유의미한 상관관계 임계값: ")
                        .font(.caption)
                    
                    Text(String(format: "±%.2f", threshold))
                        .font(.caption)
                        .bold()
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                
                Slider(value: $threshold, in: 0...1, step: 0.1)
                    .onChange(of: threshold) { _ in
                        animationProgress = 0.8
                        withAnimation(.easeOut(duration: 0.3)) {
                            animationProgress = 1.0
                        }
                    }
            }
            .padding(.horizontal)
            
            // 컨트롤
            HStack {
                Toggle("값 표시", isOn: $showValues)
                
                Spacer()
                
                Button("데이터 새로고침") {
                    dataManager.correlationData = []
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 1.0)) {
                        animationProgress = 1.0
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
            }
            .padding(.horizontal)
        }
    }
    
    func correlationStrength(_ value: Double) -> String {
        let absValue = abs(value)
        if absValue > 0.9 {
            return "매우 강한 상관"
        } else if absValue > 0.7 {
            return "강한 상관"
        } else if absValue > 0.5 {
            return "중간 상관"
        } else if absValue > 0.3 {
            return "약한 상관"
        } else {
            return "상관 없음"
        }
    }
}