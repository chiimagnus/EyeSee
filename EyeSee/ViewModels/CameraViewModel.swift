import Foundation
import SwiftUI
import Combine
import AVFoundation
import UIKit
import CoreImage

@Observable
class CameraViewModel: PreviewViewDelegate { // 遵循新的代理协议
    // MARK: - Services
    let cameraService = CameraService()
    let photoLibraryService = PhotoLibraryService()
    private let filterService = AnimalVisionFilterService()

    // MARK: - State for UI
    var isCapturing = false
    var currentFilter: AnimalVisionFilterService.AnimalFilterType = .none
    var authorizationStatus: AVAuthorizationStatus = .notDetermined
    var isSessionRunning: Bool = false
    var capturedImage: UIImage?
    var showCapturedPreview: Bool = false
    var showSaveSuccessToast: Bool = false
    var errorMessage: String?

    // MARK: - Internal interaction states
    var isGalleryButtonPressed = false
    var isCaptureButtonPressed = false
    var isFilterButtonPressed = false

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Filtered Preview
    private let context = CIContext()
    private weak var currentPreviewView: PreviewView? // 弱引用当前的 PreviewView

    init() {
        // Bridge service -> VM state
        cameraService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.authorizationStatus = status
            }
            .store(in: &cancellables)

        cameraService.$isSessionRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] running in
                self?.isSessionRunning = running
                // 当会话状态改变时，也更新滤镜覆盖层
                if !running {
                    self?.currentPreviewView?.syncFilterOverlayWithCurrentFrame()
                }
            }
            .store(in: &cancellables)

        cameraService.photoSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let self else { return }
                self.capturedImage = image
                self.isCapturing = false
                self.presentCapturedPreviewTemporarily()
                self.saveToPhotoLibrary(image)
            }
            .store(in: &cancellables)

        cameraService.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.isCapturing = false
                self?.errorMessage = error.localizedDescription
            }
            .store(in: &cancellables)
        
        // 设置 CameraService 的代理为 self
        cameraService.setPreviewViewDelegate(self)
    }

    // MARK: - Lifecycle hooks
    func onAppear() {
        cameraService.requestAccessIfNeeded { [weak self] granted in
            guard let self else { return }
            if granted {
                self.cameraService.configureSessionIfNeeded()
                self.cameraService.startSession()
            }
        }
    }

    func onDisappear() {
        cameraService.stopSession()
        // 离开时，currentPreviewView 会被自动释放，其上的覆盖层也会消失
    }

    // MARK: - Actions
    func capturePhoto() {
        guard authorizationStatus == .authorized else {
            // 自动触发一次权限请求
            onAppear()
            return
        }
        guard isSessionRunning else { return }
        isCapturing = true
        cameraService.capturePhoto()
    }

    func switchFilter() {
        let allCases = AnimalVisionFilterService.AnimalFilterType.allCases
        if let currentIndex = allCases.firstIndex(of: currentFilter), currentIndex < allCases.count - 1 {
            currentFilter = allCases[currentIndex + 1]
        } else {
            currentFilter = allCases[0]
        }
        // 切换滤镜后，立即尝试更新预览（如果会话正在运行）
        // 通过调用 PreviewView 的方法来触发滤镜更新
        if isSessionRunning, let previewView = currentPreviewView {
             previewView.syncFilterOverlayWithCurrentFrame()
        }
    }

    func openGallery() {
        // TODO: 后续接入 PhotosPicker
        print("打开图库")
    }
    
    // MARK: - Filtered Preview
    /// 获取应用于预览流的滤镜图像 (如果需要)
    /// - Parameter pixelBuffer: 从相机捕获的原始 CVPixelBuffer
    /// - Returns: 应用了滤镜的 CIImage，如果没有滤镜或失败则返回 nil
    func filteredPreviewImage(from pixelBuffer: CVPixelBuffer) -> CIImage? {
        // 只有在非 "无滤镜" 时才处理
        guard currentFilter != .none else {
            return nil
        }
        
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)
        let filteredImage = AnimalVisionFilterService.applyFilter(to: inputImage, type: currentFilter)
        
        // 如果滤镜没有改变图像，则不应用
        // 注意：这里简单比较引用，实际应用中可能需要更复杂的比较
        // 但对于我们的简单滤镜（颜色矩阵），引用比较是有效的
        if filteredImage === inputImage {
            return nil
        }
        
        return filteredImage
    }
    
    /// 将滤镜后的 CIImage 渲染到指定的 PreviewLayer 上
    /// - Parameters:
    ///   - filteredImage: 滤镜后的 CIImage
    ///   - previewLayer: 目标预览层 (AVCaptureVideoPreviewLayer)
    func renderFilteredImage(_ filteredImage: CIImage, to previewLayer: AVCaptureVideoPreviewLayer) {
        // 使用 CIContext 渲染到 CGImage
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            print("Failed to create CGImage from filtered CIImage")
            removeFilterOverlay()
            return
        }
        
        // 创建一个 CALayer 来显示滤镜后的图像，并添加到 previewLayer 的父视图上
        let filteredLayer = CALayer()
        filteredLayer.contents = cgImage
        filteredLayer.frame = previewLayer.bounds
        filteredLayer.masksToBounds = true
        filteredLayer.name = "AnimalVisionFilterOverlay" // 给 layer 一个名字方便识别
        
        // 确保在主线程操作 UI
        DispatchQueue.main.async {
            // 移除旧的同名滤镜层（如果存在）
            self.removeFilterOverlay()
            
            // 添加新的滤镜层到 previewLayer 的父视图 (UIView) 上
            if let superLayer = previewLayer.superlayer {
                superLayer.addSublayer(filteredLayer)
            }
        }
    }
    
    /// 移除预览层上的滤镜覆盖层
    func removeFilterOverlay() {
        DispatchQueue.main.async {
            // 遍历 currentPreviewView 的 layer 的子 layer，移除名为 "AnimalVisionFilterOverlay" 的
            if let previewView = self.currentPreviewView,
               let superLayer = previewView.videoPreviewLayer.superlayer {
                let filterLayers = superLayer.sublayers?.filter { $0.name == "AnimalVisionFilterOverlay" }
                filterLayers?.forEach { $0.removeFromSuperlayer() }
            }
        }
    }

    // MARK: - PreviewViewDelegate
    func didReceiveNewVideoFrame(_ pixelBuffer: CVPixelBuffer) {
        // 此方法在主线程被调用（由 CameraService 确保）
        // 从 CameraService 接收到新的视频帧
        
        // 将新的帧数据传递给当前的 PreviewView
        // PreviewView 会负责调用 ViewModel 的方法来处理和渲染滤镜
        if let previewView = currentPreviewView {
             previewView.handleNewSampleBuffer(pixelBuffer)
        }
        // 注意：实际的滤镜应用和 UI 更新现在由 PreviewView 触发和处理
    }
    
    // MARK: - Internal methods for View interaction
    /// 供 View 层调用，以设置当前的 PreviewView
    /// - Parameter previewView: 当前的 PreviewView 实例
    func setCurrentPreviewView(_ previewView: PreviewView?) {
        currentPreviewView = previewView
        // 当 PreviewView 改变时，也同步一次滤镜状态
        if let previewView = previewView, isSessionRunning {
            previewView.syncFilterOverlayWithCurrentFrame()
        }
    }


    // MARK: - Helpers
    private func presentCapturedPreviewTemporarily() {
        showCapturedPreview = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.showCapturedPreview = false
        }
    }

    private func saveToPhotoLibrary(_ image: UIImage) {
        photoLibraryService
            .saveImageToLibrary(image)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.showSaveSuccessToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    self?.showSaveSuccessToast = false
                }
            }
            .store(in: &cancellables)
    }
}