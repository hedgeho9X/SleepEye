import SwiftUI

/// SleepEye 的界面色彩集中定义。
///
/// 护眼应用的提醒颜色不能过于高饱和，否则提示本身会变成视觉负担。
/// 这里优先使用低饱和、偏灰的绿色，让用户能看清状态，又不会被亮绿色晃到。
enum SleepEyePalette {
    static let restAccent = Color(red: 0.45, green: 0.78, blue: 0.47)
    static let restAccentSoft = Color(red: 0.82, green: 0.95, blue: 0.83)
    static let restBackground = Color.white.opacity(0.86)
}
