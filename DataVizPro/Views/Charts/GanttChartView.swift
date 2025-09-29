import SwiftUI
import Charts

// 간트 차트 데이터 모델
struct GanttTask: Identifiable {
    let id = UUID()
    let taskName: String
    let category: String
    let startDate: Date
    let endDate: Date
    let progress: Double
    let dependencies: [String]
    let assignee: String
    let priority: Priority
    
    enum Priority: String, CaseIterable {
        case low = "낮음"
        case medium = "중간"
        case high = "높음"
        case critical = "긴급"
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var durationDays: Int {
        Int(duration / (24 * 60 * 60))
    }
}

struct GanttChartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTask: GanttTask?
    @State private var showDependencies = true
    @State private var groupByCategory = false
    @State private var currentDate = Date()
    
    // 샘플 프로젝트 데이터 생성
    var ganttTasks: [GanttTask] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            // 기획 단계
            GanttTask(
                taskName: "요구사항 분석",
                category: "기획",
                startDate: calendar.date(byAdding: .day, value: -30, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -25, to: today)!,
                progress: 100,
                dependencies: [],
                assignee: "김기획",
                priority: .high
            ),
            GanttTask(
                taskName: "프로젝트 계획 수립",
                category: "기획",
                startDate: calendar.date(byAdding: .day, value: -25, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -20, to: today)!,
                progress: 100,
                dependencies: ["요구사항 분석"],
                assignee: "김기획",
                priority: .high
            ),
            
            // 디자인 단계
            GanttTask(
                taskName: "UI/UX 디자인",
                category: "디자인",
                startDate: calendar.date(byAdding: .day, value: -20, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -10, to: today)!,
                progress: 100,
                dependencies: ["프로젝트 계획 수립"],
                assignee: "이디자인",
                priority: .medium
            ),
            GanttTask(
                taskName: "프로토타입 제작",
                category: "디자인",
                startDate: calendar.date(byAdding: .day, value: -10, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -5, to: today)!,
                progress: 100,
                dependencies: ["UI/UX 디자인"],
                assignee: "이디자인",
                priority: .medium
            ),
            
            // 개발 단계
            GanttTask(
                taskName: "백엔드 개발",
                category: "개발",
                startDate: calendar.date(byAdding: .day, value: -5, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 10, to: today)!,
                progress: 60,
                dependencies: ["프로토타입 제작"],
                assignee: "박개발",
                priority: .critical
            ),
            GanttTask(
                taskName: "프론트엔드 개발",
                category: "개발",
                startDate: calendar.date(byAdding: .day, value: 0, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 15, to: today)!,
                progress: 30,
                dependencies: ["프로토타입 제작"],
                assignee: "최개발",
                priority: .critical
            ),
            GanttTask(
                taskName: "API 통합",
                category: "개발",
                startDate: calendar.date(byAdding: .day, value: 10, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 20, to: today)!,
                progress: 0,
                dependencies: ["백엔드 개발", "프론트엔드 개발"],
                assignee: "박개발",
                priority: .high
            ),
            
            // 테스트 단계
            GanttTask(
                taskName: "단위 테스트",
                category: "테스트",
                startDate: calendar.date(byAdding: .day, value: 15, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 20, to: today)!,
                progress: 0,
                dependencies: ["API 통합"],
                assignee: "정테스트",
                priority: .medium
            ),
            GanttTask(
                taskName: "통합 테스트",
                category: "테스트",
                startDate: calendar.date(byAdding: .day, value: 20, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 25, to: today)!,
                progress: 0,
                dependencies: ["단위 테스트"],
                assignee: "정테스트",
                priority: .high
            ),
            
            // 배포 단계
            GanttTask(
                taskName: "배포 준비",
                category: "배포",
                startDate: calendar.date(byAdding: .day, value: 25, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 27, to: today)!,
                progress: 0,
                dependencies: ["통합 테스트"],
                assignee: "강운영",
                priority: .critical
            ),
            GanttTask(
                taskName: "프로덕션 배포",
                category: "배포",
                startDate: calendar.date(byAdding: .day, value: 27, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 30, to: today)!,
                progress: 0,
                dependencies: ["배포 준비"],
                assignee: "강운영",
                priority: .critical
            )
        ]
    }
    
    var sortedTasks: [GanttTask] {
        if groupByCategory {
            return ganttTasks.sorted { $0.category < $1.category || ($0.category == $1.category && $0.startDate < $1.startDate) }
        } else {
            return ganttTasks.sorted { $0.startDate < $1.startDate }
        }
    }
    
    var dateRange: ClosedRange<Date> {
        let minDate = ganttTasks.map { $0.startDate }.min() ?? Date()
        let maxDate = ganttTasks.map { $0.endDate }.max() ?? Date()
        return minDate...maxDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("간트 차트")
                    .font(.title2)
                    .bold()
                Text("프로젝트 일정 관리")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 간트 차트
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // 헤더 (날짜)
                    HStack(spacing: 0) {
                        // 작업명 열 헤더
                        Text("작업")
                            .font(.caption)
                            .bold()
                            .frame(width: 150, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .border(Color.gray.opacity(0.3), width: 0.5)
                        
                        // 날짜 헤더
                        ForEach(dateSequence(from: dateRange.lowerBound, to: dateRange.upperBound), id: \.self) { date in
                            VStack(spacing: 2) {
                                Text(date, format: .dateTime.month(.abbreviated))
                                    .font(.caption2)
                                Text(date, format: .dateTime.day())
                                    .font(.caption)
                                    .bold()
                            }
                            .frame(width: 30)
                            .padding(.vertical, 5)
                            .background(
                                Calendar.current.isDateInWeekend(date)
                                ? Color.gray.opacity(0.1)
                                : Color.clear
                            )
                            .border(Color.gray.opacity(0.3), width: 0.5)
                        }
                    }
                    
                    // 작업 행들
                    ForEach(sortedTasks) { task in
                        GanttRow(
                            task: task,
                            dateRange: dateRange,
                            currentDate: currentDate,
                            isSelected: selectedTask?.id == task.id,
                            showDependencies: showDependencies,
                            allTasks: ganttTasks
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedTask = task
                            }
                        }
                    }
                    
                    // 현재 날짜 라인
                    GeometryReader { geometry in
                        let dayWidth: CGFloat = 30
                        let totalDays = Calendar.current.dateComponents([.day], from: dateRange.lowerBound, to: currentDate).day ?? 0
                        let xPosition = 150 + CGFloat(totalDays) * dayWidth
                        
                        Rectangle()
                            .fill(Color.red.opacity(0.5))
                            .frame(width: 2, height: geometry.size.height)
                            .position(x: xPosition, y: geometry.size.height / 2)
                    }
                    .frame(height: 0)
                }
            }
            .frame(maxHeight: 400)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // 선택된 작업 정보
            if let task = selectedTask {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(task.taskName, systemImage: "checkmark.circle")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(task.priority.rawValue) 우선순위")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(task.priority.color.opacity(0.2))
                            .foregroundColor(task.priority.color)
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: 20) {
                        Label(task.assignee, systemImage: "person.fill")
                            .font(.caption)
                        
                        Label("\(task.durationDays)일", systemImage: "calendar")
                            .font(.caption)
                        
                        Label("\(Int(task.progress))% 완료", systemImage: "chart.pie")
                            .font(.caption)
                            .foregroundColor(task.progress == 100 ? .green : .orange)
                    }
                    
                    if !task.dependencies.isEmpty {
                        HStack {
                            Text("선행 작업:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(task.dependencies.joined(separator: ", "))
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // 컨트롤
            VStack(spacing: 12) {
                Toggle("카테고리별 그룹", isOn: $groupByCategory)
                Toggle("의존성 표시", isOn: $showDependencies)
            }
            .padding(.horizontal)
        }
    }
    
    func dateSequence(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
}

// 간트 차트 행 컴포넌트
struct GanttRow: View {
    let task: GanttTask
    let dateRange: ClosedRange<Date>
    let currentDate: Date
    let isSelected: Bool
    let showDependencies: Bool
    let allTasks: [GanttTask]
    
    var body: some View {
        HStack(spacing: 0) {
            // 작업명
            HStack {
                Circle()
                    .fill(categoryColor(task.category))
                    .frame(width: 6, height: 6)
                
                Text(task.taskName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 150, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .border(Color.gray.opacity(0.3), width: 0.5)
            
            // 타임라인
            GeometryReader { geometry in
                let dayWidth: CGFloat = 30
                let startOffset = CGFloat(daysBetween(dateRange.lowerBound, task.startDate)) * dayWidth
                let taskWidth = CGFloat(daysBetween(task.startDate, task.endDate)) * dayWidth
                
                ZStack(alignment: .leading) {
                    // 배경 그리드
                    ForEach(dateSequence(from: dateRange.lowerBound, to: dateRange.upperBound), id: \.self) { date in
                        let offset = CGFloat(daysBetween(dateRange.lowerBound, date)) * dayWidth
                        Rectangle()
                            .fill(Calendar.current.isDateInWeekend(date) ? Color.gray.opacity(0.05) : Color.clear)
                            .frame(width: dayWidth, height: 40)
                            .border(Color.gray.opacity(0.2), width: 0.5)
                            .offset(x: offset)
                    }
                    
                    // 작업 막대
                    RoundedRectangle(cornerRadius: 4)
                        .fill(task.priority.color.opacity(0.3))
                        .frame(width: taskWidth, height: 20)
                        .overlay(
                            // 진행률 표시
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(task.priority.color)
                                    .frame(width: geo.size.width * task.progress / 100, height: 20)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .offset(x: startOffset, y: 10)
                }
            }
            .frame(height: 40)
        }
    }
    
    func categoryColor(_ category: String) -> Color {
        switch category {
        case "기획": return .purple
        case "디자인": return .pink
        case "개발": return .blue
        case "테스트": return .orange
        case "배포": return .green
        default: return .gray
        }
    }
    
    func daysBetween(_ startDate: Date, _ endDate: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    func dateSequence(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
}
