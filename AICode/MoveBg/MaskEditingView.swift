import SwiftUI
import PencilKit // 用于绘图

struct MaskEditingView: View {
    let originalImage: UIImage
    @State var currentMask: UIImage // 当前编辑的蒙版
    let onComplete: (UIImage) -> Void // 完成回调

    @State private var canvasView = PKCanvasView()
    @State private var tool: PKInkingTool.InkType = .marker // 默认涂抹工具
    @State private var color: UIColor = .red // 蒙版颜色 (通常固定)
    @State private var brushSize: CGFloat = 20.0
    @State private var isErasing: Bool = false // 是否是擦除模式
    @State private var showPreview: Bool = false // 控制预览状态

    // 用于撤销/重做
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        NavigationView { // 使用 NavigationView 添加标题和按钮
            VStack(spacing: 0) {
                ZStack {
                    // 底层显示原始图片
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()

                    // 中间层显示可交互的绘图区域 (PKCanvasView)
                    CanvasViewWrapper(canvasView: $canvasView,
                                      tool: $tool,
                                      color: $color,
                                      brushSize: $brushSize,
                                      isErasing: $isErasing,
                                      initialDrawing: currentMask) // 传入初始蒙版
                        .opacity(showPreview ? 0 : 0.6) // 编辑时半透明显示蒙版，预览时隐藏

                    // (可选) 顶层显示预览效果
                    if showPreview, let previewImage = generatePreviewImage() {
                         Image(uiImage: previewImage)
                             .resizable()
                             .scaledToFit()
                     }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onChanged { _ in showPreview = true }
                        .onEnded { _ in showPreview = false }
                ) // 长按预览

                Divider()

                // --- 控制面板 ---
                VStack {
                    HStack {
                        Button("涂抹") { isErasing = false }
                            .padding()
                            .background(isErasing ? Color.gray.opacity(0.2) : Color.blue.opacity(0.3))
                            .cornerRadius(8)

                        Button("擦除") { isErasing = true }
                            .padding()
                            .background(isErasing ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        Spacer()

                        // 撤销/重做按钮
                        Button { undoManager?.undo() } label: { Image(systemName: "arrow.uturn.backward") }.disabled(!(undoManager?.canUndo ?? false))
                        Button { undoManager?.redo() } label: { Image(systemName: "arrow.uturn.forward") }.disabled(!(undoManager?.canRedo ?? false))

                        Spacer()
                         Button("按住预览") {
                             // 通过 LongPressGesture 实现
                         }
                         .padding()
                         .foregroundColor(.gray)


                    }
                    .padding(.horizontal)

                    HStack {
                        Text("画笔大小:")
                        Slider(value: $brushSize, in: 5...50) // 调整画笔大小范围
                        Text("\(Int(brushSize))")
                    }
                    .padding(.horizontal)

                }
                .padding(.vertical)
                .background(Color(UIColor.systemBackground)) // 背景色适应深色/浅色模式
            }
            .navigationTitle("涂抹编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        // 关闭视图，不保存更改
                        // 需要获取 presentationMode 来 dismiss
                        // @Environment(\.presentationMode) var presentationMode
                        // presentationMode.wrappedValue.dismiss()
                        // 或者如果使用 NavigationStack，需要不同的方式 dismiss
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // 从 CanvasView 获取最终的蒙版图像
                        let finalMask = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                        onComplete(finalMask)
                        // 关闭视图
                        // presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    // 生成预览图 (需要具体实现)
    func generatePreviewImage() -> UIImage? {
        let currentDrawingMask = canvasView.drawing.image(from: canvasView.bounds, scale: originalImage.scale)
        // TODO: 实现根据 currentDrawingMask 应用到 originalImage 上的逻辑
        print("TODO: Implement preview generation based on current drawing")
        // 占位符：简单返回原图
        return applyMaskToImage(image: originalImage, mask: currentDrawingMask)
    }

     // --- Helper Function (需要具体实现) ---
     func applyMaskToImage(image: UIImage, mask: UIImage?) -> UIImage? {
         // TODO: 根据蒙版处理原图，例如移除背景
         print("TODO: Implement mask application logic for preview")
         // 返回处理后的图像，这里简单返回原图作为占位符
         return image
     }
}

// --- PKCanvasView 的 SwiftUI 封装 ---
struct CanvasViewWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var tool: PKInkingTool.InkType
    @Binding var color: UIColor
    @Binding var brushSize: CGFloat
    @Binding var isErasing: Bool
    var initialDrawing: UIImage? // 接收初始蒙版

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear // 设置背景透明
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator

        // 加载初始蒙版
        if let img = initialDrawing, let drawing = try? PKDrawing(data: img.pngData()!) { // 尝试从 UIImage 加载
             canvasView.drawing = drawing
        } else if let img = initialDrawing {
            // 如果无法直接加载为 PKDrawing，可以尝试将 UIImage 绘制到 Canvas 上下文
            // 这比较复杂，通常需要确保 initialDrawing 是以兼容 PKDrawing 的方式保存的
            print("Warning: Could not load initial drawing directly. Initial mask might not appear.")
            // 尝试将 UIImage 绘制为背景或初始层（如果 PencilKit 版本支持）
             let imageView = UIImageView(image: img)
             imageView.frame = canvasView.bounds
             imageView.contentMode = .scaleAspectFit // 或 .topLeft 等，取决于蒙版坐标系
             imageView.alpha = 0.6 // 使其可见但可区分
             canvasView.addSubview(imageView)
             canvasView.sendSubviewToBack(imageView) // 确保在绘图层下方
        }


        updateTool(context: context) // 设置初始工具
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        updateTool(context: context) // 更新工具状态
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 更新绘图工具
    private func updateTool(context: Context) {
        var currentTool: PKTool
        if isErasing {
            currentTool = PKEraserTool(.bitmap) // 使用位图橡皮擦更精确
        } else {
            currentTool = PKInkingTool(tool, color: color, width: brushSize)
        }
        canvasView.tool = currentTool
    }

    // --- Coordinator for PKCanvasViewDelegate ---
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasViewWrapper

        init(_ parent: CanvasViewWrapper) {
            self.parent = parent
        }

        // 可选：实现 delegate 方法来响应绘图变化等事件
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // 绘图内容改变时的回调
            // 可以在这里触发自动保存或更新状态
        }
    }
}

// --- Preview ---
// struct MaskEditingView_Previews: PreviewProvider {
//     static var previews: some View {
//         // 需要一个示例图片和蒙版来预览
//         let sampleImage = UIImage(systemName: "person.fill") ?? UIImage()
//         let sampleMask = UIImage() // 创建一个空的或简单的蒙版图像
//         MaskEditingView(originalImage: sampleImage, currentMask: sampleMask) { _ in }
//     }
// }
