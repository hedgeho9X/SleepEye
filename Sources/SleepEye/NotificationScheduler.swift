import Foundation
import UserNotifications

/// 调度本地系统通知。
///
/// 系统通知是顶部浮层的兜底：当用户处在全屏应用、外接屏或没有注意菜单栏时，
/// 仍然能收到“该休息了”的提醒。权限请求采用懒触发，避免应用首次启动就打断用户。
final class NotificationScheduler {
    private let center: UNUserNotificationCenter
    private var hasRequestedAuthorization = false

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// 专注结束时发送休息提醒。
    func deliverFocusCompleted() {
        deliver(
            identifier: "sleepeye.focusCompleted.\(UUID().uuidString)",
            title: "该休息眼睛了",
            body: "看远处、眨眨眼，给自己一个短暂停顿。"
        )
    }

    /// 休息结束时发送回到专注的提醒。
    func deliverBreakCompleted(autoStartedNextRound: Bool) {
        let body = autoStartedNextRound ? "下一轮专注已经开始，慢慢回到任务里。" : "休息结束，可以决定是否开始下一轮。"
        deliver(
            identifier: "sleepeye.breakCompleted.\(UUID().uuidString)",
            title: "休息结束",
            body: body
        )
    }

    private func deliver(identifier: String, title: String, body: String) {
        requestAuthorizationIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // 不设置 trigger 会让通知尽快送达，适合“当前阶段刚结束”的即时提醒。
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request)
    }

    private func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuthorization else {
            return
        }

        hasRequestedAuthorization = true
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else {
                return
            }

            center.requestAuthorization(options: [.alert, .sound]) { _, _ in
                // 用户拒绝通知时，应用仍然可以依靠菜单栏和顶部浮层工作。
            }
        }
    }
}
