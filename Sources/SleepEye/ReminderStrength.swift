import Foundation

/// 休息提醒强度。
///
/// MVP 阶段只改变提醒的文案和浮层存在感，不做强制锁屏或键鼠拦截。
/// 这样可以先建立用户信任，避免护眼工具变成新的打扰源。
enum ReminderStrength: String, CaseIterable, Identifiable {
    case gentle
    case standard
    case strong

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle:
            "轻提醒"
        case .standard:
            "标准提醒"
        case .strong:
            "明显提醒"
        }
    }

    var description: String {
        switch self {
        case .gentle:
            "只在关键节点轻轻提示。"
        case .standard:
            "显示顶部胶囊并发送系统通知。"
        case .strong:
            "休息时保持更明显的顶部提示。"
        }
    }
}
