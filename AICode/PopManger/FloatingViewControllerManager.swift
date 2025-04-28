/*
 设计一个浮动视图弹出控制类，具体要求如下:
 1、需要一个新的window，并可以设置windowLevel
 2、window的根视频需要是一个导航控制器，以实现多个控制器的push跳转
 3、视图可以实现自定义并传入
 4、需要控制遮罩层是否可以点击半闭当前视图
 5、需要控制视图弹出的方向及动,中心放大、由上到下、由下到到、左上角出、右上角出，从左到右、从右到左、指定frame
 6、可以设定弹出动画时长,需要有默认值
 7、可以设定关闭动画时长,需要有默认值
 8、视图关闭后需要有事件回调
 9、需要有一个控制对列，同一时间不允许多个视图弹出,需要前一个弹窗关闭后才能弹出下一个。
 最后请输出一个测试用例
 */




import UIKit

class FloatingViewControllerManager {
    static let shared = FloatingViewControllerManager()

    private var windowQueue: [UIWindow] = [] // 存储窗口引用，方便管理
    private var requestQueue: [PresentationRequest] = []
    private var currentWindow: UIWindow?
    private var hiddenWindow: UIWindow? // 新增：用于存储被高优先级视图隐藏的窗口
    private var currentRequest: PresentationRequest? // 跟踪当前显示的请求

    private let defaultPresentationDuration: TimeInterval = 0.4
    private let defaultDismissalDuration: TimeInterval = 0.3

    private init() {}

    func present(_ request: PresentationRequest) {
        DispatchQueue.main.async { // 确保在主线程操作 UI
            // 如果是高优先级请求
            if request.priority == .high {
                // 如果当前有正在显示的窗口，则隐藏它
                if let windowToHide = self.currentWindow {
                    self.hiddenWindow = windowToHide
                    windowToHide.isHidden = true // 隐藏窗口
                    // 注意：当前请求 currentRequest 保持不变，因为它代表被隐藏的视图
                }
                // 无论是否有窗口被隐藏，都立即处理高优先级请求
                self.displayRequest(request)
            } else { // 普通优先级请求
                // 如果当前没有窗口显示，并且没有被隐藏的窗口，则立即显示
                if self.currentWindow == nil && self.hiddenWindow == nil {
                    self.displayRequest(request)
                } else {
                    // 否则，加入队列
                    self.requestQueue.append(request)
                }
            }
        }
    }

    private func displayRequest(_ request: PresentationRequest) {
        print("[Manager] Displaying request: \(request.priority), Animation: \(request.animationType)") // DEBUG
        let presentationDuration = request.presentationDuration ?? defaultPresentationDuration
        let dismissalDuration = request.dismissalDuration ?? defaultDismissalDuration

        // 创建容器 VC
        let containerVC = FloatingContainerViewController(
            contentView: request.contentView,
            animationType: request.animationType,
            dismissOnTap: request.dismissOnTap,
            presentationDuration: presentationDuration,
            dismissalDuration: dismissalDuration,
            dismissAction: { [weak self] in
                self?.dismissCompletionAction(for: request)
            }
        )
        print("[Manager] Container VC created: \(containerVC)") // DEBUG

        // *** 修改：尝试关联活动的 Window Scene ***
        var window: UIWindow?

        if #available(iOS 13.0, *) {
            // 查找活动的 window scene
            let activeScene = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .first

            if let windowScene = activeScene {
                print("[Manager] Found active window scene: \(windowScene)") // DEBUG
                window = UIWindow(windowScene: windowScene)
            } else {
                print("[Manager] Warning: Could not find active window scene. Falling back to frame init.") // DEBUG
                // Fallback for cases where scene is not found (e.g., background) or older iOS
                window = UIWindow(frame: UIScreen.main.bounds)
            }
        } else {
            // Fallback for iOS versions before 13
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        guard let newWindow = window else {
             print("[Manager] Error: Failed to create UIWindow.") // DEBUG
             // 可能需要处理错误，例如取消请求或放入队列重试
             return
         }

        newWindow.windowLevel = request.windowLevel
        newWindow.rootViewController = containerVC
        newWindow.backgroundColor = .clear
        print("[Manager] Window created: \(newWindow)") // DEBUG
        newWindow.makeKeyAndVisible() // 显示窗口
        print("[Manager] Window made key and visible.") // DEBUG

        self.currentWindow = newWindow
        self.currentRequest = request
        self.windowQueue.append(newWindow)
    }


    // 视图关闭后的完成动作
    private func dismissCompletionAction(for completedRequest: PresentationRequest) {
        // 查找并移除对应的窗口
        if let index = windowQueue.firstIndex(where: { $0.rootViewController === currentWindow?.rootViewController }) {
            windowQueue.remove(at: index)
        }

        // 调用外部传入的 onDismiss 回调
        completedRequest.onDismiss?()

        // 清理当前窗口引用
        self.currentWindow = nil
        self.currentRequest = nil

        // 检查是否有被隐藏的窗口需要恢复
        if let windowToShow = self.hiddenWindow {
            windowToShow.isHidden = false // 恢复显示
            self.currentWindow = windowToShow // 将其设为当前窗口
            // 找到 hiddenWindow 对应的 request (这里假设 hiddenWindow 就是之前的 currentWindow)
            // 这个逻辑需要更健壮，可能需要存储 hiddenRequest
            // 暂时简化：我们不存储 hiddenRequest，因为恢复时不需要知道它的细节
            self.hiddenWindow = nil // 清空隐藏窗口引用
        } else {
            // 如果没有隐藏的窗口，则处理队列中的下一个请求
            processQueue()
        }
    }

    // 处理队列（现在只在没有隐藏窗口恢复时调用）
    private func processQueue() {
        guard currentWindow == nil, hiddenWindow == nil, !requestQueue.isEmpty else {
            return // 只有在完全空闲时才处理队列
        }
        let nextRequest = requestQueue.removeFirst()
        displayRequest(nextRequest)
    }

    // 外部调用的关闭当前视图的方法
    func dismissCurrent() {
        guard let window = currentWindow,
              let containerVC = window.rootViewController as? FloatingContainerViewController else {
            // 如果没有当前窗口或类型不对，尝试处理队列（以防万一）
            processQueue()
            return
        }
        // 调用容器 VC 的关闭动画方法，它会在动画结束后调用 dismissCompletionAction
        containerVC.dismissView()
    }

    // 关闭所有视图（包括队列中的）
    func dismissAll() {
        DispatchQueue.main.async {
            self.requestQueue.removeAll() // 清空请求队列

            // 如果有隐藏的窗口，先处理它（通常是直接移除）
            if let hiddenWin = self.hiddenWindow {
                 // 找到 hiddenWin 对应的 request (如果需要调用 onDismiss)
                 // 简单处理：直接移除窗口
                 hiddenWin.isHidden = true // 确保它不可见
                 if let index = self.windowQueue.firstIndex(of: hiddenWin) {
                     self.windowQueue.remove(at: index)
                 }
                 self.hiddenWindow = nil
            }


            // 关闭当前正在显示的窗口（如果有）
            if let currentWin = self.currentWindow,
               let containerVC = currentWin.rootViewController as? FloatingContainerViewController {
                // 直接调用完成动作，跳过动画，并清理
                self.dismissCompletionAction(for: self.currentRequest!) // 强制解包，因为 currentWindow 存在时 currentRequest 必存在
            } else {
                 // 如果没有当前窗口，但可能有残留的 windowQueue 引用
                 self.windowQueue.forEach { $0.isHidden = true }
                 self.windowQueue.removeAll()
            }
            self.currentWindow = nil
            self.currentRequest = nil
        }
    }
}
