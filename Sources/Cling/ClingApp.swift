import SwiftUI

@main
struct ClingApp: App {
    @State private var model: AppModel

    init() {
        // Menu bar only — no Dock icon, even when run outside a bundle.
        NSApplication.shared.setActivationPolicy(.accessory)
        _model = State(initialValue: AppModel())
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(model)
        } label: {
            Image(systemName: "trophy.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
