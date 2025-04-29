import SwiftUI
import UIKit // For UIImage cropping

// --- 新增：定义拖动句柄的位置 ---
enum DragHandle {
    case topLeft, topRight, bottomLeft, bottomRight, none
}

struct ImageCroppingView: View {
    let image: UIImage
    let onCrop: (UIImage?) -> Void // 回调函数，传递裁切后的图片或 nil (取消时)

    @Environment(\.presentationMode) var presentationMode // 用于关闭视图

    // --- 裁切状态 ---
    @State private var cropRect: CGRect = .zero // 裁切框在视图坐标系中的位置和大小
    @State private var viewSize: CGSize = .zero // 容器视图的大小，用于计算坐标
    @State private var imageScale: CGFloat = 1.0 // 图片当前的缩放比例
    @State private var imageOffset: CGSize = .zero // 图片当前的偏移量 (拖动)

    // --- 拖动状态 ---
    @State private var activeDragHandle: DragHandle = .none // 当前拖动的句柄
    @State private var dragStartLocation: CGPoint = .zero // 拖动开始时的触摸位置
    @State private var dragStartCropRect: CGRect = .zero // 拖动开始时的裁切框
    // --- 结束修改 ---

    @State private var currentMagnification: CGFloat = 1.0
    @State private var totalMagnification: CGFloat = 1.0 // 累计缩放

    // 计算属性：图片在视图中实际显示的尺寸
    private var displayedImageSize: CGSize {
        let aspectRatio = image.size.width / image.size.height
        let availableSize = viewSize
        var width = availableSize.width
        var height = width / aspectRatio

        if height > availableSize.height {
            height = availableSize.height
            width = height * aspectRatio
        }
        // 应用缩放
        return CGSize(width: width * totalMagnification, height: height * totalMagnification)
    }

    // 计算属性：图片在视图中的位置（考虑偏移和缩放）
    private var imagePosition: CGPoint {
        CGPoint(x: viewSize.width / 2 + imageOffset.width * totalMagnification, // 偏移也受缩放影响
                y: viewSize.height / 2 + imageOffset.height * totalMagnification)
    }

    // --- 新增：计算图片在视图中的实际边界 ---
    private var imageBoundsInView: CGRect {
        CGRect(center: imagePosition, size: displayedImageSize)
    }
    // --- 结束新增 ---

    // --- 新增：最小裁切尺寸 ---
    private let minCropSize: CGFloat = 50
    // --- 结束新增 ---

    var body: some View {
        NavigationView { // 添加 NavigationView 以便放置按钮
            GeometryReader { geometry in
                ZStack {
                    // 背景层 (可选，例如深色背景)
                    Color.black.edgesIgnoringSafeArea(.all)

                    // 图片层 (可缩放和拖动)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit() // 初始适应屏幕
                        .frame(width: displayedImageSize.width, height: displayedImageSize.height)
                        .position(imagePosition)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    self.imageOffset = CGSize(width: value.translation.width / totalMagnification, height: value.translation.height / totalMagnification)
                                }
                                .onEnded { value in
                                    // 可以添加边界检查，防止图片移出视图
                                    // 累加偏移量（如果需要）
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    self.currentMagnification = value
                                    self.imageScale = totalMagnification * currentMagnification
                                }
                                .onEnded { value in
                                    self.totalMagnification *= value
                                    self.currentMagnification = 1.0 // 重置当前缩放
                                    // 限制缩放范围
                                    self.totalMagnification = max(1.0, self.totalMagnification) // 最小为 1
                                    self.imageScale = totalMagnification
                                    // 缩放后可能需要调整裁切框以保持在图片内
                                    adjustCropRectToBounds()
                                }
                        )


                    // 裁切框和遮罩层
                    // --- 修改：传递 activeDragHandle 和添加手势 ---
                    CropAreaOverlay(cropRect: $cropRect, viewSize: viewSize, activeHandle: $activeDragHandle)
                        .gesture(
                            DragGesture(minimumDistance: 0) // minimumDistance 0 确保能立即响应
                                .onChanged { value in
                                    handleDragChange(value: value, geometryProxy: geometry)
                                }
                                .onEnded { _ in
                                    // 拖动结束，重置状态
                                    activeDragHandle = .none
                                    // 确保裁切框最终在图片边界内
                                    adjustCropRectToBounds()
                                }
                        )
                    // --- 结束修改 ---

                }
                .onAppear {
                    // 初始化裁切框和视图大小
                    self.viewSize = geometry.size
                    // 初始裁切框，例如设置为视图中心的正方形
                    let initialCropSize: CGFloat = min(geometry.size.width, geometry.size.height) * 0.8
                    self.cropRect = CGRect(
                        x: (geometry.size.width - initialCropSize) / 2,
                        y: (geometry.size.height - initialCropSize) / 2,
                        width: initialCropSize,
                        height: initialCropSize
                    )
                    // 确保初始裁切框在图片内 (如果图片较小)
                    adjustInitialCropRectToBounds()
                }
                // 视图大小变化时更新
                .onChange(of: geometry.size) { newSize in
                     self.viewSize = newSize
                     // 可能需要重新计算裁切框位置/大小以适应新尺寸
                }
            }
            .navigationBarTitle("裁切图片", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    onCrop(nil) // 传递 nil 表示取消
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("确认") {
                    let cropped = performCrop()
                    onCrop(cropped) // 传递裁切后的图片
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle()) // 避免 iPad 上的侧边栏样式
    }

    // 调整初始裁切框，确保它在图片范围内
    private func adjustInitialCropRectToBounds() {
        let imgRect = CGRect(center: imagePosition, size: displayedImageSize)
        cropRect = cropRect.intersection(imgRect) // 取交集确保在内部
    }


    // --- Renamed function ---
    // Adjust the crop rect to ensure it stays within the image bounds
    private func adjustCropRectToBounds() {
        let imgRect = imageBoundsInView // Use the calculated image bounds
        cropRect = cropRect.intersection(imgRect) // Ensure intersection

        // Also ensure minimum size after intersection
        if cropRect.width < minCropSize {
            cropRect.size.width = minCropSize
        }
        if cropRect.height < minCropSize {
            cropRect.size.height = minCropSize
        }
        // Re-check bounds after minimum size enforcement if necessary,
        // though intersection should handle the origin correctly.
        cropRect = cropRect.intersection(imgRect)
    }


    // Execute the crop operation
    private func performCrop() -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // 1. 计算图片在视图中的实际显示区域
        let displayedImageRect = imageBoundsInView // 使用计算属性

        // 2. 将视图坐标系中的裁切框 (cropRect) 转换为相对于 *显示图片* 的坐标系
        let cropOriginInDisplayedImage = CGPoint(
            x: cropRect.origin.x - displayedImageRect.origin.x,
            y: cropRect.origin.y - displayedImageRect.origin.y
        )
        let cropRectInDisplayedImage = CGRect(origin: cropOriginInDisplayedImage, size: cropRect.size)

        // 3. 计算这个相对于显示图片的裁切框，对应到 *原始图片* 上的比例坐标
        //    使用原始图片尺寸和显示图片尺寸计算缩放比例
        let scaleX = image.size.width / displayedImageSize.width
        let scaleY = image.size.height / displayedImageSize.height

        let cropRectInOriginalImage = CGRect(
            x: cropRectInDisplayedImage.origin.x * scaleX,
            y: cropRectInDisplayedImage.origin.y * scaleY,
            width: cropRectInDisplayedImage.size.width * scaleX,
            height: cropRectInDisplayedImage.size.height * scaleY
        )

        // 4. 使用 CGImage 的 cropping(to:) 方法进行裁切
        //    添加一个检查，确保计算出的裁切区域在原始 CGImage 范围内
        let cgImageRect = CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height))
        guard let validCropRect = cropRectInOriginalImage.intersection(cgImageRect).nilIfEmpty else {
             print("Calculated crop rect is outside the original image bounds or invalid.")
             return nil
        }

        guard let croppedCGImage = cgImage.cropping(to: validCropRect) else {
            print("CGImage cropping failed.")
            return nil
        }

        // 5. 将裁切后的 CGImage 转换回 UIImage
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    // --- Add the missing handleDragChange function ---
    private func handleDragChange(value: DragGesture.Value, geometryProxy: GeometryProxy) {
        let location = value.location
        let translation = value.translation
        let imgRect = imageBoundsInView // Get current image bounds

        if activeDragHandle == .none {
            // Determine which handle is being dragged at the start
            dragStartLocation = location
            dragStartCropRect = cropRect

            let handleSize: CGFloat = 20 // Larger tappable area for handles
            let topLeftRect = CGRect(center: CGPoint(x: cropRect.minX, y: cropRect.minY), size: CGSize(width: handleSize, height: handleSize))
            let topRightRect = CGRect(center: CGPoint(x: cropRect.maxX, y: cropRect.minY), size: CGSize(width: handleSize, height: handleSize))
            let bottomLeftRect = CGRect(center: CGPoint(x: cropRect.minX, y: cropRect.maxY), size: CGSize(width: handleSize, height: handleSize))
            let bottomRightRect = CGRect(center: CGPoint(x: cropRect.maxX, y: cropRect.maxY), size: CGSize(width: handleSize, height: handleSize))

            if topLeftRect.contains(location) { activeDragHandle = .topLeft }
            else if topRightRect.contains(location) { activeDragHandle = .topRight }
            else if bottomLeftRect.contains(location) { activeDragHandle = .bottomLeft }
            else if bottomRightRect.contains(location) { activeDragHandle = .bottomRight }
            else {
                // If not dragging a handle, maybe drag the whole crop area?
                // For now, we only handle corner drags.
                // You could add logic here to drag the entire rect if desired.
                activeDragHandle = .none // Or a new case like .move
                return // Exit if not dragging a handle
            }
        }

        // Calculate new rect based on the active handle and translation
        var newRect = dragStartCropRect
        let deltaX = translation.width
        let deltaY = translation.height

        switch activeDragHandle {
        case .topLeft:
            newRect.origin.x = dragStartCropRect.minX + deltaX
            newRect.origin.y = dragStartCropRect.minY + deltaY
            newRect.size.width = dragStartCropRect.width - deltaX
            newRect.size.height = dragStartCropRect.height - deltaY
        case .topRight:
            newRect.origin.y = dragStartCropRect.minY + deltaY
            newRect.size.width = dragStartCropRect.width + deltaX
            newRect.size.height = dragStartCropRect.height - deltaY
        case .bottomLeft:
            newRect.origin.x = dragStartCropRect.minX + deltaX
            newRect.size.width = dragStartCropRect.width - deltaX
            newRect.size.height = dragStartCropRect.height + deltaY
        case .bottomRight:
            newRect.size.width = dragStartCropRect.width + deltaX
            newRect.size.height = dragStartCropRect.height + deltaY
        case .none:
            return // Should not happen if logic above is correct
        }

        // Enforce minimum size
        if newRect.width < minCropSize {
            let diff = minCropSize - newRect.width
            if activeDragHandle == .topLeft || activeDragHandle == .bottomLeft {
                newRect.origin.x -= diff // Adjust origin when shrinking from left
            }
            newRect.size.width = minCropSize
        }
        if newRect.height < minCropSize {
            let diff = minCropSize - newRect.height
            if activeDragHandle == .topLeft || activeDragHandle == .topRight {
                newRect.origin.y -= diff // Adjust origin when shrinking from top
            }
            newRect.size.height = minCropSize
        }

        // Clamp to image bounds during drag
        newRect = newRect.intersection(imgRect)

        // Update the state
        cropRect = newRect
    }
    // --- End adding function ---
}

// --- Views for Overlay and Grid ---
struct CropAreaOverlay: View {
    @Binding var cropRect: CGRect
    let viewSize: CGSize
    @Binding var activeHandle: DragHandle // 接收活动句柄状态

    // --- 新增：句柄样式 ---
    let handleSize: CGFloat = 10 // 可视句柄大小
    let handleColor = Color.white
    // --- 结束新增 ---

    var body: some View {
        ZStack {
            // 半透明遮罩层
            Color.black.opacity(0.5)

            // "挖空" 裁切区域
            Rectangle()
                .fill(Color.clear)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .blendMode(.destinationOut)

            // 绘制裁切框的边框
            Rectangle()
                .stroke(handleColor, lineWidth: 1) // 边框细一点
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)

            // 绘制网格线
            CropGrid(cropRect: cropRect)

            // --- 新增：绘制角点句柄 ---
            // Top Left
            Rectangle()
                .fill(handleColor)
                .frame(width: handleSize, height: handleSize)
                .position(x: cropRect.minX, y: cropRect.minY)
            // Top Right
            Rectangle()
                .fill(handleColor)
                .frame(width: handleSize, height: handleSize)
                .position(x: cropRect.maxX, y: cropRect.minY)
            // Bottom Left
            Rectangle()
                .fill(handleColor)
                .frame(width: handleSize, height: handleSize)
                .position(x: cropRect.minX, y: cropRect.maxY)
            // Bottom Right
            Rectangle()
                .fill(handleColor)
                .frame(width: handleSize, height: handleSize)
                .position(x: cropRect.maxX, y: cropRect.maxY)
            // --- 结束新增 ---

        }
        .compositingGroup()
        // --- 新增：根据活动句柄改变鼠标指针样式 (仅 macOS) ---
        // .cursor(cursorForHandle(activeHandle)) // 需要一个辅助函数 cursorForHandle
        // --- 结束新增 ---
    }
}

// 辅助视图：绘制网格线
struct CropGrid: View {
    let cropRect: CGRect

    var body: some View {
        Path { path in
            let stepX = cropRect.width / 3
            let stepY = cropRect.height / 3

            // 垂直线
            for i in 1..<3 {
                let x = cropRect.minX + CGFloat(i) * stepX
                path.move(to: CGPoint(x: x, y: cropRect.minY))
                path.addLine(to: CGPoint(x: x, y: cropRect.maxY))
            }
            // 水平线
            for i in 1..<3 {
                let y = cropRect.minY + CGFloat(i) * stepY
                path.move(to: CGPoint(x: cropRect.minX, y: y))
                path.addLine(to: CGPoint(x: cropRect.maxX, y: y))
            }
        }
        .stroke(Color.white.opacity(0.6), lineWidth: 1)
    }
}

// 扩展 CGRect 以方便获取中心点
extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}

// 预览 (可选)
struct ImageCroppingView_Previews: PreviewProvider {
    static var previews: some View {
        // 需要一个示例图片才能预览
        if let img = UIImage(systemName: "photo") { // 使用系统图标作为示例
             ImageCroppingView(image: img, onCrop: { cropped in
                 print("Cropped image received: \(cropped != nil)")
             })
        } else {
            Text("无法加载预览图片")
        }
    }
}

// --- 新增：CGRect 扩展，处理空矩形 ---
extension CGRect {
    var nilIfEmpty: CGRect? {
        return isEmpty ? nil : self
    }
}
// --- 结束新增 ---