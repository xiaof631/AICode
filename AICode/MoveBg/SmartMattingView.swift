import SwiftUI
import Vision // 可能需要引入 Vision 框架进行主体识别
import PhotosUI // 导入 PhotosUI 框架
import CoreImage.CIFilterBuiltins // 导入 CoreImage 滤镜

// --- 移除：Identifiable 包装器 ---
// struct CroppableImage: Identifiable { ... } // (移除)
// --- 结束移除 ---

struct SmartMattingView: View {
    @State private var originalImage: UIImage? = UIImage(named: "your_image_name") // 加载你的图片
    @State private var maskImage: UIImage? // 存储生成的蒙版
    @State private var segmentedImage: UIImage? // 存储抠图后的图像或预览图
    @State private var isEditingMask: Bool = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isMattingComplete: Bool = false

    // --- 移除：用于 sheet(item:) 的状态 ---
    // @State private var croppableImageItem: CroppableImage? = nil // (移除)
    // --- 结束移除 ---


    var body: some View {
        VStack {
            Group {
                // --- 修改：根据 isMattingComplete 和 isMattingInProgress 状态显示不同内容 ---
                if isMattingComplete, let segmented = segmentedImage {
                    // 状态 1: 抠图完成，显示结果
                    Image(uiImage: segmented)
                        .resizable()
                        .scaledToFit()
                        .background(CheckerboardBackground(tileSize: 20))
                } else if let original = originalImage, let mask = maskImage {
                    // 状态 2: 抠图生成蒙版但未完成，显示原图 + 红色蒙版预览
                    // (此状态下抠图已结束，不应用等待动画)
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
                    // --- 修改：在此状态下应用等待动画 ---
                    Image(uiImage: original)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(isMattingInProgress ? 1.05 : 1.0) // 抠图进行中时放大
                        .shadow(radius: isMattingInProgress ? 10 : 0) // 抠图进行中时加阴影
                        .animation(.easeInOut(duration: 0.3), value: isMattingInProgress) // 为状态变化添加动画
                    // --- 结束修改 ---
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
                        // --- 修改：加载成功后，直接设置 originalImage 并执行抠图 ---
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    // 清除之前的抠图结果和状态
                                    self.maskImage = nil
                                    self.segmentedImage = nil
                                    self.isMattingComplete = false
                                    // 直接设置原始图片
                                    self.originalImage = uiImage
                                    // 立即执行智能抠图
                                    performSmartMatting()
                                }
                                return // 成功加载并处理，退出 Task
                            }
                        }
                        // 如果加载失败或取消
                        await MainActor.run {
                             // 可以选择清除 originalImage 或保留旧图
                             // self.originalImage = nil
                             print("Failed to load image or selection cancelled.")
                        }
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
        // --- 移除：用于显示 ImageCroppingView 的 sheet ---
        // .sheet(item: $croppableImageItem) { ... } // (移除)
        // --- 结束移除 ---
        .navigationTitle("智能抠图") // 如果需要的话
    }

    // --- 新增：追踪抠图进度状态 ---
    @State private var isMattingInProgress: Bool = false
    // --- 结束新增 ---

    func performSmartMatting() {
        guard let inputImage = originalImage else { return }
        guard let cgImage = inputImage.cgImage else {
            print("无法获取 CGImage")
            return
        }

        // --- 新增：开始抠图，设置状态 ---
        DispatchQueue.main.async {
            self.isMattingInProgress = true
            // 清除旧结果，确保动画应用在原图上
            self.maskImage = nil
            self.segmentedImage = nil
            self.isMattingComplete = false
        }
        // --- 结束新增 ---

        // --- 确保在后台线程执行 Vision 请求 ---
        DispatchQueue.global(qos: .userInitiated).async {
            if #available(iOS 15.0, *) {
                let request = VNGenerateForegroundInstanceMaskRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    guard let result = request.results?.first else {
                        print("未找到主体实例蒙版")
                        // --- 修改：抠图结束（失败），重置状态 ---
                        DispatchQueue.main.async {
                             self.maskImage = nil
                             self.segmentedImage = nil
                             self.isMattingComplete = false
                             self.isMattingInProgress = false // 结束动画状态
                        }
                        // --- 结束修改 ---
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

                    // --- 修改：抠图结束（成功），更新UI并重置状态 ---
                    DispatchQueue.main.async {
                        self.maskImage = generatedMask
                        self.segmentedImage = previewImage
                        // 注意：这里不设置 isMattingComplete = true，等待用户点击按钮
                        self.isMattingInProgress = false // 结束动画状态
                    }
                    // --- 结束修改 ---

                } catch {
                    print("执行 Vision 请求或处理蒙版失败: \(error.localizedDescription)")
                    // --- 修改：抠图结束（异常），重置状态 ---
                    DispatchQueue.main.async {
                        self.maskImage = nil
                        self.segmentedImage = nil
                        self.isMattingComplete = false
                        self.isMattingInProgress = false // 结束动画状态
                    }
                    // --- 结束修改 ---
                }
            } else {
                // Fallback for older iOS versions
                print("VNGenerateForegroundInstanceMaskRequest 需要 iOS 15+")
                // --- 修改：抠图结束（不支持），重置状态 ---
                DispatchQueue.main.async {
                    self.maskImage = nil
                    self.segmentedImage = nil
                    self.isMattingComplete = false
                    self.isMattingInProgress = false // 结束动画状态
                }
                // --- 结束修改 ---
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
