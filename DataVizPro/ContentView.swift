import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedChart: DataManager.ChartType = .bar
    @State private var showSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchText = ""
    @State private var favoriteCharts: Set<DataManager.ChartType> = []
    @State private var showFavoritesOnly = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 사이드바
            ChartSidebarView(
                selectedChart: $selectedChart,
                searchText: $searchText,
                favoriteCharts: $favoriteCharts,
                showFavoritesOnly: $showFavoritesOnly
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
        } detail: {
            // 메인 콘텐츠
            ChartDetailContainerView(
                selectedChart: selectedChart,
                isFavorite: favoriteCharts.contains(selectedChart)
            ) {
                if favoriteCharts.contains(selectedChart) {
                    favoriteCharts.remove(selectedChart)
                } else {
                    favoriteCharts.insert(selectedChart)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// 사이드바 뷰
struct ChartSidebarView: View {
    @Binding var selectedChart: DataManager.ChartType
    @Binding var searchText: String
    @Binding var favoriteCharts: Set<DataManager.ChartType>
    @Binding var showFavoritesOnly: Bool
    
    // 모든 차트 타입을 카테고리별로 그룹화
    let chartCategories: [(name: String, charts: [DataManager.ChartType])] = [
        ("기본 차트", [.bar, .line, .area, .point, .sector, .rectangle, .rule]),
        ("고급 차트", [.heatMap, .waterfall, .boxPlot, .violin, .ridgeline, .streamGraph]),
        ("금융 차트", [.candlestick, .rangeChart, .gantt, .funnel]),
        ("분석 차트", [.pyramid, .histogram, .densityPlot, .correlation, .multiLine, .stackedBar]),
        ("특수 차트", [.polar, .radar, .gauge, .bubbleChart]),
        ("계층 차트", [.treemap, .sunburst]),
        ("3D 차트", [.scatter3D, .surface3D, .vector3D])
    ]
    
    // 검색 결과 필터링
    var filteredCategories: [(name: String, charts: [DataManager.ChartType])] {
        if showFavoritesOnly {
            let favCharts = Array(favoriteCharts)
            if searchText.isEmpty {
                return [("즐겨찾기", favCharts)]
            } else {
                let filtered = favCharts.filter { chart in
                    chart.rawValue.localizedCaseInsensitiveContains(searchText)
                }
                return filtered.isEmpty ? [] : [("즐겨찾기", filtered)]
            }
        }
        
        if searchText.isEmpty {
            return chartCategories
        }
        
        var result: [(String, [DataManager.ChartType])] = []
        for category in chartCategories {
            let filteredCharts = category.charts.filter { chart in
                chart.rawValue.localizedCaseInsensitiveContains(searchText)
            }
            if !filteredCharts.isEmpty {
                result.append((category.name, filteredCharts))
            }
        }
        return result
    }
    
    var body: some View {
        List {
            // 검색 바
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("차트 검색...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 즐겨찾기 토글
            HStack {
                Toggle(isOn: $showFavoritesOnly) {
                    Label("즐겨찾기만 보기", systemImage: "star.fill")
                        .foregroundColor(showFavoritesOnly ? .yellow : .gray)
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                if !favoriteCharts.isEmpty {
                    Text("\(favoriteCharts.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.3))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            // 차트 목록
            if filteredCategories.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("검색 결과가 없습니다")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredCategories, id: \.name) { category in
                    Section(header: 
                        HStack {
                            Text(category.name)
                                .font(.headline)
                            Spacer()
                            Text("\(category.charts.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    ) {
                        ForEach(category.charts, id: \.self) { chartType in
                            ChartRowView(
                                chartType: chartType,
                                isSelected: selectedChart == chartType,
                                isFavorite: favoriteCharts.contains(chartType),
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedChart = chartType
                                    }
                                },
                                onToggleFavorite: {
                                    withAnimation(.spring(response: 0.3)) {
                                        if favoriteCharts.contains(chartType) {
                                            favoriteCharts.remove(chartType)
                                        } else {
                                            favoriteCharts.insert(chartType)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("차트 라이브러리")
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("총 \(DataManager.ChartType.allCases.count)개")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 차트 행 뷰
struct ChartRowView: View {
    let chartType: DataManager.ChartType
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 즐겨찾기 버튼
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .gray)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            
            // 차트 선택 버튼
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    Image(systemName: chartType.systemImage)
                        .foregroundColor(isSelected ? .white : .accentColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chartType.rawValue)
                            .foregroundColor(isSelected ? .white : .primary)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(chartType.category)
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
}

// 차트 상세 컨테이너
struct ChartDetailContainerView: View {
    let selectedChart: DataManager.ChartType
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    @EnvironmentObject var dataManager: DataManager
    @State private var showInfo = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            ChartHeaderView(
                title: selectedChart.rawValue,
                category: selectedChart.category,
                isFavorite: isFavorite,
                showInfo: $showInfo,
                onToggleFavorite: onToggleFavorite
            )
            
            // 차트 콘텐츠
            ScrollView {
                VStack(spacing: 20) {
                    ChartView(chartType: selectedChart)
                        .padding()
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showInfo) {
            ChartInfoView(chartType: selectedChart)
        }
    }
}

// 차트 헤더
struct ChartHeaderView: View {
    let title: String
    let category: String
    let isFavorite: Bool
    @Binding var showInfo: Bool
    let onToggleFavorite: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(title)
                        .font(.largeTitle)
                        .bold()
                    
                    // 즐겨찾기 버튼
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isFavorite ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isFavorite)
                }
                
                HStack(spacing: 10) {
                    Label(category, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("마지막 업데이트: \(Date.now, format: .dateTime.hour().minute())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // 애니메이션 토글
                VStack(spacing: 2) {
                    Toggle("", isOn: $dataManager.isAnimating)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    Text("자동 갱신")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                // 새로고침
                Button(action: {
                    dataManager.refreshAllData()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("새로고침")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.bordered)
                
                // 정보
                Button(action: {
                    showInfo.toggle()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                        Text("정보")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
}

// 실제 차트를 표시하는 뷰
struct ChartView: View {
    let chartType: DataManager.ChartType
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 20) {
            // 차트 종류에 따른 뷰 표시
            switch chartType {
            // 기본 차트
            case .bar:
                BarChartView()
                
            case .line:
                LineChartView()
                
            case .area:
                AreaChartView()
                
            case .point:
                ScatterPlotView()
                
            case .sector:
                SectorChartView()
                
            case .rectangle:
                RectangleChartView()
                
            case .rule:
                RuleChartView()
                
            // 고급 차트
            case .heatMap:
                HeatMapChartView()
                
            case .waterfall:
                WaterfallChartView()
                
            case .boxPlot:
                BoxPlotChartView()
                
            case .violin:
                ViolinPlotView()
                
            case .ridgeline:
                RidgelineChartView()
                
            case .streamGraph:
                StreamGraphView()
                
            // 금융 차트
            case .candlestick:
                CandlestickChartView()
                
            case .rangeChart:
                RangeChartView()
                
            case .gantt:
                GanttChartView()
                
            case .funnel:
                FunnelChartView()
                
            // 분석 차트
            case .pyramid:
                PopulationPyramidView()
                
            case .multiLine:
                MultiLineChartView()
                
            case .stackedBar:
                StackedBarChartView()
                
            case .histogram:
                HistogramChartView()
                
            case .densityPlot:
                DensityPlotView()
                
            case .correlation:
                CorrelationMatrixView()
                
            // 특수 차트
            case .radar:
                RadarChartView()
                
            case .gauge:
                GaugeChartView()
                
            case .bubbleChart:
                BubbleChartView()
                
            case .polar:
                PolarChartView()
                
            // 계층 차트
            case .treemap:
                TreemapChartView()
                
            case .sunburst:
                SunburstChartView()
                
            // 3D 차트
            case .scatter3D:
                Scatter3DChartView()
                
            case .surface3D:
                Surface3DChartView()
                
            case .vector3D:
                Vector3DChartView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.03), Color.gray.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// 빈 차트 뷰
struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: 400)
        .frame(maxWidth: .infinity)
    }
}

// 차트 정보 뷰
struct ChartInfoView: View {
    let chartType: DataManager.ChartType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 차트 아이콘과 제목
                    HStack(spacing: 20) {
                        Image(systemName: chartType.systemImage)
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                            .frame(width: 80, height: 80)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(chartType.rawValue)
                                .font(.title)
                                .bold()
                            
                            Label(chartType.category, systemImage: "folder")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // 차트 설명
                    VStack(alignment: .leading, spacing: 10) {
                        Label("설명", systemImage: "text.alignleft")
                            .font(.headline)
                        
                        Text(chartDescription(for: chartType))
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // 사용 예시
                    VStack(alignment: .leading, spacing: 10) {
                        Label("사용 예시", systemImage: "lightbulb")
                            .font(.headline)
                        
                        Text(chartUsageExample(for: chartType))
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // 주요 특징
                    VStack(alignment: .leading, spacing: 10) {
                        Label("주요 특징", systemImage: "star")
                            .font(.headline)
                        
                        ForEach(chartFeatures(for: chartType), id: \.self) { feature in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(feature)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("차트 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func chartDescription(for type: DataManager.ChartType) -> String {
        switch type {
        case .bar:
            return "막대 차트는 카테고리별 데이터를 비교할 때 사용됩니다. 각 막대의 높이가 값을 나타내며, 여러 카테고리 간의 크기 비교가 쉽습니다."
        case .line:
            return "선 차트는 시간에 따른 데이터의 변화를 보여줍니다. 연속적인 데이터의 추세를 파악하기에 최적화되어 있습니다."
        case .area:
            return "영역 차트는 선 차트와 유사하지만 선 아래 영역을 색상으로 채워 볼륨을 강조합니다. 시간에 따른 누적량을 표현하기 좋습니다."
        case .point:
            return "산점도는 두 변수 간의 관계를 보여줍니다. 데이터의 분포와 상관관계를 파악하는 데 유용합니다."
        case .sector:
            return "파이 차트는 전체에서 각 부분이 차지하는 비율을 보여줍니다. 구성 비율을 한눈에 파악할 수 있습니다."
        case .rectangle:
            return "사각형 차트는 2차원 매트릭스 형태로 데이터를 표현합니다. 두 카테고리의 교차점에서의 값을 시각화합니다."
        case .rule:
            return "규칙 차트는 임계값, 기준선 등을 시각화합니다. 데이터가 특정 기준을 충족하는지 확인하는 데 유용합니다."
        case .heatMap:
            return "히트맵은 데이터 값을 색상의 강도로 표현합니다. 패턴을 시각적으로 빠르게 파악할 수 있습니다."
        case .waterfall:
            return "워터폴 차트는 누적 값의 변화를 단계별로 보여줍니다. 재무 데이터의 흐름을 이해하는 데 효과적입니다."
        case .boxPlot:
            return "박스 플롯은 데이터의 분포와 이상치를 보여줍니다. 사분위수와 중앙값을 통해 데이터의 특성을 파악합니다."
        case .violin:
            return "바이올린 플롯은 박스 플롯과 밀도 플롯을 결합한 형태입니다. 데이터의 분포를 더 자세히 보여줍니다."
        case .ridgeline:
            return "리지라인 차트는 여러 분포를 겹쳐서 보여줍니다. 시간에 따른 분포 변화를 표현하기 좋습니다."
        case .streamGraph:
            return "스트림 그래프는 시간에 따른 여러 카테고리의 변화를 유기적으로 표현합니다."
        case .candlestick:
            return "캔들스틱 차트는 주가의 시가, 종가, 고가, 저가를 한눈에 보여줍니다."
        case .rangeChart:
            return "범위 차트는 최소값과 최대값 사이의 범위를 표현합니다."
        case .gantt:
            return "간트 차트는 프로젝트의 일정과 진행 상황을 시각화합니다."
        case .funnel:
            return "퍼널 차트는 단계별 전환율을 보여줍니다. 판매 프로세스나 사용자 여정 분석에 유용합니다."
        case .pyramid:
            return "피라미드 차트는 계층적 데이터나 인구 분포를 표현합니다."
        case .histogram:
            return "히스토그램은 데이터의 빈도 분포를 보여줍니다."
        case .densityPlot:
            return "밀도 플롯은 데이터의 확률 밀도를 부드러운 곡선으로 표현합니다."
        case .correlation:
            return "상관관계 매트릭스는 여러 변수 간의 상관계수를 색상으로 표현합니다."
        case .multiLine:
            return "멀티 라인 차트는 여러 시계열 데이터를 동시에 비교합니다."
        case .stackedBar:
            return "누적 막대 차트는 여러 카테고리의 합계와 각 부분을 동시에 보여줍니다."
        case .polar:
            return "극좌표 차트는 각도와 거리를 이용해 데이터를 표현합니다."
        case .radar:
            return "레이더 차트는 여러 축에 대한 값을 방사형으로 표현합니다."
        case .gauge:
            return "게이지 차트는 현재 값을 계기판 형태로 보여줍니다."
        case .bubbleChart:
            return "버블 차트는 3개 이상의 변수를 2D 공간에 표현합니다. 위치와 크기로 데이터를 표현합니다."
        case .treemap:
            return "트리맵은 계층적 데이터를 중첩된 사각형으로 표현합니다."
        case .sunburst:
            return "선버스트 차트는 계층적 데이터를 동심원으로 표현합니다."
        case .scatter3D:
            return "3D 산점도는 3차원 공간에서 데이터 포인트를 표현합니다."
        case .surface3D:
            return "3D 표면 차트는 3차원 함수나 데이터를 표면으로 시각화합니다."
        case .vector3D:
            return "3D 벡터 차트는 방향과 크기를 가진 벡터 데이터를 3차원으로 표현합니다."
        }
    }
    
    func chartUsageExample(for type: DataManager.ChartType) -> String {
        switch type {
        case .bar: return "월별 매출 비교, 제품별 판매량, 부서별 성과"
        case .line: return "주가 변동, 온도 변화, 웹사이트 트래픽 추이"
        case .area: return "누적 매출, 시장 점유율 변화, 리소스 사용량"
        case .point: return "키와 몸무게 관계, 광고비와 매출 상관관계"
        case .sector: return "시장 점유율, 예산 배분, 설문 응답 비율"
        case .heatMap: return "웹사이트 클릭 히트맵, 요일/시간별 활동량"
        case .candlestick: return "주식 가격 변동, 암호화폐 거래"
        case .radar: return "제품 성능 비교, 직원 역량 평가"
        case .gantt: return "프로젝트 일정 관리, 리소스 할당"
        case .treemap: return "파일 시스템 용량, 예산 할당"
        default: return "다양한 데이터 분석 및 시각화"
        }
    }
    
    func chartFeatures(for type: DataManager.ChartType) -> [String] {
        switch type {
        case .bar:
            return ["카테고리별 비교 용이", "값의 크기를 직관적으로 표현", "여러 시리즈 동시 비교 가능"]
        case .line:
            return ["시간에 따른 추세 파악", "여러 시리즈 비교", "데이터 포인트 연결"]
        case .area:
            return ["볼륨 강조", "누적 값 표현", "시간에 따른 변화 시각화"]
        case .heatMap:
            return ["색상으로 값 표현", "패턴 인식 용이", "대량 데이터 시각화"]
        case .radar:
            return ["다차원 데이터 표현", "균형 평가", "비교 분석 용이"]
        default:
            return ["효과적인 데이터 시각화", "인터랙티브 기능", "커스터마이징 가능"]
        }
    }
}
