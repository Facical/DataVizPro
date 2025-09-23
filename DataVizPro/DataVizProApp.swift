import SwiftUI

@main
struct DataVizProApp: App {
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
        #if os(visionOS)
        .windowStyle(.plain)
        .defaultSize(CGSize(width: 1200, height: 800))
        #endif
    }
}
