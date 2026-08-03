import Foundation

@MainActor
enum SelfCheck {
    static func run() {
        let suiteName = "VistaRestSelfCheck.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = LocalStore(defaults: defaults)

        let model = AppModel(store: store)
        model.updatePreferences {
            $0.mode = .eyeCare
            $0.eyeCareWorkMinutes = 1
        }
        model.selectMode(.eyeCare)
        model.start()
        model.pause()

        precondition(model.state.phase == .working, "A started timer should be working")
        precondition(!model.state.isRunning, "Paused timer should not be running")
        precondition(model.state.remainingSeconds > 0, "Paused timer should retain time")

        let restored = AppModel(store: store)
        precondition(restored.state.phase == .working, "Timer phase should persist")
        precondition(!restored.state.isRunning, "Paused state should persist")
        precondition(restored.state.remainingSeconds > 0, "Remaining time should persist")

        model.reset()
        restored.reset()
        defaults.removePersistentDomain(forName: suiteName)
        print("VistaRest self-check passed")
    }
}
