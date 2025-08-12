import SwiftUI
import AVFoundation

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
                        // 移除了滤镜名称显示
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
                // 移除了滤镜动作
                filterAction: {
                    // 移除了滤镜切换功能
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
        
        // 移除了滤镜相关闭包传递
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 当 UIView 更新时，例如父视图大小改变，确保滤镜层也更新
        // 移除了滤镜相关的注释
    }
    
    // 在销毁时，通知 ViewModel 清理引用
    static func dismantleUIView(_ uiView: PreviewView, coordinator: ()) {
        uiView.onDismantle()
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    
    // 移除了滤镜相关的闭包
    
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
                if connection.isVideoRotationAngleSupported(0) {
                    connection.videoRotationAngle = 0 // 竖屏方向
                }
            }
        } else if keyPath == "bounds", object as? PreviewView === self {
             // 当 PreviewView 大小改变时，不需要同步滤镜覆盖层
             // 移除了滤镜同步调用
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    /// 移除了滤镜覆盖层同步功能
    func syncFilterOverlayWithCurrentFrame() {
        // 移除了滤镜相关功能
    }
    
    /// 当 ViewModel 通过 CameraService 收到新的视频帧时调用
    /// - Parameter pixelBuffer: 新的视频帧数据
    func handleNewSampleBuffer(_ pixelBuffer: CVPixelBuffer) {
        // 缓存当前帧
        currentPixelBuffer = pixelBuffer
        
        // 移除了滤镜应用和渲染
        print("接收到新的视频帧，但滤镜功能已移除")
    }
    
    /// 在 View 被销毁时调用
    func onDismantle() {
        // 移除观察者
        videoPreviewLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        self.removeObserver(self, forKeyPath: "bounds")
        // 移除了滤镜覆盖层移除功能
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
    // 移除了滤镜动作
    
    var body: some View {
        HStack(spacing: 50) {
            // 图库按钮
            ControlButton(iconName: "photo", action: galleryAction)
            
            // 拍照按钮
            CaptureButton(isCapturing: isCapturing, action: captureAction)
            
            // 移除了滤镜按钮
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