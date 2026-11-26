import SwiftUI

/// 唱机配色：不同主题只换材质与灯光，布局完全一致。
struct DeckTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let plinthTop: Color
    let plinthBottom: Color
    let platter: Color
    let accent: Color
    let ink: Color
    let hardware: Color
    let labelWarm: Color
    let prefersLight: Bool

    static let walnut = DeckTheme(
        id: "walnut",
        name: "胡桃木",
        plinthTop: Color(red: 0.32, green: 0.20, blue: 0.13),
        plinthBottom: Color(red: 0.16, green: 0.10, blue: 0.07),
        platter: Color(red: 0.10, green: 0.10, blue: 0.11),
        accent: Color(red: 0.86, green: 0.72, blue: 0.47),
        ink: Color(red: 0.97, green: 0.94, blue: 0.88),
        hardware: Color(red: 0.78, green: 0.76, blue: 0.72),
        labelWarm: Color(red: 0.90, green: 0.85, blue: 0.72),
        prefersLight: false
    )

    static let noir = DeckTheme(
        id: "noir",
        name: "午夜黑",
        plinthTop: Color(red: 0.13, green: 0.13, blue: 0.15),
        plinthBottom: Color(red: 0.05, green: 0.05, blue: 0.06),
        platter: Color(red: 0.08, green: 0.08, blue: 0.09),
        accent: Color(red: 0.55, green: 0.72, blue: 0.95),
        ink: Color(white: 0.95),
        hardware: Color(white: 0.62),
        labelWarm: Color(red: 0.72, green: 0.80, blue: 0.94),
        prefersLight: false
    )

    static let cream = DeckTheme(
        id: "cream",
        name: "奶油白",
        plinthTop: Color(red: 0.96, green: 0.93, blue: 0.87),
        plinthBottom: Color(red: 0.86, green: 0.82, blue: 0.75),
        platter: Color(red: 0.88, green: 0.86, blue: 0.82),
        accent: Color(red: 0.55, green: 0.36, blue: 0.22),
        ink: Color(red: 0.20, green: 0.17, blue: 0.14),
        hardware: Color(red: 0.55, green: 0.53, blue: 0.50),
        labelWarm: Color(red: 0.35, green: 0.28, blue: 0.22),
        prefersLight: true
    )

    static let midnight = DeckTheme(
        id: "midnight",
        name: "深海蓝",
        plinthTop: Color(red: 0.09, green: 0.16, blue: 0.28),
        plinthBottom: Color(red: 0.04, green: 0.07, blue: 0.13),
        platter: Color(red: 0.07, green: 0.10, blue: 0.16),
        accent: Color(red: 0.49, green: 0.85, blue: 0.83),
        ink: Color(red: 0.93, green: 0.96, blue: 0.98),
        hardware: Color(red: 0.70, green: 0.76, blue: 0.82),
        labelWarm: Color(red: 0.80, green: 0.90, blue: 0.92),
        prefersLight: false
    )

    static let all: [DeckTheme] = [walnut, noir, cream, midnight]

    static func named(_ id: String) -> DeckTheme {
        all.first { $0.id == id } ?? walnut
    }
}
