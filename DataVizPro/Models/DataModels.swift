import Foundation
import SwiftUI

// MARK: - Sales Data
struct SalesData: Identifiable {
    let id = UUID()
    let month: String
    let sales: Double
    let year: Int
    let category: String
}

// MARK: - Profit Data
struct ProfitData: Identifiable {
    let id = UUID()
    let department: String
    let profit: Double
    let quarter: String
}

// MARK: - Stock Data
struct StockData: Identifiable {
    let id = UUID()
    let date: Date
    let open: Double
    let close: Double
    let high: Double
    let low: Double
    let volume: Int
}

// MARK: - Population Data
struct PopulationData: Identifiable {
    let id = UUID()
    let age: Int
    let count: Int
    let gender: String
}

// MARK: - Weather Data
struct WeatherData: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let humidity: Double
    let precipitation: Double
}

// MARK: - 3D Point Data
struct Point3DData: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let z: Double
    let category: String
    let size: Double
}

// MARK: - Heat Map Data
struct HeatMapData: Identifiable {
    let id = UUID()
    let x: String
    let y: String
    let value: Double
}

// MARK: - Multi Series Data
struct MultiSeriesData: Identifiable {
    let id = UUID()
    let date: Date
    let series: String
    let value: Double
}
