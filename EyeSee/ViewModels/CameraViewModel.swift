import Foundation
import SwiftUI
import Combine
import AVFoundation
import UIKit

@Observable
class CameraViewModel: PreviewViewDelegate { // 遵循新的代理协议
    // MARK: - Services
    let cameraService = CameraService()
    let photoLibraryService = PhotoLibraryService()
    // 移除了动物视觉滤镜服务

    // MARK: - State for UI
    var isCapturing = false
    // 移除了滤镜相关状态
    var authorizationStatus: AVAuthorizationStatus = .notDetermined
    var isSessionRunning: Bool = false
    var capturedImage: UIImage?
    var showCapturedPreview: Bool = false
    var showSaveSuccessToast: Bool = false
    var errorMessage: String?

    // MARK: - Internal interaction states
    var isGalleryButtonPressed = false
    var isCaptureButtonPressed = false
    // 移除了滤镜按钮状态

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Preview
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
                // 当会话状态改变时，不需要更新滤镜覆盖层
                if !running {
                    // 移除了滤镜相关代码
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

    // 移除了动物视觉滤镜切换功能
    // func switchFilter() {
    //     // 移除了动物视觉滤镜切换功能
    //     print("滤镜功能已移除")
    // }

    func openGallery() {
        // TODO: 后续接入 PhotosPicker
        print("打开图库")
    }
    
    // MARK: - Preview
    // 移除了动物视觉滤镜相关功能

    // MARK: - PreviewViewDelegate
    func didReceiveNewVideoFrame(_ pixelBuffer: CVPixelBuffer) {
        // 此方法在主线程被调用（由 CameraService 确保）
        // 从 CameraService 接收到新的视频帧
        
        // 移除了滤镜处理相关代码
        print("接收到新的视频帧，但滤镜功能已移除")
    }
    
    // MARK: - Internal methods for View interaction
    /// 供 View 层调用，以设置当前的 PreviewView
    /// - Parameter previewView: 当前的 PreviewView 实例
    func setCurrentPreviewView(_ previewView: PreviewView?) {
        currentPreviewView = previewView
        // 移除了滤镜状态同步相关代码
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