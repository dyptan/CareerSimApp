import CoreGraphics

enum GameConstants {
    static let maxSoftActivitiesPerYear: Int = 3
    static let trainingActivitySlotCost: Int = 1
    static let previewWindowWidth: CGFloat = 1000
    static let previewWindowHeight: CGFloat = 700

    /// Savings target that wins the game in realistic mode ("first million").
    static let millionGoal: Int = 1_000_000
}
