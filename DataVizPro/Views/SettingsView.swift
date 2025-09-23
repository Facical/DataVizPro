import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("데이터 설정") {
                    Picker("시간 범위", selection: $dataManager.selectedTimeRange) {
                        ForEach(DataManager.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    
                    Toggle("자동 새로고침", isOn: $dataManager.isAnimating)
                    
                    Button("모든 데이터 새로고침") {
                        dataManager.refreshAllData()
                    }
                }
                
                Section("차트 설정") {
                    // 여기에 차트별 설정 추가
                }
            }
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}
