import SwiftUI
import UIKit // For UIImage cropping

// --- 移除：拖动句柄定义 ---
// enum DragHandle { ... } // (移除)

struct ImageCroppingView: View {
    let image: UIImage
    // --- 修改：回调可能需要调整，暂时保留，但不再传递裁切后的图片 ---
    let onCrop: (UIImage?) -> Void // 回调函数，后续用于传递抠图结果

    @Environment(\.presentationMode) var presentationMode

    // --- 移除：裁切状态 ---
    // @State private var cropRect: CGRect = .zero // (移除)
    @State private var viewSize: CGSize = .zero
    @State private var totalImageOffset: CGSize = .zero
    @GestureState private var gestureDragOffset: CGSize = .zero

    // --- 移除：裁切框拖动状态 ---
    // @State private var activeDragHandle: DragHandle = .none // (移除)
    // @State private var dragStartLocation: CGPoint = .zero // (移除)
    // @State private var dragStartCropRect: CGRect = .zero // (移除)

    @State private var totalMagnification: CGFloat = 1.0
    @GestureState private var gestureMagnification: CGFloat = 1.0

    // 计算属性：图片在视图中实际显示的尺寸 (考虑手势过程)
    private var currentDisplayedImageSize: CGSize {
        let baseSize = calculateBaseImageSize()
        return CGSize(width: baseSize.width * totalMagnification * gestureMagnification,
                      height: baseSize.height * totalMagnification * gestureMagnification)
    }

    private var currentImagePosition: CGPoint {
        let currentScale = totalMagnification * gestureMagnification
        let calculatedPosition = CGPoint(
            x: viewSize.width / 2 + (totalImageOffset.width + gestureDragOffset.width) * currentScale,
            y: viewSize.height / 2 + (totalImageOffset.height + gestureDragOffset.height) * currentScale
        )
        return calculatedPosition
    }

    private var imageBoundsInView: CGRect {
        CGRect(origin: currentImagePosition, size: currentDisplayedImageSize)
    }

    private func calculateBaseImageSize() -> CGSize {
        guard viewSize != .zero else { return .zero }
        let aspectRatio = image.size.width / image.size.height
        let availableSize = viewSize
        var width = availableSize.width
        var height = width / aspectRatio

        if height > availableSize.height {
            height = availableSize.height
            width = height * aspectRatio
        }
        return CGSize(width: width, height: height)
    }


    // --- 移除：最小裁切尺寸 ---
    // private let minCropSize: CGFloat = 50 // (移除)

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)

                    // 图片层 (可缩放和拖动)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: currentDisplayedImageSize.width, height: currentDisplayedImageSize.height)
                        .position(currentImagePosition)
                        .gesture(
                            DragGesture()
                                .updating($gestureDragOffset) { value, state, _ in
                                    let currentGestureScale = totalMagnification * gestureMagnification
                                    guard currentGestureScale != 0 else { return }
                                    state = CGSize(width: value.translation.width / currentGestureScale, height: value.translation.height / currentGestureScale)
                                }
                                .onEnded { value in
                                    let finalScale = totalMagnification
                                    guard finalScale != 0 else { return }
                                    self.totalImageOffset.width += value.translation.width / finalScale
                                    self.totalImageOffset.height += value.translation.height / finalScale
                                    // --- 移除：调用 adjustCropRectToBounds ---
                                    // adjustCropRectToBounds() // (移除)
                                }
                        )
                        .simultaneousGesture(
                            MagnificationGesture()
                                .updating($gestureMagnification) { currentState, gestureState, _ in
                                    gestureState = currentState
                                }
                                .onEnded { value in
                                    self.totalMagnification *= value
                                    self.totalMagnification = max(1.0, self.totalMagnification)
                                    // --- 移除：调用 adjustCropRectToBounds ---
                                    // adjustCropRectToBounds() // (移除)
                                }
                        )

                    // --- 移除：裁切框和遮罩层 ---
                    // CropAreaOverlay(...) // (移除)
                    // .gesture(...) // (移除)

                }
                .onAppear {
                    self.viewSize = geometry.size
                    // --- 移除：调用 initializeCropRect ---
                    // initializeCropRect(geometryProxy: geometry) // (移除)
                }
                .onChange(of: geometry.size) { newSize in
                     self.viewSize = newSize
                     // --- 移除：调用 initializeCropRect ---
                     // initializeCropRect(geometryProxy: geometry) // (移除)
                }
            }
            // --- 修改：导航栏标题 ---
            .navigationBarTitle("智能抠图", displayMode: .inline) // 修改标题
            .navigationBarItems(
                leading: Button("取消") {
                    onCrop(nil) // 传递 nil 表示取消
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("确认") {
                    // --- 修改：移除裁切逻辑，后续替换为智能抠图逻辑 ---
                    // let cropped = performCrop() // (移除)
                    // onCrop(cropped) // (移除)
                    // 暂时传递原始图片或 nil，根据后续抠图逻辑决定
                    print("触发智能抠图（占位）") // 添加占位打印
                    onCrop(image) // 或者 onCrop(nil) 如果需要先处理
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // --- 移除：初始化裁切框函数 ---
    // private func initializeCropRect(...) { ... } // (移除)

    // --- 移除：处理裁切框拖动函数 ---
    // private func handleDragChange(...) { ... } // (移除)

    // --- 移除：调整裁切框边界函数 ---
    // private func adjustCropRectToBounds() { ... } // (移除)

    // --- 移除：执行裁切函数 ---
    // private func performCrop() -> UIImage? { ... } // (移除)
}

// --- 移除：CropAreaOverlay 和 CropGrid 视图 ---
// struct CropAreaOverlay: View { ... } // (移除)
// struct CropGrid: View { ... } // (移除)

// --- 移除：CGRect 扩展 ---
// extension CGRect { ... } // (移除，如果不再需要)

// --- 预览代码可能也需要调整或移除 ---
// struct ImageCroppingView_Previews: PreviewProvider { ... }
