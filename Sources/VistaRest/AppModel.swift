import AppKit
import Combine
import Foundation
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state: TimerState
    @Published private(set) var displayRemainingSeconds = 0
    @Published private(set) var stats: DailyStats
    @Published var preferences: AppPreferences {
        didSet {
            store.savePreferences(preferences)
        }
    }

    private let store: LocalStore
    private let overlayController: BreakOverlayController
    private var ticker: Timer?
    private var lastTickDate = Date()
    private var focusedFractionalSeconds: TimeInterval = 0
    private var currentFocusSeconds: TimeInterval = 0
    private var hasRequestedNotifications = false
    private var breakInstructionIndex = 0

    private let longBreakInstructions = [
        "起身走动一下",
        "喝一点水",
        "看一会儿窗外",
        "转动肩膀",
        "闭眼放松",
        "慢慢眨眼十次"
    ]

    init(store: LocalStore = LocalStore()) {
        self.store = store
        self.overlayController = BreakOverlayController()
        self.preferences = store.loadPreferences()
        self.state = store.loadTimerState()
        self.stats = store.loadDailyStats()

        if self.stats.dayKey != DailyStats.currentDayKey() {
            self.stats = DailyStats()
        }

        if self.state.phase == .idle {
            self.state.mode = self.preferences.mode
            self.state.isRunning = false
            self.state.expectedEndDate = nil
            self.state.remainingSeconds = 0
        }

        self.displayRemainingSeconds = max(0, Int(ceil(self.state.remainingSeconds)))
        self.lastTickDate = Date()
        self.startTicker()

        if self.state.isRunning {
            tick()
        }
    }

    deinit {
        ticker?.invalidate()
    }

    var currentMode: TimerMode {
        state.phase == .idle ? preferences.mode : state.mode
    }

    var phaseTitle: String {
        state.phase.title
    }

    var primaryActionTitle: String {
        if state.phase == .idle { return "开始专注" }
        return state.isRunning ? "暂停" : (state.phase.isBreak ? "继续休息" : "继续专注")
    }

    var formattedRemaining: String {
        guard state.phase != .idle else { return "--:--" }
        let seconds = max(displayRemainingSeconds, 0)
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    var formattedFocusedTime: String {
        let totalMinutes = stats.focusedSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 { return String(format: "%d 小时 %d 分", hours, minutes) }
        return String(format: "%d 分钟", minutes)
    }

    var progress: Double {
        guard state.phase != .idle else { return 0 }
        let duration = durationForCurrentPhase
        guard duration > 0 else { return 0 }
        return min(1, max(0, 1 - state.remainingSeconds / duration))
    }

    var breakInstruction: String {
        if state.phase == .longBreak {
            return longBreakInstructions[breakInstructionIndex % longBreakInstructions.count]
        }
        return "找一个至少几米外的物体，放松视线"
    }

    func toggleRunning() {
        if state.phase == .idle {
            start()
        } else if state.isRunning {
            pause()
        } else {
            resume()
        }
    }

    func start() {
        requestNotificationPermissionIfNeeded()

        guard state.phase == .idle else {
            resume()
            return
        }

        state.mode = preferences.mode
        state.classicCompletedRounds = 0
        state.deepSegment = 0
        beginPhase(.working, duration: workDurationForCurrentMode, running: true)
    }

    func pause() {
        guard state.isRunning else { return }
        tick()
        state.remainingSeconds = max(0, state.expectedEndDate?.timeIntervalSinceNow ?? state.remainingSeconds)
        state.expectedEndDate = nil
        state.isRunning = false
        currentFocusSeconds = 0
        save()
    }

    func resume() {
        guard state.phase != .idle else {
            start()
            return
        }

        guard !state.isRunning else { return }
        state.isRunning = true
        state.expectedEndDate = Date().addingTimeInterval(max(1, state.remainingSeconds))
        lastTickDate = Date()
        save()
    }

    func takeBreakNow() {
        guard state.phase == .working else { return }
        tick()
        stats.skippedCount += 1
        beginBreakAfterWork()
    }

    func skipCurrentPhase() {
        guard state.phase != .idle else { return }
        tick()
        stats.skippedCount += 1

        if state.phase == .working {
            beginBreakAfterWork()
        } else {
            beginNextWorkPhase()
        }
    }

    func reset() {
        overlayController.hide()
        state = TimerState(mode: preferences.mode)
        displayRemainingSeconds = 0
        currentFocusSeconds = 0
        focusedFractionalSeconds = 0
        save()
    }

    func selectMode(_ mode: TimerMode) {
        preferences.mode = mode
        guard state.phase == .idle else { return }
        state.mode = mode
        save()
    }

    func updatePreferences(_ update: (inout AppPreferences) -> Void) {
        var next = preferences
        update(&next)
        preferences = next
    }

    func deleteLocalData() {
        reset()
        preferences = AppPreferences()
        stats = DailyStats()
        store.saveDailyStats(stats)
    }

    private var durationForCurrentPhase: TimeInterval {
        duration(for: state.phase, mode: state.mode)
    }

    private var workDurationForCurrentMode: TimeInterval {
        switch preferences.mode {
        case .eyeCare:
            return minutes(preferences.eyeCareWorkMinutes)
        case .pomodoro:
            return minutes(preferences.pomodoroWorkMinutes)
        case .deepWork:
            return deepSegmentDuration(for: 0)
        }
    }

    private func startTicker() {
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        let now = Date()
        ensureToday()

        if state.isRunning {
            let elapsed = min(2, max(0, now.timeIntervalSince(lastTickDate)))
            if state.phase == .working {
                recordFocusedTime(elapsed)
            }

            if let expectedEndDate = state.expectedEndDate, now >= expectedEndDate {
                finishCurrentPhase()
            } else {
                state.remainingSeconds = max(0, state.expectedEndDate?.timeIntervalSince(now) ?? state.remainingSeconds)
                displayRemainingSeconds = max(0, Int(ceil(state.remainingSeconds)))
                save()
            }
        }

        lastTickDate = now
    }

    private func recordFocusedTime(_ elapsed: TimeInterval) {
        guard elapsed > 0 else { return }
        focusedFractionalSeconds += elapsed
        currentFocusSeconds += elapsed

        let wholeSeconds = Int(focusedFractionalSeconds.rounded(.down))
        if wholeSeconds > 0 {
            stats.focusedSeconds += wholeSeconds
            focusedFractionalSeconds -= TimeInterval(wholeSeconds)
        }

        stats.longestFocusSeconds = max(stats.longestFocusSeconds, Int(currentFocusSeconds.rounded(.down)))
    }

    private func finishCurrentPhase() {
        switch state.phase {
        case .working:
            switch state.mode {
            case .eyeCare:
                beginPhase(.microBreak, duration: microBreakDuration, running: preferences.autoStartNextPhase)
            case .pomodoro:
                state.classicCompletedRounds += 1
                if state.classicCompletedRounds >= 4 {
                    state.classicCompletedRounds = 0
                    beginPhase(.longBreak, duration: pomodoroLongBreakDuration, running: preferences.autoStartNextPhase)
                } else {
                    beginPhase(.shortBreak, duration: pomodoroShortBreakDuration, running: preferences.autoStartNextPhase)
                }
            case .deepWork:
                if state.deepSegment + 1 < deepSegmentCount {
                    beginPhase(.microBreak, duration: microBreakDuration, running: preferences.autoStartNextPhase)
                } else {
                    state.deepSegment = 0
                    beginPhase(.longBreak, duration: deepLongBreakDuration, running: preferences.autoStartNextPhase)
                }
            }
        case .microBreak:
            stats.completedBreaks += 1
            if state.mode == .deepWork {
                state.deepSegment += 1
            }
            beginNextWorkPhase()
        case .shortBreak:
            stats.completedBreaks += 1
            beginNextWorkPhase()
        case .longBreak:
            stats.completedBreaks += 1
            state.classicCompletedRounds = 0
            state.deepSegment = 0
            beginNextWorkPhase()
        case .idle:
            return
        }
    }

    private func beginBreakAfterWork() {
        switch state.mode {
        case .eyeCare:
            beginPhase(.microBreak, duration: microBreakDuration, running: preferences.autoStartNextPhase)
        case .pomodoro:
            beginPhase(.shortBreak, duration: pomodoroShortBreakDuration, running: preferences.autoStartNextPhase)
        case .deepWork:
            if state.deepSegment + 1 < deepSegmentCount {
                beginPhase(.microBreak, duration: microBreakDuration, running: preferences.autoStartNextPhase)
            } else {
                state.deepSegment = 0
                beginPhase(.longBreak, duration: deepLongBreakDuration, running: preferences.autoStartNextPhase)
            }
        }
    }

    private func beginNextWorkPhase() {
        let duration: TimeInterval
        switch state.mode {
        case .eyeCare:
            duration = minutes(preferences.eyeCareWorkMinutes)
        case .pomodoro:
            duration = minutes(preferences.pomodoroWorkMinutes)
        case .deepWork:
            duration = deepSegmentDuration(for: state.deepSegment)
        }
        beginPhase(.working, duration: duration, running: preferences.autoStartNextPhase)
    }

    private func beginPhase(_ phase: TimerPhase, duration: TimeInterval, running: Bool) {
        state.phase = phase
        state.remainingSeconds = max(1, duration)
        state.isRunning = running
        state.expectedEndDate = running ? Date().addingTimeInterval(state.remainingSeconds) : nil
        displayRemainingSeconds = max(0, Int(ceil(state.remainingSeconds)))
        lastTickDate = Date()

        if phase == .working {
            overlayController.hide()
        } else {
            currentFocusSeconds = 0
            breakInstructionIndex += 1
            notifyBreak()
            if preferences.reminderStyle != .gentle {
                overlayController.show(model: self)
            }
        }
        save()
    }

    private func notifyBreak() {
        guard canUseSystemNotifications else {
            if preferences.soundEnabled {
                NSSound.beep()
            }
            return
        }

        let content = UNMutableNotificationContent()
        content.title = state.phase == .longBreak ? "该离开屏幕了" : "该看远处了"
        content.body = state.phase == .longBreak ? breakInstruction : "放松眼睛，慢慢眨眼"
        if preferences.soundEnabled {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "vistarest.break.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        if preferences.soundEnabled {
            NSSound.beep()
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        guard canUseSystemNotifications, !hasRequestedNotifications else { return }
        hasRequestedNotifications = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private var canUseSystemNotifications: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    private func ensureToday() {
        let today = DailyStats.currentDayKey()
        guard stats.dayKey != today else { return }
        stats = DailyStats(dayKey: today)
        focusedFractionalSeconds = 0
        currentFocusSeconds = 0
        store.saveDailyStats(stats)
    }

    private func save() {
        store.saveTimerState(state)
        store.saveDailyStats(stats)
    }

    private func duration(for phase: TimerPhase, mode: TimerMode) -> TimeInterval {
        switch phase {
        case .idle:
            return 0
        case .working:
            switch mode {
            case .eyeCare: return minutes(preferences.eyeCareWorkMinutes)
            case .pomodoro: return minutes(preferences.pomodoroWorkMinutes)
            case .deepWork: return deepSegmentDuration(for: state.deepSegment)
            }
        case .microBreak:
            return microBreakDuration
        case .shortBreak:
            return pomodoroShortBreakDuration
        case .longBreak:
            return mode == .deepWork ? deepLongBreakDuration : pomodoroLongBreakDuration
        }
    }

    private var microBreakDuration: TimeInterval {
        TimeInterval(max(5, preferences.microBreakSeconds))
    }

    private var pomodoroShortBreakDuration: TimeInterval {
        minutes(preferences.pomodoroShortBreakMinutes)
    }

    private var pomodoroLongBreakDuration: TimeInterval {
        minutes(preferences.pomodoroLongBreakMinutes)
    }

    private var deepLongBreakDuration: TimeInterval {
        minutes(preferences.deepLongBreakMinutes)
    }

    private var deepSegmentCount: Int {
        let total = max(1, preferences.deepWorkMinutes)
        let interval = max(1, min(preferences.deepBreakIntervalMinutes, total))
        return max(1, Int(ceil(Double(total) / Double(interval))))
    }

    private func deepSegmentDuration(for segment: Int) -> TimeInterval {
        let total = max(1, preferences.deepWorkMinutes)
        let interval = max(1, min(preferences.deepBreakIntervalMinutes, total))
        let remaining = total - segment * interval
        return minutes(max(1, min(interval, remaining)))
    }

    private func minutes(_ value: Int) -> TimeInterval {
        TimeInterval(max(1, value) * 60)
    }
}
