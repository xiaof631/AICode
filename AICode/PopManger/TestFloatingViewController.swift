// MARK: - Test Floating View Controller
import UIKit

class TestFloatingViewController: UIViewController {

    private let label = UILabel()
    var message: String = "Hello, Floating View!"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true

        label.text = message
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            // 给视图一个基本的大小约束
            view.widthAnchor.constraint(equalToConstant: 250),
            view.heightAnchor.constraint(equalToConstant: 150)
        ])

        // 添加一个关闭按钮（可选）
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close Me", for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
        ])
    }

    @objc private func closeButtonTapped() {
        // 通过 Manager 关闭
        FloatingViewControllerManager.shared.dismissCurrent()
    }
}

// MARK: - Example Usage in another ViewController (e.g., your main ViewController)
class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTestButtons()
    }

    func setupTestButtons() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let animations: [(String, PresentationAnimationType)] = [
            ("Center Scale", .centerScale),
            ("From Top", .fromTop),
            ("From Bottom", .fromBottom),
            ("From Left", .fromLeft),
            ("From Right", .fromRight),
            ("Top Left", .fromTopLeft),
            ("Top Right", .fromTopRight),
            ("Custom Frame", .customFrame(CGRect(x: 50, y: 100, width: 200, height: 100)))
        ]

        for (title, animationType) in animations {
            let button = UIButton(type: .system)
            button.setTitle("Show (\(title))", for: .normal)
            button.addAction(UIAction { [weak self] _ in
                self?.showFloatingView(animationType: animationType)
            }, for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        // 添加一个按钮测试队列
        let queueButton = UIButton(type: .system)
        queueButton.setTitle("Test Queue (Bottom -> Center)", for: .normal) // 修改标题
        queueButton.addAction(UIAction { [weak self] _ in
            self?.testQueue()
        }, for: .touchUpInside)
        stackView.addArrangedSubview(queueButton)

        // *** 新增：添加一个按钮测试高优先级 ***
        let priorityButton = UIButton(type: .system)
        priorityButton.setTitle("Test High Priority", for: .normal)
        priorityButton.addAction(UIAction { [weak self] _ in
            self?.testPriority()
        }, for: .touchUpInside)
        stackView.addArrangedSubview(priorityButton)

        // *** 新增：添加一个按钮关闭所有 ***
        let dismissAllButton = UIButton(type: .system)
        dismissAllButton.setTitle("Dismiss All", for: .normal)
        dismissAllButton.addAction(UIAction { _ in
            FloatingViewControllerManager.shared.dismissAll()
        }, for: .touchUpInside)
        stackView.addArrangedSubview(dismissAllButton)
    }

    // Helper function to create a sample view
    func createSampleView(message: String) -> UIView {
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = .systemGray6
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false // 重要！

        // 添加内边距
        let containerView = UIView()
        containerView.addSubview(label)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15),
            // 给 ContainerView 一个最小尺寸，防止 label 内容过少时太小
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        containerView.backgroundColor = label.backgroundColor // 保持背景一致
        containerView.layer.cornerRadius = label.layer.cornerRadius
        containerView.layer.masksToBounds = true

        return containerView
    }


    func showFloatingView(animationType: PresentationAnimationType) {
        // 修改：创建 UIView 而不是 TestFloatingViewController
        let testView = createSampleView(message: "Animation: \(animationType)")

        let request = PresentationRequest(
            contentView: testView, // 修改：使用 contentView
            animationType: animationType,
            dismissOnTap: true, // 点击背景关闭
            onDismiss: {
                print("Floating view dismissed! Animation: \(animationType)")
            }
        )
        FloatingViewControllerManager.shared.present(request)
    }

    func testQueue() {
         // 修改：创建 UIView
         let testView1 = createSampleView(message: "First in Queue (Bottom)")
         let request1 = PresentationRequest(
             contentView: testView1, // 修改
             animationType: .fromBottom,
             dismissalDuration: 1.0, // 慢点消失，看效果
             onDismiss: { print("First view dismissed") }
         )

         // 修改：创建 UIView
         let testView2 = createSampleView(message: "Second in Queue (Center)")
         let request2 = PresentationRequest(
             contentView: testView2, // 修改
             animationType: .centerScale,
             onDismiss: { print("Second view dismissed") }
         )

         FloatingViewControllerManager.shared.present(request1)
         FloatingViewControllerManager.shared.present(request2) // 立即调用第二个，它会进入队列
     }

    // *** 新增：测试高优先级的方法 ***
    func testPriority() {
        // 1. 显示一个普通的视图 (From Left)
        let normalView = createSampleView(message: "Normal Priority (From Left)\nWill be hidden")
        let normalRequest = PresentationRequest(
            contentView: normalView,
            animationType: .fromLeft,
            priority: .normal, // 显式设为 normal
            onDismiss: { print("Normal view dismissed (was hidden)") }
        )
        FloatingViewControllerManager.shared.present(normalRequest)

        // 2. 延迟一小段时间后，显示一个高优先级的视图 (Center Scale)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let highPriorityView = self.createSampleView(message: "High Priority! (Center Scale)\nHiding the other one.")
            let highPriorityRequest = PresentationRequest(
                contentView: highPriorityView,
                animationType: .centerScale,
                priority: .high, // 设为 high
                onDismiss: { print("High priority view dismissed") }
            )
            FloatingViewControllerManager.shared.present(highPriorityRequest)
            print("Presented High Priority Request")
        }
    }
}
