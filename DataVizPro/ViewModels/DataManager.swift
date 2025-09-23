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
        case bar = "막대 차트"
        case line = "라인 차트"
        case area = "영역 차트"
        case point = "포인트 차트"
        case rectangle = "사각형 차트"
        case rule = "룰 차트"
        case sector = "섹터 차트"
        case heatMap = "히트맵"
        case multiLine = "멀티 라인"
        case stackedBar = "누적 막대"
        case rangeChart = "범위 차트"
        case candlestick = "캔들스틱"
        
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
    }
    
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
        let startDate = Date().addingTimeInterval(-86400 * 365) // 1년 전
        
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
                populationData.append(PopulationData(
                    age: age,
                    count: Int.random(in: 10000...100000),
                    gender: gender
                ))
            }
        }
    }
    
    private func generateWeatherData() {
        weatherData = []
        let startDate = Date().addingTimeInterval(-86400 * 30) // 30일 전
        
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
        let startDate = Date().addingTimeInterval(-86400 * 90) // 90일 전
        
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
        // 실시간 데이터 업데이트 시뮬레이션
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
        // 시간 범위에 따른 데이터 필터링 로직
        loadInitialData() // 간단히 재생성
    }
}
