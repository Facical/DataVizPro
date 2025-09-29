import Foundation
import SwiftUI

// MARK: - 기존 데이터 모델들 (원래 프로젝트에 있던 것들)

// Sales Data
struct SalesData: Identifiable {
    let id = UUID()
    let month: String
    let sales: Double
    let year: Int
    let category: String
}

// Profit Data
struct ProfitData: Identifiable {
    let id = UUID()
    let department: String
    let profit: Double
    let quarter: String
}

// Stock Data
struct StockData: Identifiable {
    let id = UUID()
    let date: Date
    let open: Double
    let close: Double
    let high: Double
    let low: Double
    let volume: Int
}

// Population Data
struct PopulationData: Identifiable {
    let id = UUID()
    let age: Int
    let count: Int
    let gender: String
}

// Weather Data
struct WeatherData: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let humidity: Double
    let precipitation: Double
}

// 3D Point Data
struct Point3DData: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let z: Double
    let category: String
    let size: Double
}

// Heat Map Data
struct HeatMapData: Identifiable {
    let id = UUID()
    let x: String
    let y: String
    let value: Double
}

// Multi Series Data
struct MultiSeriesData: Identifiable {
    let id = UUID()
    let date: Date
    let series: String
    let value: Double
}

// MARK: - 차트 뷰 파일에 정의되지 않은 추가 데이터 모델들만 여기 정의
// (WaterfallData, BoxPlotData, RadarData, TreemapData, GanttTask, Point3DEnhanced는
//  각 차트 뷰 파일에 이미 정의되어 있으므로 여기서는 정의하지 않음)

// Violin Plot Data
struct ViolinPlotData: Identifiable {
    let id = UUID()
    let category: String
    let values: [Double]
    let quartiles: [Double]
    let densityCurve: [(x: Double, y: Double)]
}

// Stream Graph Data
struct StreamGraphData: Identifiable {
    let id = UUID()
    let date: Date
    let series: String
    let value: Double
    let baseline: Double
}

// Sunburst Data
struct SunburstData: Identifiable {
    let id = UUID()
    let name: String
    let parent: String?
    let value: Double
    let level: Int
    let startAngle: Double
    let endAngle: Double
    let color: Color
}

// Gauge Data
struct GaugeData: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let min: Double
    let max: Double
    let thresholds: [Threshold]
    
    struct Threshold {
        let value: Double
        let color: Color
        let label: String
    }
}

// Funnel Data
struct FunnelData: Identifiable {
    let id = UUID()
    let stage: String
    let value: Double
    let conversionRate: Double
    let dropoffRate: Double
    let color: Color
}

// Histogram Data
struct HistogramData: Identifiable {
    let id = UUID()
    let bin: String
    let frequency: Int
    let range: ClosedRange<Double>
    let normalizedFrequency: Double
}

// Density Plot Data
struct DensityData: Identifiable {
    let id = UUID()
    let x: Double
    let density: Double
    let cumulativeDensity: Double
}

// Bubble Chart Data
struct BubbleData: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let category: String
    let label: String
    let growth: Double
    let color: Color
}

// Correlation Matrix Data
struct CorrelationData: Identifiable {
    let id = UUID()
    let rowLabel: String
    let columnLabel: String
    let correlation: Double
    
    var color: Color {
        if correlation > 0.7 {
            return .green
        } else if correlation > 0.3 {
            return .yellow
        } else if correlation < -0.7 {
            return .red
        } else if correlation < -0.3 {
            return .orange
        } else {
            return .gray
        }
    }
}

// 3D Vector Data
struct Vector3DData: Identifiable {
    let id = UUID()
    let origin: SIMD3<Float>
    let direction: SIMD3<Float>
    let magnitude: Float
    let category: String
    let color: Color
}

// 3D Surface Data
struct Surface3DData: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let z: Double
    let gradient: Color
}

// Polar Chart Data
struct PolarData: Identifiable {
    let id = UUID()
    let angle: Double
    let radius: Double
    let category: String
    let color: Color
}

// Ridgeline Data
struct RidgelineData: Identifiable {
    let id = UUID()
    let category: String
    let values: [Double]
    let offset: Double
    let color: Color
}
