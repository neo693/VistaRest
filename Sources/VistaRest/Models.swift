import Foundation

enum TimerMode: String, CaseIterable, Codable, Identifiable {
    case eyeCare
    case pomodoro
    case deepWork

    var id: String { rawValue }

    var title: String {
        switch self {
        case .eyeCare: return "护眼模式"
        case .pomodoro: return "经典番茄"
        case .deepWork: return "深度工作"
        }
    }

    var subtitle: String {
        switch self {
        case .eyeCare: return "20 分钟工作，远眺 20 秒"
        case .pomodoro: return "25 分钟专注，5 分钟休息"
        case .deepWork: return "50 分钟工作，中途两次远眺"
        }
    }

    var symbolName: String {
        switch self {
        case .eyeCare: return "eye"
        case .pomodoro: return "timer"
        case .deepWork: return "bolt"
        }
    }
}

enum ReminderStyle: String, CaseIterable, Codable, Identifiable {
    case gentle
    case standard
    case strict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: return "轻柔提醒"
        case .standard: return "标准提醒"
        case .strict: return "严格遮罩"
        }
    }

    var subtitle: String {
        switch self {
        case .gentle: return "通知和提示音，可以直接跳过"
        case .standard: return "通知加上居中的休息提示"
        case .strict: return "多显示器半透明遮罩"
        }
    }
}

enum TimerPhase: String, Codable {
    case idle
    case working
    case microBreak
    case shortBreak
    case longBreak

    var isBreak: Bool {
        self == .microBreak || self == .shortBreak || self == .longBreak
    }

    var title: String {
        switch self {
        case .idle: return "准备开始"
        case .working: return "正在专注"
        case .microBreak: return "护眼微休息"
        case .shortBreak: return "短休息"
        case .longBreak: return "离屏长休息"
        }
    }
}

struct TimerState: Codable {
    var mode: TimerMode = .eyeCare
    var phase: TimerPhase = .idle
    var isRunning = false
    var expectedEndDate: Date?
    var remainingSeconds: TimeInterval = 0
    var classicCompletedRounds = 0
    var deepSegment = 0
}

struct DailyStats: Codable {
    var dayKey: String
    var focusedSeconds = 0
    var completedBreaks = 0
    var skippedCount = 0
    var longestFocusSeconds = 0

    init(dayKey: String = Self.currentDayKey()) {
        self.dayKey = dayKey
    }

    static func currentDayKey(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct AppPreferences: Codable {
    var mode: TimerMode = .eyeCare
    var reminderStyle: ReminderStyle = .standard
    var soundEnabled = true
    var autoStartNextPhase = true
    var showRemainingInMenuBar = true

    var eyeCareWorkMinutes = 20
    var microBreakSeconds = 20

    var pomodoroWorkMinutes = 25
    var pomodoroShortBreakMinutes = 5
    var pomodoroLongBreakMinutes = 15

    var deepWorkMinutes = 50
    var deepBreakIntervalMinutes = 20
    var deepLongBreakMinutes = 10

    private enum CodingKeys: String, CodingKey {
        case mode
        case reminderStyle
        case soundEnabled
        case autoStartNextPhase
        case showRemainingInMenuBar
        case eyeCareWorkMinutes
        case microBreakSeconds
        case pomodoroWorkMinutes
        case pomodoroShortBreakMinutes
        case pomodoroLongBreakMinutes
        case deepWorkMinutes
        case deepBreakIntervalMinutes
        case deepLongBreakMinutes
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(TimerMode.self, forKey: .mode) ?? .eyeCare
        reminderStyle = try container.decodeIfPresent(ReminderStyle.self, forKey: .reminderStyle) ?? .standard
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        autoStartNextPhase = try container.decodeIfPresent(Bool.self, forKey: .autoStartNextPhase) ?? true
        showRemainingInMenuBar = try container.decodeIfPresent(Bool.self, forKey: .showRemainingInMenuBar) ?? true
        eyeCareWorkMinutes = try container.decodeIfPresent(Int.self, forKey: .eyeCareWorkMinutes) ?? 20
        microBreakSeconds = try container.decodeIfPresent(Int.self, forKey: .microBreakSeconds) ?? 20
        pomodoroWorkMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroWorkMinutes) ?? 25
        pomodoroShortBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroShortBreakMinutes) ?? 5
        pomodoroLongBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroLongBreakMinutes) ?? 15
        deepWorkMinutes = try container.decodeIfPresent(Int.self, forKey: .deepWorkMinutes) ?? 50
        deepBreakIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .deepBreakIntervalMinutes) ?? 20
        deepLongBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .deepLongBreakMinutes) ?? 10
    }
}
