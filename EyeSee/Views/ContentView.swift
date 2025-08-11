import SwiftUI
import AVFoundation
import CoreImage

struct ContentView: View {
    @State private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 相机预览区域
            ZStack {
                CameraPreviewLayerView(viewModel: viewModel) // 传递 viewModel
                    .overlay(alignment: .topLeading) {
                        // 权限或错误提示（MVP 简单文字）
                        if viewModel.authorizationStatus != .authorized {
                            Text("需要相机权限")
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding()
                        }
                        if let message = viewModel.errorMessage {
                            Text(message)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding()
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if viewModel.showSaveSuccessToast {
                            Text("已保存到相册")
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .overlay(alignment: .bottomLeading) {
                        // 显示当前滤镜名称
                        if viewModel.currentFilter != .none {
                            Text(viewModel.currentFilter.rawValue)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding()
                        }
                    }

                // 拍到的图片短暂预览
                if viewModel.showCapturedPreview, let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.6))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            
            // 底部控制栏
            BottomControlBar(
                isCapturing: viewModel.isCapturing,
                galleryAction: {
                    viewModel.openGallery()
                },
                captureAction: {
                    viewModel.capturePhoto()
                },
                filterAction: {
                    viewModel.switchFilter()
                }
            )
        }
        .ignoresSafeArea(.all)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - AVCaptureVideoPreview SwiftUI 包装
struct CameraPreviewLayerView: UIViewRepresentable {
    let viewModel: CameraViewModel // 直接持有 ViewModel
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = viewModel.cameraService.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // 将 PreviewView 的引用设置给 ViewModel
        viewModel.setCurrentPreviewView(view)
        
        // 将 ViewModel 的方法作为闭包传递给 PreviewView
        view.filterImageProvider = viewModel.filteredPreviewImage(from:)
        view.filterRenderer = viewModel.renderFilteredImage(_:to:)
        view.filterRemover = viewModel.removeFilterOverlay
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 当 UIView 更新时，例如父视图大小改变，确保滤镜层也更新
        // 不再需要在这里调用 syncFilterOverlayWithCurrentFrame，
        // 因为滤镜更新由 CameraService 驱动或 ViewModel 的 switchFilter 主动触发。
        // 如果需要强制刷新（例如在某些特定的 UI 变化后），可以在这里调用。
        // 但通常情况下，依赖数据流是更好的做法。
        // DispatchQueue.main.async {
        //     uiView.syncFilterOverlayWithCurrentFrame()
        // }
    }
    
    // 在销毁时，通知 ViewModel 清理引用
    static func dismantleUIView(_ uiView: PreviewView, coordinator: ()) {
        uiView.onDismantle()
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    
    // 持有 ViewModel 提供的闭包
    var filterImageProvider: ((CVPixelBuffer) -> CIImage?)?
    var filterRenderer: ((CIImage, AVCaptureVideoPreviewLayer) -> Void)?
    var filterRemover: (() -> Void)?
    
    private var currentPixelBuffer: CVPixelBuffer? // 缓存当前的 pixel buffer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        videoPreviewLayer.addObserver(self, forKeyPath: "readyForDisplay", options: .new, context: nil)
        // 监听 bounds 变化以适应布局变化
        self.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "readyForDisplay", object as? AVCaptureVideoPreviewLayer === self.videoPreviewLayer {
            // 当预览层准备好显示时，设置连接方向
            if let connection = videoPreviewLayer.connection, connection.isEnabled {
                connection.videoOrientation = .portrait // 默认竖屏
            }
        } else if keyPath == "bounds", object as? PreviewView === self {
             // 当 PreviewView 大小改变时，同步滤镜覆盖层
             syncFilterOverlayWithCurrentFrame()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    /// 同步滤镜覆盖层与当前帧（如果有的话）
    func syncFilterOverlayWithCurrentFrame() {
        guard let pixelBuffer = currentPixelBuffer,
              let filterImageProvider = self.filterImageProvider,
              let filterRenderer = self.filterRenderer else {
            // 如果没有帧数据或闭包，移除覆盖层
            filterRemover?()
            return
        }
        
        // 应用滤镜并渲染
        if let filteredImage = filterImageProvider(pixelBuffer) {
            filterRenderer(filteredImage, self.videoPreviewLayer)
        } else {
            // 如果没有滤镜或滤镜处理失败，移除覆盖层
            filterRemover?()
        }
    }
    
    /// 当 ViewModel 通过 CameraService 收到新的视频帧时调用
    /// - Parameter pixelBuffer: 新的视频帧数据
    func handleNewSampleBuffer(_ pixelBuffer: CVPixelBuffer) {
        // 缓存当前帧
        currentPixelBuffer = pixelBuffer
        
        // 应用滤镜并渲染
        syncFilterOverlayWithCurrentFrame()
    }
    
    /// 在 View 被销毁时调用
    func onDismantle() {
        // 移除观察者
        videoPreviewLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        self.removeObserver(self, forKeyPath: "bounds")
        // 移除滤镜覆盖层
        filterRemover?()
    }
    
    deinit {
        // 确保在销毁时移除观察者和覆盖层
        onDismantle()
    }
}

// MARK: - 底部控制栏
struct BottomControlBar: View {
    let isCapturing: Bool
    let galleryAction: () -> Void
    let captureAction: () -> Void
    let filterAction: () -> Void
    
    var body: some View {
        HStack(spacing: 50) {
            // 图库按钮
            ControlButton(iconName: "photo", action: galleryAction)
            
            // 拍照按钮
            CaptureButton(isCapturing: isCapturing, action: captureAction)
            
            // 滤镜按钮
            ControlButton(iconName: "camera.filters", action: filterAction)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray5)) // 浅灰色背景
        .border(.black, width: 2) // 黑色实线边框
    }
}

// MARK: - 控制按钮（图库和滤镜）
struct ControlButton: View {
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(.black, lineWidth: 2)
                    )
                    .shadow(color: .black, radius: 0, x: 4, y: 4) // Neo-Brutalism 风格阴影
                
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(ControlButtonStyle())
    }
}

// MARK: - 拍照按钮
struct CaptureButton: View {
    let isCapturing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.red) // 红色填充
                
                if isCapturing {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .scaleEffect(1.2)
                        .opacity(0.7)
                }
            }
            .frame(width: 80, height: 80)
            .overlay(
                Circle()
                    .stroke(.black, lineWidth: 2)
            )
        }
        .shadow(color: .black, radius: 0, x: 4, y: 4) // Neo-Brutalism 风格阴影
        .buttonStyle(CaptureButtonStyle(isCapturing: isCapturing))
    }
}

// MARK: - 控制按钮样式
struct ControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .shadow(color: .black, radius: 0, x: configuration.isPressed ? 2 : 4, y: configuration.isPressed ? 2 : 4)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 拍照按钮样式
struct CaptureButtonStyle: ButtonStyle {
    let isCapturing: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed || isCapturing ? 0.9 : 1.0)
            .shadow(color: .black, radius: 0, x: configuration.isPressed || isCapturing ? 2 : 4, y: configuration.isPressed || isCapturing ? 2 : 4)
    }
}

#Preview {
    ContentView()
}