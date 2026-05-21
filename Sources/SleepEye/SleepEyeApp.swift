import AppKit
import SwiftUI

/// SleepEye 的 macOS 应用入口。
///
/// 当前版本只提供菜单栏入口和设置窗口。应用启动后设置为 accessory，
/// 让它更像系统小工具，而不是一个占据 Dock 和 Cmd-Tab 的完整桌面应用。
@main
struct SleepEyeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Label(appState.menuBarTitle, systemImage: appState.menuBarSymbol)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: appState.settings)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
