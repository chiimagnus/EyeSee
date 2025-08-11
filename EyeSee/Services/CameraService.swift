import Foundation
import AVFoundation
import Combine
import UIKit

final class CameraService: NSObject, ObservableObject {
    enum CameraServiceError: Error, LocalizedError {
        case configurationFailed
        case noCameraAvailable
        case captureFailed
        
        var errorDescription: String? {
            switch self {
            case .configurationFailed: return "相机配置失败"
            case .noCameraAvailable: return "没有可用的相机设备"
            case .captureFailed: return "拍照失败"
            }
        }
    }
    
    // MARK: - Public
    let session = AVCaptureSession()
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var isSessionRunning: Bool = false
    @Published private(set) var lastCapturedImage: UIImage?
    @Published var lastError: CameraServiceError?
    
    let photoSubject = PassthroughSubject<UIImage, Never>()
    
    // MARK: - Private
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // MARK: - Authorization
    func requestAccessIfNeeded(completion: ((Bool) -> Void)? = nil) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status
        switch status {
        case .authorized:
            completion?(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    completion?(granted)
                }
            }
        default:
            completion?(false)
        }
    }
    
    // MARK: - Session lifecycle
    func configureSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.videoDeviceInput == nil else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // Input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
                    AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
                    AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async { self.lastError = .noCameraAvailable }
                self.session.commitConfiguration()
                return
            }
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                } else {
                    DispatchQueue.main.async { self.lastError = .configurationFailed }
                    self.session.commitConfiguration()
                    return
                }
            } catch {
                DispatchQueue.main.async { self.lastError = .configurationFailed }
                self.session.commitConfiguration()
                return
            }
            
            // Output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            } else {
                DispatchQueue.main.async { self.lastError = .configurationFailed }
                self.session.commitConfiguration()
                return
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isSessionRunning = true }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isSessionRunning = false }
        }
    }
    
    // MARK: - Capture
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        // 在现代系统下，使用默认设置即可由系统选择合适的编码（HEIC/JPEG）
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            DispatchQueue.main.async { self.lastError = .captureFailed }
            print("Capture error: \(error)")
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            DispatchQueue.main.async { self.lastError = .captureFailed }
            return
        }
        DispatchQueue.main.async {
            self.lastCapturedImage = image
            self.photoSubject.send(image)
        }
    }
}


