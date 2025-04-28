import UIKit

// MARK: - Presentation Priority (新增)
enum PresentationPriority {
    case normal
    case high
}

// MARK: - Presentation Animation Type
enum PresentationAnimationType {
    case centerScale        // 中心放大
    case fromTop            // 从上到下
    case fromBottom         // 从下到上
    case fromTopLeft        // 从左上角
    case fromTopRight       // 从右上角
    case fromLeft           // 从左到右
    case fromRight          // 从右到左
    case customFrame(CGRect) // 指定 Frame (注意：frame 是相对于屏幕的)
}

// MARK: - Presentation Request
struct PresentationRequest {
    let contentView: UIView
    let animationType: PresentationAnimationType
    let priority: PresentationPriority // 新增：优先级
    let windowLevel: UIWindow.Level
    let dismissOnTap: Bool
    let presentationDuration: TimeInterval?
    let dismissalDuration: TimeInterval?
    let onDismiss: (() -> Void)?

    init(contentView: UIView,
         animationType: PresentationAnimationType = .centerScale,
         priority: PresentationPriority = .normal, // 新增：默认普通优先级
         windowLevel: UIWindow.Level = .normal + 1,
         dismissOnTap: Bool = true,
         presentationDuration: TimeInterval? = nil,
         dismissalDuration: TimeInterval? = nil,
         onDismiss: (() -> Void)? = nil) {
        self.contentView = contentView
        self.animationType = animationType
        self.priority = priority // 新增
        self.windowLevel = windowLevel
        self.dismissOnTap = dismissOnTap
        self.presentationDuration = presentationDuration
        self.dismissalDuration = dismissalDuration
        self.onDismiss = onDismiss
    }
}