import SwiftUI
import Vision // 可能需要引入 Vision 框架进行主体识别
import PhotosUI // 导入 PhotosUI 框架
import CoreImage.CIFilterBuiltins // 导入 CoreImage 滤镜

// --- 新增：Identifiable 包装器 ---
struct CroppableImage: Identifiable {
    let id = UUID() // 使其唯一可识别
    let image: UIImage
}
// --- 结束新增 ---

struct SmartMattingView: View {
    @State private var originalImage: UIImage? = UIImage(named: "your_image_name") // 加载你的图片
    @State private var maskImage: UIImage? // 存储生成的蒙版
    @State private var segmentedImage: UIImage? // 存储抠图后的图像或预览图
    @State private var isEditingMask: Bool = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isMattingComplete: Bool = false

    // --- Add missing state variables ---
    // @State private var imageToCrop: UIImage? = nil // Stores the original image loaded from PhotosPicker for cropping
    // @State private var showCroppingView: Bool = false // Controls the presentation of the cropping view
    @State private var croppableImageItem: CroppableImage? = nil // 新状态，用于 sheet(item:)
    // --- End adding missing state variables ---


    var body: some View {
        VStack {
            Group {
                // --- 修改：根据 isMattingComplete 状态显示不同内容 ---
                if isMattingComplete, let segmented = segmentedImage {
                    // 状态 1: 用户点击“完成抠图”后，显示抠图结果 + 棋盘格背景
                    Image(uiImage: segmented)
                        .resizable()
                        .scaledToFit()
                        .background(CheckerboardBackground(tileSize: 20))
                } else if let original = originalImage, let mask = maskImage {
                    // 状态 2: 抠图已生成但未“完成”，显示原图 + 红色蒙版预览
                    Image(uiImage: original)
                        .resizable()
                        .scaledToFit()
                        .overlay( // 叠加红色蒙版预览
                            Color.red
                                .mask(
                                    Image(uiImage: mask)
                                        .resizable()
                                        .scaledToFit()
                                )
                                .opacity(0.5)
                        )
                } else if let original = originalImage {
                    // 状态 3: 只有原图（未抠图或抠图失败无蒙版）
                    Image(uiImage: original)
                        .resizable()
                        .scaledToFit()
                } else {
                    // 状态 4: 无图片
                    Text("请选择或加载图片")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                }
                // --- 结束修改 ---
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 保持 Group 填充可用空间

            HStack {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("选择照片")
                }
                .buttonStyle(.borderedProminent)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        // --- 修改：加载成功后，设置 croppableImageItem ---
                        // 先清除旧的待裁切项
                        await MainActor.run {
                            self.croppableImageItem = nil
                        }
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    // 清除之前的抠图结果和状态
                                    self.originalImage = nil
                                    self.maskImage = nil
                                    self.segmentedImage = nil
                                    self.isMattingComplete = false
                                    // 设置新的待裁切项，这将自动触发 sheet
                                    self.croppableImageItem = CroppableImage(image: uiImage)
                                }
                                return // 成功加载并设置，退出 Task
                            }
                        }
                        // 如果加载失败或取消
                        await MainActor.run {
                             self.croppableImageItem = nil // 确保为 nil
                        }
                        print("Failed to load image or selection cancelled.")
                        // --- 结束修改 ---
                    }
                }

                // --- 修改：缩略图优先显示抠图结果 ---
                // 决定缩略图应该显示哪个图像
                let thumbnailImageToShow = segmentedImage ?? originalImage

                if let thumb = thumbnailImageToShow { // 使用决定好的图像
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                        // --- 移除编辑文字叠加 ---
                        // .overlay(
                        //     Text("编辑").font(.caption).foregroundColor(.white).background(Color.black.opacity(0.6)).cornerRadius(4),
                        //     alignment: .bottomTrailing
                        //  )
                        // --- 移除点击手势 ---
                        // .onTapGesture {
                        //     // 编辑逻辑保持不变
                        //     if !isMattingComplete, originalImage != nil, maskImage != nil {
                        //         isEditingMask = true
                        //     } else if originalImage != nil && maskImage == nil {
                        //         performSmartMatting()
                        //     } else if isMattingComplete {
                        //         print("抠图已完成，如需重新编辑，请重新选择照片或添加重置功能。")
                        //     } else {
                        //         print("请先通过 '选择照片' 按钮选择图片")
                        //     }
                        // }
                }
                // --- 结束修改 ---

                Spacer()

                // --- 新增：“完成抠图”按钮 ---
                // 仅当有蒙版且未完成时显示
                if !isMattingComplete && originalImage != nil && maskImage != nil {
                    Button("完成抠图") {
                        // 点击后，将状态设置为完成
                        self.isMattingComplete = true
                    }
                    .buttonStyle(.bordered) // 可以选择其他样式
                }
                // --- 结束新增 ---

            }
            .padding()
        }
        .onAppear {
            // 视图出现时不再自动执行抠图，等待用户选择图片
            // performSmartMatting() // 注释掉或移除这行
            // 如果需要默认图片，可以在这里加载
            if originalImage == nil {
                 // originalImage = UIImage(named: "your_default_image_name")
                 // if originalImage != nil { performSmartMatting() }
            }
        }
        .sheet(isPresented: $isEditingMask) {
            // 弹出蒙版编辑视图
            // 确保编辑时重置完成状态，或在编辑完成后决定是否重置
            if let img = originalImage, let mask = maskImage {
                MaskEditingView(originalImage: img, currentMask: mask) { updatedMask in
                    self.maskImage = updatedMask
                    // 编辑蒙版后，可能需要重置完成状态，让用户再次确认
                    self.isMattingComplete = false
                    updateSegmentedImagePreview() // 重新生成预览（包括 segmentedImage）
                }
            }
        }
        // --- 修改：使用 sheet(item:) ---
        .sheet(item: $croppableImageItem) { item in // 当 croppableImageItem 非 nil 时显示
            // 直接使用 item.image
            ImageCroppingView(image: item.image) { croppedImage in
                // onCrop 回调保持不变
                if let finalImage = croppedImage {
                    self.originalImage = finalImage
                    // 不需要清除 imageToCrop，因为 sheet(item:) 在 item 变为 nil 时自动关闭
                    performSmartMatting()
                } else {
                    print("用户取消了裁切")
                    // 不需要清除 imageToCrop
                }
                // 当 sheet 关闭时 (无论是确认还是取消)，croppableImageItem 会自动变回 nil
            }
        }
        // --- 结束修改 ---
        .navigationTitle("智能抠图") // 如果需要的话
    }

    func performSmartMatting() {
        guard let inputImage = originalImage else { return }
        guard let cgImage = inputImage.cgImage else {
            print("无法获取 CGImage")
            return
        }

        // --- 确保在后台线程执行 Vision 请求 ---
        DispatchQueue.global(qos: .userInitiated).async {
            if #available(iOS 15.0, *) {
                let request = VNGenerateForegroundInstanceMaskRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    guard let result = request.results?.first else {
                        print("未找到主体实例蒙版")
                        // 可以在主线程更新UI提示用户
                        DispatchQueue.main.async {
                             // 可以选择显示原图或错误提示
                             self.maskImage = nil // 确保清除旧蒙版
                             self.segmentedImage = nil // 确保清除旧结果
                             self.isMattingComplete = false // 重置状态
                        }
                        return
                    }

                    // 从结果生成蒙版图像 (CVPixelBuffer -> UIImage)
                    let maskPixelBuffer = try result.generateMaskedImage(
                        ofInstances: result.allInstances,
                        from: handler,
                        croppedToInstancesExtent: false // 获取完整尺寸的蒙版
                    )

                    // 在后台线程处理图像转换和应用蒙版
                    let generatedMask = self.createImage(from: maskPixelBuffer, size: inputImage.size)
                    let previewImage = self.applyMaskToImage(image: inputImage, mask: generatedMask)

                    // --- 回到主线程更新 UI ---
                    DispatchQueue.main.async {
                        self.maskImage = generatedMask
                        self.segmentedImage = previewImage
                        // 注意：这里不设置 isMattingComplete = true，等待用户点击按钮
                    }

                } catch {
                    print("执行 Vision 请求或处理蒙版失败: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        // 处理错误，例如显示原图或提示
                        self.maskImage = nil
                        self.segmentedImage = nil
                        self.isMattingComplete = false
                    }
                }
            } else {
                // Fallback for older iOS versions (if needed)
                print("VNGenerateForegroundInstanceMaskRequest 需要 iOS 15+")
                // ... (可以保留占位符逻辑或移除) ...
                DispatchQueue.main.async {
                    self.maskImage = nil
                    self.segmentedImage = nil
                    self.isMattingComplete = false
                }
            }
        }
    }

    func updateSegmentedImagePreview() {
         guard let inputImage = originalImage, let mask = maskImage else { return }
         DispatchQueue.global(qos: .userInitiated).async {
             let previewImage = applyMaskToImage(image: inputImage, mask: mask)
             DispatchQueue.main.async {
                 self.segmentedImage = previewImage
                 // 编辑后也需要用户再次点击“完成”，所以重置状态
                 self.isMattingComplete = false
             }
         }
    }

    // --- Helper Functions ---

    // 将 CVPixelBuffer (蒙版) 转换为 UIImage
    func createImage(from pixelBuffer: CVPixelBuffer, size: CGSize) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        // 蒙版通常是单通道灰度图，前景为白色（或接近1），背景为黑色（或接近0）
        // 为了可视化或后续处理，我们可能需要将其转换为 RGBA 图像
        // 这里我们直接使用它作为蒙版

        // 创建一个 CIContext
        let context = CIContext(options: nil)

        // 从 CIImage 创建 CGImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("无法从 CIImage 创建 CGImage")
            return nil
        }

        // 从 CGImage 创建 UIImage
        // 注意：这里的 scale 和 orientation 可能需要根据原始图像调整
        return UIImage(cgImage: cgImage, scale: originalImage?.scale ?? 1.0, orientation: originalImage?.imageOrientation ?? .up)
    }


    func generatePlaceholderMask(for image: UIImage) -> UIImage? {
        // TODO: 使用 Vision 或其他库实现主体分割，生成蒙版
        print("TODO: Implement smart matting logic using Vision")
        // 返回一个与原图等大的纯色或特定形状的 UIImage 作为蒙版示例
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.red.cgColor) // 红色蒙版
        // 绘制一个简单的形状作为占位符
        let rect = CGRect(x: image.size.width * 0.1, y: image.size.height * 0.1, width: image.size.width * 0.8, height: image.size.height * 0.8)
        context.fill(rect)
        let mask = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mask
    }

    func applyMaskToImage(image: UIImage, mask: UIImage?) -> UIImage? {
        guard let mask = mask,
              let originalCIImage = CIImage(image: image),
              let maskCIImage = CIImage(image: mask) else {
            print("无法应用蒙版，缺少图像或蒙版")
            return image // 返回原图或 nil
        }

        // 创建 Core Image 上下文
        let context = CIContext(options: nil)

        // --- 修改：使用 CISourceInCompositing 和 setValue ---
        guard let filter = CIFilter(name: "CISourceInCompositing") else {
             print("无法创建 CISourceInCompositing 滤镜")
             return image
        }
        filter.setValue(originalCIImage, forKey: kCIInputImageKey)
        filter.setValue(maskCIImage, forKey: kCIInputBackgroundImageKey) // 使用标准 Key
        // --- 结束修改 ---

        // --- 原来的 CIBlendWithMask 方法 (注释掉或删除) ---
        // let blendFilter = CIFilter.blendWithMask()
        // blendFilter.inputImage = originalCIImage
        // blendFilter.maskImage = maskCIImage
        // blendFilter.backgroundImage = CIImage.empty() // 使用透明背景
        // guard let outputCIImage = blendFilter.outputImage else { ... }
        // --- 结束原来的方法 ---


        // 获取滤镜输出
        guard let outputCIImage = filter.outputImage else {
             print("应用蒙版滤镜 (CISourceInCompositing) 失败")
             return image // 或者返回 nil
         }


        // 将处理后的 CIImage 转换回 UIImage
        // 注意保持原始图像的尺寸和方向
        // --- 修改：确保输出尺寸与原图一致 ---
        // CISourceInCompositing 的输出范围可能只包含蒙版区域，需要指定渲染范围为原图范围
        guard let outputCGImage = context.createCGImage(outputCIImage, from: originalCIImage.extent) else {
             print("无法从处理后的 CIImage 创建 CGImage")
             return image // 或者返回 nil
         }
        // --- 结束修改 ---

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct SmartMattingView_Previews: PreviewProvider {
    static var previews: some View {
        // 为了预览，你可能需要添加一张名为 "your_image_name" 的图片到 Assets
        SmartMattingView()
    }
}

// --- 确保 ImageCroppingView.swift 文件存在且正确 ---
// (不需要修改 ImageCroppingView.swift 本身)
