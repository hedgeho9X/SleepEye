import AppKit
import SwiftUI

enum SleepEyeWindowID {
    static let dashboard = "sleepEyeDashboard"
}

/// SleepEye 的 macOS 应用入口。
///
/// release 版本同时提供完整主窗口和菜单栏入口：主窗口承载状态、统计和设置摘要，
/// 菜单栏负责常驻状态与快捷操作。两者共享同一个 `AppState`，避免状态分叉。
@main
struct SleepEyeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("SleepEye", id: SleepEyeWindowID.dashboard) {
            DashboardView(appState: appState)
        }
        .defaultSize(width: 860, height: 640)

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
        // SleepEye 仍然常驻菜单栏，但 release 目标需要一个可见的主应用窗口。
        // 使用 regular 让用户能从 Dock、Cmd-Tab 和菜单栏共同回到应用。
        NSApp.setActivationPolicy(.regular)
    }
}
