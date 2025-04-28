import SwiftUI
import UIKit // 需要 UIKit 来创建 UIView

struct FloatingViewTestView: View {

    var body: some View {
        ScrollView { // 使用 ScrollView 防止按钮过多超出屏幕
            VStack(spacing: 15) {
                Text("Floating View Tests (SwiftUI)")
                    .font(.headline)
                    .padding(.bottom)

                // 动画测试按钮
                ForEach(animationTypes, id: \.0) { name, type in
                    Button("Show (\(name))") {
                        showFloatingView(animationType: type)
                    }
                }

                // 队列测试按钮
                Button("Test Queue (Bottom -> Center)") {
                    testQueue()
                }

                // *** 新增：高优先级测试按钮 ***
                Button("Test High Priority") {
                    testPriority()
                }

                // *** 新增：关闭所有按钮 ***
                Button("Dismiss All") {
                    FloatingViewControllerManager.shared.dismissAll()
                }
                .foregroundColor(.red) // 突出显示
            }
            .padding()
        }
    }

    // 定义动画类型供按钮使用
    private let animationTypes: [(String, PresentationAnimationType)] = [
        ("Center Scale", .centerScale),
        ("From Top", .fromTop),
        ("From Bottom", .fromBottom),
        ("From Left", .fromLeft),
        ("From Right", .fromRight),
        ("Top Left", .fromTopLeft),
        ("Top Right", .fromTopRight),
        ("Custom Frame (Top Left Area)", .customFrame(CGRect(x: 50, y: 100, width: 250, height: 150))), // 修改了尺寸和描述
        // --- 新增测试类型 ---
        ("Center Scale (No Tap Dismiss)", .centerScale), // 用于测试 dismissOnTap = false
        ("From Bottom (Slow)", .fromBottom), // 用于测试自定义时长
        ("Custom Frame (Bottom Right Area)", .customFrame(CGRect(x: UIScreen.main.bounds.width - 220, y: UIScreen.main.bounds.height - 170, width: 200, height: 150))) // 新增右下角区域
    ]

    // Helper function (可以和 MainViewController 中的共享，或者在这里重新定义)
    func createSampleView(message: String) -> UIView {
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = .systemGray6
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false

        let containerView = UIView()
        containerView.addSubview(label)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 300.0),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 600.0)
        ])
        containerView.backgroundColor = label.backgroundColor
        containerView.layer.cornerRadius = label.layer.cornerRadius
        containerView.layer.masksToBounds = true

        return containerView
    }

    // 显示浮动视图的方法
    private func showFloatingView(animationType: PresentationAnimationType, name: String = "") { // 新增 name 参数
        // 修改：创建 UIView
        let testView = createSampleView(message: "SwiftUI Triggered\nAnimation: \(name)") // 使用 name

        // 根据名称判断是否需要特殊处理
        var dismissOnTap = true
        var presentationDuration: TimeInterval? = nil // 使用默认值

        if name.contains("No Tap Dismiss") {
            dismissOnTap = false
        }
        if name.contains("Slow") {
            presentationDuration = 2.0 // 设置较长的呈现时间
        }

        let request = PresentationRequest(
            contentView: testView, // 修改
            animationType: animationType,
            dismissOnTap: dismissOnTap, presentationDuration: presentationDuration, // 传递 dismissOnTap 设置
            onDismiss: {
                print("Floating view dismissed! Animation: \(name)") // 使用 name
            }
        )
        FloatingViewControllerManager.shared.present(request)
    }

    // 测试队列的方法
    private func testQueue() {
        // 修改：创建 UIView 1
        let testView1 = createSampleView(message: "SwiftUI Triggered\n1st in Queue (From Bottom)")
        let request1 = PresentationRequest(
            contentView: testView1, // 修改
            animationType: .fromBottom,
            dismissalDuration: 1.0, // 稍快消失
            onDismiss: { print("SwiftUI: 1st view dismissed") }
        )

        // 修改：创建 UIView 2
        let testView2 = createSampleView(message: "SwiftUI Triggered\n2nd in Queue (Center Scale)")
        let request2 = PresentationRequest(
            contentView: testView2, // 修改
            animationType: .centerScale,
            dismissalDuration: 1.5, // 正常速度消失
            onDismiss: { print("SwiftUI: 2nd view dismissed") }
        )

        // --- 新增视图 ---
        // 创建 UIView 3
        let testView3 = createSampleView(message: "SwiftUI Triggered\n3rd in Queue (From Left)")
        let request3 = PresentationRequest(
            contentView: testView3,
            animationType: .fromLeft,
            dismissalDuration: 2.0, // 稍慢消失
            onDismiss: { print("SwiftUI: 3rd view dismissed") }
        )

        // 创建 UIView 4
        let testView4 = createSampleView(message: "SwiftUI Triggered\n4th in Queue (Custom Frame - Top Left)")
        let request4 = PresentationRequest(
            contentView: testView4,
            animationType: .customFrame(CGRect(x: 30, y: 80, width: 280, height: 180)), // 使用一个自定义 Frame
            dismissalDuration: 1.0,
            onDismiss: { print("SwiftUI: 4th view dismissed") }
        )

        // 创建 UIView 5
        let testView5 = createSampleView(message: "SwiftUI Triggered\n5th in Queue (From Top Right)")
        let request5 = PresentationRequest(
            contentView: testView5,
            animationType: .fromTopRight,
            onDismiss: { print("SwiftUI: 5th view dismissed") }
        )
        // --- 结束新增 ---


        // 按顺序呈现所有请求
        FloatingViewControllerManager.shared.present(request1)
        FloatingViewControllerManager.shared.present(request2)
        FloatingViewControllerManager.shared.present(request3) // 新增
        FloatingViewControllerManager.shared.present(request4) // 新增
        FloatingViewControllerManager.shared.present(request5) // 新增

        print("SwiftUI: Presented 5 requests to the queue.")
    }

    // *** 新增：测试高优先级的方法 ***
    private func testPriority() {
        // 1. 显示第一个普通的视图 (From Left)
        let normalView1 = createSampleView(message: "SwiftUI Triggered\nNormal Priority 1 (From Left)\nWill be hidden soon")
        let normalRequest1 = PresentationRequest(
            contentView: normalView1,
            animationType: .fromLeft,
            priority: .normal, // 显式设为 normal
            onDismiss: { print("SwiftUI: Normal view 1 dismissed (was hidden)") }
        )
        FloatingViewControllerManager.shared.present(normalRequest1)
        print("SwiftUI: Presented Normal Priority Request 1")

        // 2. 延迟一小段时间后，显示第二个普通的视图 (From Right) - 它应该排在第一个后面
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            let normalView2 = self.createSampleView(message: "SwiftUI Triggered\nNormal Priority 2 (From Right)\nWill also be hidden")
            let normalRequest2 = PresentationRequest(
                contentView: normalView2,
                animationType: .fromRight,
                priority: .normal,
                onDismiss: { print("SwiftUI: Normal view 2 dismissed (was hidden)") }
            )
            FloatingViewControllerManager.shared.present(normalRequest2)
            print("SwiftUI: Presented Normal Priority Request 2")
        }

        // 3. 再延迟一小段时间后，显示第一个高优先级的视图 (Center Scale) - 它应该隐藏前两个普通视图
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { // 增加延迟以确保普通视图都已加入
            let highPriorityView1 = self.createSampleView(message: "SwiftUI Triggered\nHigh Priority 1! (Center Scale)\nHiding the normal ones.")
            let highPriorityRequest1 = PresentationRequest(
                contentView: highPriorityView1,
                animationType: .centerScale,
                priority: .high, // 设为 high
                onDismiss: { print("SwiftUI: High priority view 1 dismissed (was replaced or dismissed all)") }
            )
            FloatingViewControllerManager.shared.present(highPriorityRequest1)
            print("SwiftUI: Presented High Priority Request 1")
        }

        // 4. 再延迟，显示第二个高优先级的视图 (From Top) - 它应该替换掉第一个高优先级视图
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let highPriorityView2 = self.createSampleView(message: "SwiftUI Triggered\nHigh Priority 2! (From Top)\nReplacing the previous high priority.")
            let highPriorityRequest2 = PresentationRequest(
                contentView: highPriorityView2,
                animationType: .fromTop,
                priority: .high, // 同样是 high
                onDismiss: { print("SwiftUI: High priority view 2 dismissed") }
            )
            FloatingViewControllerManager.shared.present(highPriorityRequest2)
            print("SwiftUI: Presented High Priority Request 2")
        }
    }
}

// SwiftUI 预览 (可选)
struct FloatingViewTestView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingViewTestView()
    }
}
