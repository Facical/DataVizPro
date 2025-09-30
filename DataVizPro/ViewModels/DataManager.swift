import Foundation
import SwiftUI
import Combine

@MainActor
class DataManager: ObservableObject {
    // MARK: - Published Properties
    @Published var salesData: [SalesData] = []
    @Published var profitData: [ProfitData] = []
    @Published var stockData: [StockData] = []
    @Published var populationData: [PopulationData] = []
    @Published var weatherData: [WeatherData] = []
    @Published var point3DData: [Point3DData] = []
    @Published var heatMapData: [HeatMapData] = []
    @Published var multiSeriesData: [MultiSeriesData] = []
    
    // 새로운 차트용 데이터 (DataModels.swift에 정의된 타입 사용)
    @Published var waterfallData: [WaterfallData] = []
    @Published var boxPlotData: [BoxPlotData] = []
    @Published var radarData: [RadarData] = []
    @Published var treemapData: [TreemapData] = []
    @Published var ganttTasks: [GanttTask] = []
    @Published var point3DEnhanced: [Point3DEnhanced] = []
    @Published var violinPlotData: [ViolinPlotData] = []
    @Published var streamGraphData: [StreamGraphData] = []
    @Published var sunburstData: [SunburstData] = []
    @Published var gaugeData: [GaugeData] = []
    @Published var funnelData: [FunnelData] = []
    @Published var histogramData: [HistogramData] = []
    @Published var densityData: [DensityData] = []
    @Published var bubbleData: [BubbleData] = []
    @Published var correlationData: [[Double]] = []
    @Published var vector3DData: [Vector3DData] = []
    @Published var surface3DData: [[Double]] = []
    
    @Published var selectedTimeRange: TimeRange = .month
    @Published var isAnimating = true
    @Published var selectedChart: ChartType = .bar
    
    private var cancellables = Set<AnyCancellable>()
    
    enum TimeRange: String, CaseIterable {
        case week = "1주"
        case month = "1개월"
        case quarter = "3개월"
        case year = "1년"
        case all = "전체"
    }
    
    enum ChartType: String, CaseIterable, Identifiable {
        // 기본 차트
        case bar = "막대 차트"
        case line = "라인 차트"
        case area = "영역 차트"
        case point = "포인트 차트"
        case rectangle = "사각형 차트"
        case rule = "룰 차트"
        case sector = "섹터 차트"
        
        // 고급 차트
        case heatMap = "히트맵"
        case waterfall = "워터폴 차트"
        case boxPlot = "박스 플롯"
        case violin = "바이올린 플롯"
        case ridgeline = "리지라인 차트"
        case streamGraph = "스트림 그래프"
        
        // 금융 차트
        case candlestick = "캔들스틱"
        case rangeChart = "범위 차트"
        case gantt = "간트 차트"
        case funnel = "퍼널 차트"
        
        // 분석 차트
        case pyramid = "피라미드 차트"
        case histogram = "히스토그램"
        case densityPlot = "밀도 플롯"
        case correlation = "상관관계 매트릭스"
        case multiLine = "멀티 라인"
        case stackedBar = "누적 막대"
        
        // 특수 차트
        case polar = "폴라 차트"
        case radar = "레이더 차트"
        case gauge = "게이지 차트"
        case bubbleChart = "버블 차트"
        
        // 계층 차트
        case treemap = "트리맵"
        case sunburst = "선버스트 차트"
        
        // 3D 차트
        case scatter3D = "3D 산점도"
        case surface3D = "3D 서피스 차트"
        case vector3D = "3D 벡터 차트"
        
        var id: String { rawValue }
        
        var systemImage: String {
            switch self {
            case .bar: return "chart.bar"
            case .line: return "chart.line.uptrend.xyaxis"
            case .area: return "chart.line.uptrend.xyaxis.fill"
            case .point: return "chart.dots.scatter"
            case .rectangle: return "rectangle.split.3x3"
            case .rule: return "ruler"
            case .sector: return "chart.pie"
            case .heatMap: return "square.grid.3x3.fill"
            case .multiLine: return "chart.line.uptrend.xyaxis"
            case .stackedBar: return "chart.bar.fill"
            case .rangeChart: return "chart.line.flattrend.xyaxis"
            case .candlestick: return "chart.bar.doc.horizontal"
            case .pyramid: return "triangle.fill"
            case .waterfall: return "chart.bar.xaxis"
            case .boxPlot: return "rectangle.and.pencil.and.ellipsis"
            case .violin: return "waveform"
            case .ridgeline: return "waveform.path.ecg"
            case .streamGraph: return "waveform.circle"
            case .polar: return "circle.grid.3x3"
            case .radar: return "hexagon"
            case .treemap: return "square.grid.2x2"
            case .sunburst: return "sun.max"
            case .gauge: return "gauge"
            case .funnel: return "cone"
            case .histogram: return "chart.bar.xaxis"
            case .densityPlot: return "waveform.path"
            case .bubbleChart: return "circles.hexagongrid"
            case .gantt: return "calendar.day.timeline.trailing"
            case .correlation: return "square.grid.3x3.topleft.filled"
            case .vector3D: return "cube"
            case .surface3D: return "cube.fill"
            case .scatter3D: return "cube.transparent"
            }
        }
        
        var category: String {
            switch self {
            case .bar, .line, .area, .point, .rectangle, .rule, .sector:
                return "기본 차트"
            case .heatMap, .waterfall, .boxPlot, .violin, .ridgeline, .streamGraph:
                return "고급 차트"
            case .candlestick, .rangeChart, .gantt, .funnel:
                return "금융 차트"
            case .pyramid, .histogram, .densityPlot, .correlation, .multiLine, .stackedBar:
                return "분석 차트"
            case .polar, .radar, .gauge, .bubbleChart:
                return "특수 차트"
            case .treemap, .sunburst:
                return "계층 차트"
            case .scatter3D, .surface3D, .vector3D:
                return "3D 차트"
            }
        }
    }
    
    init() {
        loadInitialData()
        setupAutoRefresh()
    }
    
    // MARK: - Data Generation
    func loadInitialData() {
        generateSalesData()
        generateProfitData()
        generateStockData()
        generatePopulationData()
        generateWeatherData()
        generate3DPointData()
        generateHeatMapData()
        generateMultiSeriesData()
        
        // 새로운 차트 데이터 생성
        generateWaterfallData()
        generateBoxPlotData()
        generateRadarData()
        generateTreemapData()
        generateGanttData()
        generate3DEnhancedData()
        generateViolinPlotData()
        generateStreamGraphData()
        generateSunburstData()
        generateGaugeData()
        generateFunnelData()
        generateHistogramData()
        generateDensityData()
        generateBubbleData()
        generateCorrelationData()
        generateVector3DData()
        generateSurface3DData()
    }
    
    // 기존 데이터 생성 메서드들
    private func generateSalesData() {
        let months = ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"]
        let categories = ["온라인", "오프라인", "모바일"]
        
        salesData = []
        for month in months {
            for category in categories {
                salesData.append(SalesData(
                    month: month,
                    sales: Double.random(in: 100000...500000),
                    year: 2024,
                    category: category
                ))
            }
        }
    }
    
    private func generateProfitData() {
        let departments = ["영업", "마케팅", "개발", "디자인", "인사"]
        let quarters = ["Q1", "Q2", "Q3", "Q4"]
        
        profitData = []
        for dept in departments {
            for quarter in quarters {
                profitData.append(ProfitData(
                    department: dept,
                    profit: Double.random(in: -50000...200000),
                    quarter: quarter
                ))
            }
        }
    }
    
    private func generateStockData() {
        stockData = []
        let startDate = Date().addingTimeInterval(-86400 * 365)
        
        for i in 0..<365 {
            let date = startDate.addingTimeInterval(Double(i) * 86400)
            let open = Double.random(in: 100...200)
            let close = open + Double.random(in: -10...10)
            let high = max(open, close) + Double.random(in: 0...5)
            let low = min(open, close) - Double.random(in: 0...5)
            
            stockData.append(StockData(
                date: date,
                open: open,
                close: close,
                high: high,
                low: low,
                volume: Int.random(in: 1000000...10000000)
            ))
        }
    }
    
    private func generatePopulationData() {
        populationData = []
        let genders = ["남성", "여성"]
        
        for age in stride(from: 0, to: 100, by: 5) {
            for gender in genders {
                // 안전한 범위의 값으로 제한
                let count = Int.random(in: 10000...50000)
                populationData.append(PopulationData(
                    age: age,
                    count: count,
                    gender: gender
                ))
            }
        }
        
        // 데이터가 비어있지 않은지 확인
        if populationData.isEmpty {
            print("Warning: Population data is empty, generating default data")
            // 기본 데이터 생성
            for age in stride(from: 0, to: 100, by: 10) {
                for gender in genders {
                    populationData.append(PopulationData(
                        age: age,
                        count: 20000,
                        gender: gender
                    ))
                }
            }
        }
    }
    
    private func generateWeatherData() {
        weatherData = []
        let startDate = Date().addingTimeInterval(-86400 * 30)
        
        for i in 0..<30 {
            let date = startDate.addingTimeInterval(Double(i) * 86400)
            weatherData.append(WeatherData(
                date: date,
                temperature: Double.random(in: -10...35),
                humidity: Double.random(in: 30...90),
                precipitation: Double.random(in: 0...50)
            ))
        }
    }
    
    private func generate3DPointData() {
        point3DData = []
        let categories = ["그룹 A", "그룹 B", "그룹 C", "그룹 D"]
        
        for _ in 0..<200 {
            point3DData.append(Point3DData(
                x: Double.random(in: 0...100),
                y: Double.random(in: 0...100),
                z: Double.random(in: 0...100),
                category: categories.randomElement()!,
                size: Double.random(in: 5...20)
            ))
        }
    }
    
    private func generateHeatMapData() {
        heatMapData = []
        let xLabels = ["월", "화", "수", "목", "금", "토", "일"]
        let yLabels = Array(0..<24).map { "\($0)시" }
        
        for x in xLabels {
            for y in yLabels {
                heatMapData.append(HeatMapData(
                    x: x,
                    y: y,
                    value: Double.random(in: 0...100)
                ))
            }
        }
    }
    
    private func generateMultiSeriesData() {
        multiSeriesData = []
        let series = ["시리즈 1", "시리즈 2", "시리즈 3"]
        let startDate = Date().addingTimeInterval(-86400 * 90)
        
        for i in 0..<90 {
            let date = startDate.addingTimeInterval(Double(i) * 86400)
            for seriesName in series {
                multiSeriesData.append(MultiSeriesData(
                    date: date,
                    series: seriesName,
                    value: Double.random(in: 50...150) + (seriesName == "시리즈 1" ? 0 : seriesName == "시리즈 2" ? 50 : 100)
                ))
            }
        }
    }
    
    // MARK: - 새로운 차트 데이터 생성 메서드들
    
    private func generateWaterfallData() {
        // 샘플 워터폴 데이터 생성
        waterfallData = []
        var runningTotal = 10000.0
        
        waterfallData.append(WaterfallData(
            category: "시작 잔액",
            value: runningTotal,
            type: .start,
            runningTotal: runningTotal
        ))
        
        let changes: [(String, Double, WaterfallData.WaterfallType)] = [
            ("매출", 5000, .increase),
            ("비용", -3000, .decrease),
            ("투자수익", 2000, .increase)
        ]
        
        for (category, value, type) in changes {
            runningTotal += value
            waterfallData.append(WaterfallData(
                category: category,
                value: abs(value),
                type: type,
                runningTotal: runningTotal
            ))
        }
    }
    
    private func generateBoxPlotData() {
        // 샘플 박스플롯 데이터 생성
        boxPlotData = []
        let categories = ["제품 A", "제품 B", "제품 C"]
        
        for category in categories {
            var values = (0..<100).map { _ in Double.random(in: 0...100) }.sorted()
            let q1 = values[25]
            let median = values[50]
            let q3 = values[75]
            
            boxPlotData.append(BoxPlotData(
                category: category,
                min: values.first ?? 0,
                q1: q1,
                median: median,
                q3: q3,
                max: values.last ?? 100,
                outliers: [],
                mean: values.reduce(0, +) / Double(values.count)
            ))
        }
    }
    
    private func generateRadarData() {
        // 샘플 레이더 데이터 생성
        let axes = ["속도", "내구성", "디자인", "가격", "연비", "안전성"]
        radarData = []
        
        radarData.append(RadarData(
            category: "모델 A",
            axes: axes,
            values: axes.map { _ in Double.random(in: 60...100) },
            color: .blue
        ))
        
        radarData.append(RadarData(
            category: "모델 B",
            axes: axes,
            values: axes.map { _ in Double.random(in: 50...90) },
            color: .green
        ))
    }
    
    private func generateTreemapData() {
        // 샘플 트리맵 데이터 생성
        treemapData = []
        let companies = ["Apple", "Microsoft", "Google", "Amazon", "Meta"]
        
        for company in companies {
            treemapData.append(TreemapData(
                name: company,
                value: Double.random(in: 500...3000),
                category: "기술",
                parent: nil,
                color: .blue,
                growth: Double.random(in: -20...30)
            ))
        }
    }
    
    private func generateGanttData() {
        // 샘플 간트 데이터 생성
        ganttTasks = []
        let today = Date()
        
        ganttTasks.append(GanttTask(
            taskName: "프로젝트 기획",
            category: "기획",
            startDate: today,
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: today)!,
            progress: 0.8,
            dependencies: [],
            assignee: "팀장",
            priority: .high
        ))
    }
    
    private func generate3DEnhancedData() {
        point3DEnhanced = []
        for _ in 0..<200 {
            point3DEnhanced.append(Point3DEnhanced(
                x: Double.random(in: -50...50),
                y: Double.random(in: -50...50),
                z: Double.random(in: -50...50),
                category: ["클러스터 A", "클러스터 B", "클러스터 C"].randomElement()!,
                size: Double.random(in: 5...20),
                temperature: Double.random(in: 0...100)
            ))
        }
    }
    
    private func generateViolinPlotData() {
        violinPlotData = []
        // 바이올린 플롯 데이터 생성
    }
    
    private func generateStreamGraphData() {
        streamGraphData = []
        // 스트림 그래프 데이터 생성
    }
    
    private func generateSunburstData() {
        sunburstData = []
        // 선버스트 데이터 생성
    }
    
    private func generateGaugeData() {
        gaugeData = []
        gaugeData.append(GaugeData(
            name: "CPU 사용률",
            value: 75,
            min: 0,
            max: 100,
            thresholds: [
                GaugeData.Threshold(value: 50, color: .green, label: "정상"),
                GaugeData.Threshold(value: 80, color: .orange, label: "경고"),
                GaugeData.Threshold(value: 90, color: .red, label: "위험")
            ]
        ))
    }
    
    private func generateFunnelData() {
        funnelData = []
        let stages = [
            ("방문자", 10000.0),
            ("가입", 5000.0),
            ("활성 사용자", 3000.0),
            ("구매", 1000.0)
        ]
        
        for (index, (stage, value)) in stages.enumerated() {
            let conversionRate = index > 0 ? value / stages[index-1].1 : 1.0
            funnelData.append(FunnelData(
                stage: stage,
                value: value,
                conversionRate: conversionRate,
                dropoffRate: 1 - conversionRate,
                color: .blue
            ))
        }
    }
    
    private func generateHistogramData() {
        histogramData = []
        // 히스토그램 데이터 생성
    }
    
    private func generateDensityData() {
        densityData = []
        // 밀도 플롯 데이터 생성
    }
    
    private func generateBubbleData() {
        bubbleData = []
        for _ in 0..<50 {
            bubbleData.append(BubbleData(
                x: Double.random(in: 0...100),
                y: Double.random(in: 0...100),
                size: Double.random(in: 10...50),
                category: ["A", "B", "C"].randomElement()!,
                label: "Item",
                growth: Double.random(in: -20...20),
                color: [.blue, .green, .orange].randomElement()!
            ))
        }
    }
    
    private func generateCorrelationData() {
        let size = 10
        correlationData = []
        for i in 0..<size {
            var row: [Double] = []
            for j in 0..<size {
                if i == j {
                    row.append(1.0)
                } else {
                    row.append(Double.random(in: -1...1))
                }
            }
            correlationData.append(row)
        }
    }
    
    private func generateVector3DData() {
        vector3DData = []
        // 3D 벡터 데이터 생성
    }
    
    private func generateSurface3DData() {
        let gridSize = 20
        surface3DData = []
        for i in 0..<gridSize {
            var row: [Double] = []
            for j in 0..<gridSize {
                let x = Double(i) / Double(gridSize)
                let y = Double(j) / Double(gridSize)
                let z = sin(x * .pi) * cos(y * .pi)
                row.append(z)
            }
            surface3DData.append(row)
        }
    }
    
    // MARK: - Auto Refresh
    private func setupAutoRefresh() {
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.isAnimating {
                    self.updateRealtimeData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateRealtimeData() {
        withAnimation(.easeInOut(duration: 0.5)) {
            // 최신 주식 데이터 추가
            if let lastStock = stockData.last {
                let newStock = StockData(
                    date: lastStock.date.addingTimeInterval(86400),
                    open: lastStock.close,
                    close: lastStock.close + Double.random(in: -5...5),
                    high: lastStock.close + Double.random(in: 0...8),
                    low: lastStock.close - Double.random(in: 0...8),
                    volume: Int.random(in: 1000000...10000000)
                )
                stockData.append(newStock)
                if stockData.count > 365 {
                    stockData.removeFirst()
                }
            }
            
            // 날씨 데이터 업데이트
            if let lastWeather = weatherData.last {
                let newWeather = WeatherData(
                    date: lastWeather.date.addingTimeInterval(86400),
                    temperature: Double.random(in: -10...35),
                    humidity: Double.random(in: 30...90),
                    precipitation: Double.random(in: 0...50)
                )
                weatherData.append(newWeather)
                if weatherData.count > 30 {
                    weatherData.removeFirst()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func refreshAllData() {
        withAnimation(.spring()) {
            loadInitialData()
        }
    }
    
    func filterDataByTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        loadInitialData()
    }
    
    func getChartsByCategory(_ category: String) -> [ChartType] {
        return ChartType.allCases.filter { $0.category == category }
    }
    
    func getAllCategories() -> [String] {
        let categories = Set(ChartType.allCases.map { $0.category })
        return Array(categories).sorted()
    }
}
