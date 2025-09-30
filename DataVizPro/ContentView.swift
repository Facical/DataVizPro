import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedChart: DataManager.ChartType = .bar
    @State private var showSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 사이드바
            ChartSidebarView(selectedChart: $selectedChart)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // 메인 콘텐츠
            ChartDetailContainerView(selectedChart: selectedChart)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// 사이드바 뷰
struct ChartSidebarView: View {
    @Binding var selectedChart: DataManager.ChartType
    
    var body: some View {
        List {
            Section("기본 차트") {
                ForEach([DataManager.ChartType.bar, .line, .area, .point, .sector, .rectangle, .rule], id: \.self) { chartType in
                    ChartRowView(chartType: chartType, isSelected: selectedChart == chartType) {
                        selectedChart = chartType
                    }
                }
            }
            
            Section("고급 차트") {
                ForEach([DataManager.ChartType.heatMap, .waterfall, .boxPlot, .violin, .ridgeline, .streamGraph], id: \.self) { chartType in
                    ChartRowView(chartType: chartType, isSelected: selectedChart == chartType) {
                        selectedChart = chartType
                    }
                }
            }
            
            Section("금융 차트") {
                ForEach([DataManager.ChartType.candlestick, .rangeChart, .gantt, .funnel], id: \.self) { chartType in
                    ChartRowView(chartType: chartType, isSelected: selectedChart == chartType) {
                        selectedChart = chartType
                    }
                }
            }
            
            Section("분석 차트") {
                ForEach([DataManager.ChartType.pyramid, .histogram, .densityPlot, .correlation, .multiLine, .stackedBar], id: \.self) { chartType in
                    ChartRowView(chartType: chartType, isSelected: selectedChart == chartType) {
                        selectedChart = chartType
                    }
                }
            }
            
            Section("특수 차트") {
                ForEach([DataManager.ChartType.polar, .radar, .gauge, .bubbleChart], id: \.self) { chartType in
                    ChartRowView(chartType: chartType, isSelected: selectedChart == chartType) {
                        selectedChart = chartType
                    }
                }
            }
            
            Section("계층 차트") {
                ForEach([DataManager.ChartType.treemap, .sunburst], id: \.self) { chartType in
                    ChartRowView(chartType: chartType, isSelected: selectedChart == chartType) {
                        selectedChart = chartType
                    }
                }
            }
            
            Section("3D 차트") {
                ForEach([DataManager.ChartType.scatter3D, .surface3D, .vector3D], id: \.self) { chartType in
                    ChartRowView(chartType: chartType, isSelected: selectedChart == chartType) {
                        selectedChart = chartType
                    }
                }
            }
        }
        .navigationTitle("차트 종류")
        .listStyle(.sidebar)
    }
}

// 차트 행 뷰
struct ChartRowView: View {
    let chartType: DataManager.ChartType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: chartType.systemImage)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 24)
                
                Text(chartType.rawValue)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// 차트 상세 컨테이너
struct ChartDetailContainerView: View {
    let selectedChart: DataManager.ChartType
    @EnvironmentObject var dataManager: DataManager
    @State private var showInfo = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            ChartHeaderView(
                title: selectedChart.rawValue,
                showInfo: $showInfo
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
    @Binding var showInfo: Bool
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle)
                    .bold()
                
                Text("마지막 업데이트: \(Date.now, format: .dateTime.hour().minute())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // 애니메이션 토글
                Toggle("", isOn: $dataManager.isAnimating)
                    .toggleStyle(.switch)
                    .labelsHidden()
                
                // 새로고침
                Button(action: {
                    dataManager.refreshAllData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                
                // 정보
                Button(action: {
                    showInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
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
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
            VStack(alignment: .leading, spacing: 20) {
                // 차트 설명
                VStack(alignment: .leading, spacing: 10) {
                    Label("차트 유형", systemImage: "chart.xyaxis.line")
                        .font(.headline)
                    
                    Text(chartType.rawValue)
                        .font(.title2)
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 사용 방법
                VStack(alignment: .leading, spacing: 10) {
                    Label("사용 방법", systemImage: "questionmark.circle")
                        .font(.headline)
                    
                    Text(chartDescription(for: chartType))
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
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
            return "막대 차트는 카테고리별 데이터를 비교할 때 사용됩니다. 각 막대의 높이가 값을 나타냅니다."
        case .line:
            return "선 차트는 시간에 따른 데이터의 변화를 보여줍니다. 추세를 파악하기에 좋습니다."
        case .area:
            return "영역 차트는 선 차트와 유사하지만 선 아래 영역을 색상으로 채워 볼륨을 강조합니다."
        case .point:
            return "산점도는 두 변수 간의 관계를 보여줍니다. 상관관계를 파악하는 데 유용합니다."
        case .sector:
            return "파이 차트는 전체에서 각 부분이 차지하는 비율을 보여줍니다."
        case .heatMap:
            return "히트맵은 데이터 값을 색상으로 표현합니다. 패턴을 시각적으로 빠르게 파악할 수 있습니다."
        case .candlestick:
            return "캔들스틱 차트는 주가의 시가, 종가, 고가, 저가를 한눈에 보여줍니다."
        default:
            return "이 차트는 특정 데이터를 효과적으로 시각화합니다."
        }
    }
}
