import Foundation

struct LocalStore {
    private static let preferencesKey = "vistarest.preferences"
    private static let timerStateKey = "vistarest.timer-state"
    private static let dailyStatsKey = "vistarest.daily-stats"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadPreferences() -> AppPreferences {
        load(AppPreferences.self, forKey: Self.preferencesKey) ?? AppPreferences()
    }

    func savePreferences(_ preferences: AppPreferences) {
        save(preferences, forKey: Self.preferencesKey)
    }

    func loadTimerState() -> TimerState {
        load(TimerState.self, forKey: Self.timerStateKey) ?? TimerState()
    }

    func saveTimerState(_ state: TimerState) {
        save(state, forKey: Self.timerStateKey)
    }

    func loadDailyStats() -> DailyStats {
        load(DailyStats.self, forKey: Self.dailyStatsKey) ?? DailyStats()
    }

    func saveDailyStats(_ stats: DailyStats) {
        save(stats, forKey: Self.dailyStatsKey)
    }

    private func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
