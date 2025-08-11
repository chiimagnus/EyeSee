//
//  CameraViewModel.swift
//  EyeSee
//
//  Created by chii_magnus on 2025/8/11.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import UIKit

@Observable
class CameraViewModel {
    // MARK: - Services
    let cameraService = CameraService()

    // MARK: - State for UI
    var isCapturing = false
    var currentFilter: String = "无滤镜"
    var authorizationStatus: AVAuthorizationStatus = .notDetermined
    var isSessionRunning: Bool = false
    var capturedImage: UIImage?
    var showCapturedPreview: Bool = false
    var errorMessage: String?

    // MARK: - Internal interaction states
    var isGalleryButtonPressed = false
    var isCaptureButtonPressed = false
    var isFilterButtonPressed = false

    // MARK: - Filters
    let filters = ["无滤镜", "狗狗视角", "猫咪视角", "鸟类视角"]

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

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
            }
            .store(in: &cancellables)

        cameraService.photoSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let self else { return }
                self.capturedImage = image
                self.isCapturing = false
                self.presentCapturedPreviewTemporarily()
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
        if let currentIndex = filters.firstIndex(of: currentFilter), currentIndex < filters.count - 1 {
            currentFilter = filters[currentIndex + 1]
        } else {
            currentFilter = filters[0]
        }
    }

    func openGallery() {
        // TODO: 后续接入 PhotosPicker
        print("打开图库")
    }

    // MARK: - Helpers
    private func presentCapturedPreviewTemporarily() {
        showCapturedPreview = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.showCapturedPreview = false
        }
    }
}