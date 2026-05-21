import SwiftUI

/// SleepEye 的界面色彩集中定义。
///
/// 护眼应用的提醒颜色不能过于高饱和，否则提示本身会变成视觉负担。
/// 这里优先使用低饱和、偏灰的绿色，让用户能看清状态，又不会被亮绿色晃到。
enum SleepEyePalette {
    static let restAccent = Color(red: 0.45, green: 0.78, blue: 0.47)
    static let restBackground = Color.white
    static let restBackgroundSoft = Color(red: 0.94, green: 0.99, blue: 0.94)
    static let restSurface = Color.white
    static let restRingTrack = Color(red: 0.86, green: 0.93, blue: 0.86)
    static let islandBackground = Color(red: 0.96, green: 0.97, blue: 0.95)
    static let islandBorder = Color(red: 0.78, green: 0.82, blue: 0.78)
    static let islandProgressTrack = Color(red: 0.82, green: 0.89, blue: 0.82)
}
