// MARK: - Floating Container View Controller
import UIKit

class FloatingContainerViewController: UIViewController {
    private let contentView: UIView // 修改：类型和变量名
    private let animationType: PresentationAnimationType
    private let dismissOnTap: Bool
    private let presentationDuration: TimeInterval
    private let dismissalDuration: TimeInterval
    private let dismissAction: () -> Void

    private let backgroundMaskView = UIView()
    private var contentOriginalFrame: CGRect = .zero
    private var screenSize: CGSize = UIScreen.main.bounds.size // 移到这里方便访问

    init(contentView: UIView, // 修改：参数类型和名称
         animationType: PresentationAnimationType,
         dismissOnTap: Bool,
         presentationDuration: TimeInterval,
         dismissalDuration: TimeInterval,
         dismissAction: @escaping () -> Void) {
        self.contentView = contentView // 修改：存储 contentView
        self.animationType = animationType
        self.dismissOnTap = dismissOnTap
        self.presentationDuration = presentationDuration
        self.dismissalDuration = dismissalDuration
        self.dismissAction = dismissAction
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[ContainerVC] viewDidLoad") // DEBUG
        setupViews()
        setupGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[ContainerVC] viewWillAppear") // DEBUG
        view.layoutIfNeeded() // Ensure constraints applied before prepare
        print("[ContainerVC] viewWillAppear - layoutIfNeeded done") // DEBUG
        prepareForAnimation()
        print("[ContainerVC] viewWillAppear - prepareForAnimation done") // DEBUG
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[ContainerVC] viewDidAppear - Starting animation") // DEBUG
        performPresentAnimation()
    }

    private func setupViews() {
        print("[ContainerVC] setupViews - Start") // DEBUG
        // Background Mask
        backgroundMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.4) // 半透明黑色遮罩
        backgroundMaskView.translatesAutoresizingMaskIntoConstraints = false
        backgroundMaskView.alpha = 0 // 初始透明
        view.addSubview(backgroundMaskView)

        // Content View
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false // 确保 contentView 使用 Auto Layout

        // Layout Mask
        NSLayoutConstraint.activate([
            backgroundMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 移除这行错误的代码 -> contentView.frame.origin = frame.origin

        // 约束：根据 animationType 决定约束
        var constraints: [NSLayoutConstraint] = [] // 初始化为空数组

        // 根据动画类型添加特定的约束
        switch animationType {
        case .customFrame(let frame):
             // 修改：为 customFrame 添加绝对定位约束
             // 移除之前可能存在的通用约束，直接使用 frame 定义
             constraints.append(contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: frame.origin.y))
             constraints.append(contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: frame.origin.x))
             constraints.append(contentView.widthAnchor.constraint(equalToConstant: frame.width))
             constraints.append(contentView.heightAnchor.constraint(equalToConstant: frame.height))
             // 注意：这里不再添加 lessThanOrEqualTo/greaterThanOrEqualTo 约束，因为 frame 是确定的
        default: // 处理其他所有非 customFrame 的情况
             constraints = [
                 // 添加通用的 lessThanOrEqualTo/greaterThanOrEqualTo 约束
                 contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                 contentView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                 contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                 contentView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
             ]
             // 为非 customFrame 类型添加特定的对齐约束
             switch animationType {
                 case .centerScale:
                     constraints.append(contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
                     constraints.append(contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
                 case .fromTop:
                     constraints.append(contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                     constraints.append(contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
                 case .fromBottom:
                     constraints.append(contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
                     constraints.append(contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
                 case .fromLeft:
                     constraints.append(contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                     constraints.append(contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
                 case .fromRight:
                     constraints.append(contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                     constraints.append(contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
                 case .fromTopLeft:
                     constraints.append(contentView.topAnchor.constraint(equalTo: view.topAnchor))
                     constraints.append(contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                 case .fromTopRight:
                     constraints.append(contentView.topAnchor.constraint(equalTo: view.topAnchor))
                     constraints.append(contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                 default: // .customFrame 已在上面处理
                     break
             }
        }


        NSLayoutConstraint.activate(constraints)
        print("[ContainerVC] setupViews - End") // DEBUG
    }

    private func setupGesture() {
        if dismissOnTap {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
            backgroundMaskView.addGestureRecognizer(tapGesture)
            // 如果 contentViewController.view 覆盖了 backgroundMaskView，可能需要让事件穿透
            // 或者将手势加在 self.view 上，并判断点击位置
        }
    }

    @objc private func handleBackgroundTap() {
        dismissView()
    }

    // MARK: - Animation Logic

    private func prepareForAnimation() {
        // 对于非 customFrame 类型，先让约束生效
        if case .customFrame = animationType {
             // customFrame 不需要初始 layoutIfNeeded，因为它会直接设置 frame
        } else {
            view.layoutIfNeeded()
        }
        contentView.alpha = 0

        switch animationType {
        case .centerScale:
            // 恢复：仅设置缩放 transform，中心位置由约束保证
            contentView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            print("[ContainerVC] prepareForAnimation - .centerScale transform: \(contentView.transform)") // DEBUG
        case .fromTop:
             // 保持：计算向上平移的 transform
             contentView.layoutIfNeeded()
             let ty_new = -(view.safeAreaInsets.top + contentView.bounds.height)
             contentView.transform = CGAffineTransform(translationX: 0, y: ty_new)
             print("[ContainerVC] prepareForAnimation - .fromTop transform: \(contentView.transform)") // DEBUG
        case .fromBottom:
             // 修改：计算向下平移的 transform，使其从底部外部开始
             contentView.layoutIfNeeded() // Ensure contentView size is calculated
             // 最终位置由 bottomAnchor 约束决定
             // 初始位置需要基于这个最终位置向下平移整个视图的高度
             let ty = contentView.bounds.height // 向下平移自身高度
             contentView.transform = CGAffineTransform(translationX: 0, y: ty)
             print("[ContainerVC] prepareForAnimation - .fromBottom transform: \(contentView.transform)") // DEBUG
        case .fromLeft:
             // 修改：计算向左平移的 transform，使其从左侧外部开始
             contentView.layoutIfNeeded() // Ensure contentView size is calculated
             // 最终位置由 leadingAnchor 约束决定
             // 初始位置需要基于这个最终位置向左平移整个视图的宽度
             let tx = -contentView.bounds.width // 向左平移自身宽度
             contentView.transform = CGAffineTransform(translationX: tx, y: 0)
             print("[ContainerVC] prepareForAnimation - .fromLeft transform: \(contentView.transform)") // DEBUG
        case .fromRight:
             // 修改：计算向右平移的 transform，使其从右侧外部开始
             contentView.layoutIfNeeded() // Ensure contentView size is calculated
             // 最终位置由 trailingAnchor 约束决定
             // 初始位置需要基于这个最终位置向右平移整个视图的宽度
             let tx = contentView.bounds.width // 向右平移自身宽度
             contentView.transform = CGAffineTransform(translationX: tx, y: 0)
             print("[ContainerVC] prepareForAnimation - .fromRight transform: \(contentView.transform)") // DEBUG
        case .fromTopLeft:
             // 修改：计算向左上平移的 transform，使其从左上角外部开始
             contentView.layoutIfNeeded() // Ensure contentView size is calculated
             // 最终位置由 topAnchor 和 leadingAnchor 约束决定
             // 初始位置需要基于这个最终位置向左平移整个视图的宽度，向上平移整个视图的高度
             let tx = -contentView.bounds.width // 向左平移自身宽度
             let ty = -contentView.bounds.height // 向上平移自身高度
             contentView.transform = CGAffineTransform(translationX: tx, y: ty)
             print("[ContainerVC] prepareForAnimation - .fromTopLeft transform: \(contentView.transform)") // DEBUG
        case .fromTopRight:
             // 修改：计算向右上平移的 transform，使其从右上角外部开始
             contentView.layoutIfNeeded() // Ensure contentView size is calculated
             // 最终位置由 topAnchor 和 trailingAnchor 约束决定
             // 初始位置需要基于这个最终位置向右平移整个视图的宽度，向上平移整个视图的高度
             let tx = contentView.bounds.width // 向右平移自身宽度
             let ty = -contentView.bounds.height // 向上平移自身高度
             contentView.transform = CGAffineTransform(translationX: tx, y: ty)
             print("[ContainerVC] prepareForAnimation - .fromTopRight transform: \(contentView.transform)") // DEBUG
        case .customFrame: // 注意：不再需要解包 frame，因为约束已在 setupViews 中设置
            // 先让 Auto Layout 定位到最终frame
            view.layoutIfNeeded()
            // 记录原始frame和bounds
            let oldAnchor = contentView.layer.anchorPoint
            let oldFrame = contentView.frame
            let bounds = contentView.bounds

            // 设置锚点为左上角
            contentView.layer.anchorPoint = CGPoint(x: 0, y: 0)
            // 补偿origin
            let dx = (contentView.layer.anchorPoint.x - oldAnchor.x) * bounds.width
            let dy = (contentView.layer.anchorPoint.y - oldAnchor.y) * bounds.height
            contentView.frame.origin = CGPoint(x: oldFrame.origin.x + dx, y: oldFrame.origin.y + dy)

            // 初始缩放
            contentView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            print("[ContainerVC] prepareForAnimation - .customFrame anchorPoint: \(contentView.layer.anchorPoint), compensated frame: \(contentView.frame), transform: \(contentView.transform)") // DEBUG
        }
        print("[ContainerVC] prepareForAnimation - End, contentView frame: \(contentView.frame), transform: \(contentView.transform), alpha: \(contentView.alpha)") // DEBUG
    }

    private func performPresentAnimation() {
        print("[ContainerVC] performPresentAnimation - Start, contentView frame before animation: \(contentView.frame), transform: \(contentView.transform)") // DEBUG

        if case .customFrame(let frame) = animationType {
            // .customFrame: 动画 Frame 和 Transform
            UIView.animate(withDuration: presentationDuration, delay: 0,
                          usingSpringWithDamping: 0.8,
                          initialSpringVelocity: 0.5,
                          options: [.curveEaseOut], animations: {
                print("[ContainerVC] performPresentAnimation - Animation block start (.customFrame)")
                self.backgroundMaskView.alpha = 1.0
                self.contentView.alpha = 1.0
                self.contentView.transform = .identity // 动画 Transform
                self.contentView.frame = frame // 动画 Frame 到目标位置
                print("[ContainerVC] performPresentAnimation - Animation block end (.customFrame), target frame: \(frame)")
            }, completion: { completed in
                print("[ContainerVC] performPresentAnimation - Completion block START (.customFrame)")
                if completed {
                    // 注意：动画完成后 contentView 的 frame 就是最终 frame，约束不再需要（除非有后续交互需要约束）
                    print("[ContainerVC] performPresentAnimation - .customFrame animation completed. Final frame: \(self.contentView.frame)")
                }
                print("[ContainerVC] performPresentAnimation - Completion block END (.customFrame)")
            })
        } else {
            // 其他类型: 仅动画 Transform
            UIView.animate(withDuration: presentationDuration, delay: 0,
                          usingSpringWithDamping: 0.8,
                          initialSpringVelocity: 0.5,
                          options: [.curveEaseOut], animations: {
                print("[ContainerVC] performPresentAnimation - Animation block start (non-customFrame)")
                self.backgroundMaskView.alpha = 1.0
                self.contentView.alpha = 1.0
                self.contentView.transform = .identity // 恢复 Transform
                print("[ContainerVC] performPresentAnimation - Animation block end (non-customFrame)")
            }, completion: { completed in
                 print("[ContainerVC] performPresentAnimation - Completion block START (non-customFrame)")
                 // 不需要重置锚点，因为未使用锚点动画
                 print("[ContainerVC] performPresentAnimation - Completion block END (non-customFrame)")
            })
        }
    }

    func dismissView() {
         print("[ContainerVC] dismissView - Start") // DEBUG

        if case .customFrame(let frame) = animationType {
            // .customFrame: 动画 Frame 和 Transform 回到初始状态
            UIView.animate(withDuration: dismissalDuration, delay: 0,
                          options: [.curveEaseIn], animations: {
                print("[ContainerVC] dismissView - Animation block start (.customFrame)")
                self.backgroundMaskView.alpha = 0
                self.contentView.alpha = 0
                // 动画回 (0,0) 并缩小
                self.contentView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.contentView.frame = CGRect(origin: .zero, size: frame.size) // 动画回 (0,0)
                print("[ContainerVC] dismissView - Animation block end (.customFrame)")
            }) { _ in
                print("[ContainerVC] dismissView - Animation completed (.customFrame), calling dismissAction")
                self.dismissAction()
                self.dismiss(animated: false, completion: nil)
            }
        } else {
            // 其他类型: 计算并动画 Transform
            var finalTransform: CGAffineTransform = .identity
            var finalAlpha: CGFloat = 0.0

            // 需要布局来计算移出屏幕的 Transform
            view.layoutIfNeeded()

            switch self.animationType {
            case .centerScale:
                finalTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            case .fromTop:
                let ty_new = -(view.safeAreaInsets.top + contentView.bounds.height)
                finalTransform = CGAffineTransform(translationX: 0, y: ty_new)
            case .fromBottom:
                let ty = contentView.bounds.height // 向下平移自身高度
                finalTransform = CGAffineTransform(translationX: 0, y: ty)
            case .fromLeft:
                let tx = -contentView.bounds.width // 向左平移自身宽度
                finalTransform = CGAffineTransform(translationX: tx, y: 0)
            case .fromRight:
                let tx = contentView.bounds.width // 向右平移自身宽度
                finalTransform = CGAffineTransform(translationX: tx, y: 0)
            case .fromTopLeft:
                let tx = -contentView.bounds.width // 向左平移自身宽度
                let ty = -contentView.bounds.height // 向上平移自身高度
                finalTransform = CGAffineTransform(translationX: tx, y: ty)
            case .fromTopRight:
                let tx = contentView.bounds.width // 向右平移自身宽度
                let ty = -contentView.bounds.height // 向上平移自身高度
                finalTransform = CGAffineTransform(translationX: tx, y: ty)
            case .customFrame: // 正确获取 frame
                // 先让 Auto Layout 定位到最终frame
                view.layoutIfNeeded()
                let oldAnchor = contentView.layer.anchorPoint
                let oldFrame = contentView.frame
                let bounds = contentView.bounds

                // 设置锚点为左上角
                contentView.layer.anchorPoint = CGPoint(x: 0, y: 0)
                // 补偿origin
                let dx = (contentView.layer.anchorPoint.x - oldAnchor.x) * bounds.width
                let dy = (contentView.layer.anchorPoint.y - oldAnchor.y) * bounds.height
                contentView.frame.origin = CGPoint(x: oldFrame.origin.x + dx, y: oldFrame.origin.y + dy)

                finalTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                finalAlpha = 0.0 // 确保消失时透明度为0
                print("[ContainerVC] dismissView - .customFrame prepare anchorPoint: \(contentView.layer.anchorPoint), compensated frame: \(contentView.frame)") // DEBUG
            }


            UIView.animate(withDuration: dismissalDuration, delay: 0,
                          options: [.curveEaseIn], animations: {
                print("[ContainerVC] dismissView - Animation block start (non-customFrame)")
                self.backgroundMaskView.alpha = 0
                self.contentView.alpha = finalAlpha
                self.contentView.transform = finalTransform
                print("[ContainerVC] dismissView - Animation block end (non-customFrame)")
            }) { _ in
                print("[ContainerVC] dismissView - Animation completed (non-customFrame), calling dismissAction")
                self.dismissAction()
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
}
