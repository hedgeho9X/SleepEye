import SwiftUI

/// SleepEye 的界面色彩集中定义。
///
/// 护眼应用的提醒颜色不能过于高饱和，否则提示本身会变成视觉负担。
/// 这里优先使用低饱和、偏灰的绿色，让用户能看清状态，又不会被亮绿色晃到。
enum SleepEyePalette {
    static let restAccent = Color(red: 0.25, green: 0.52, blue: 0.38)
    static let restAccentSoft = Color(red: 0.82, green: 0.90, blue: 0.84)
    static let restBackground = Color(red: 0.95, green: 0.98, blue: 0.95)
}
