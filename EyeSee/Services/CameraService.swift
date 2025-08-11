import Foundation
import AVFoundation
import Combine
import UIKit
import CoreImage

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
    
    // MARK: - Video Data Output for real-time filtering
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var videoDataOutputConnection: AVCaptureConnection?
    
    // MARK: - Private
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // MARK: - Delegates
    private weak var previewViewDelegate: PreviewViewDelegate?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupVideoDataOutput()
    }
    
    // MARK: - Setup
    private func setupVideoDataOutput() {
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        // 设置输出格式，这里选择 BGRA 以便于处理
        videoDataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
    }
    
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
            self.session.beginConfiguration()
            
            // Ensure session preset is set only once
            if self.session.sessionPreset == .high { // Check if it's the default (.high) or not set properly
                self.session.sessionPreset = .photo
            }
            
            // Input
            if self.videoDeviceInput == nil {
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
            }
            
            // Photo Output
            if !self.session.outputs.contains(self.photoOutput) {
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                } else {
                    DispatchQueue.main.async { self.lastError = .configurationFailed }
                    self.session.commitConfiguration()
                    return
                }
            }
            
            // Video Data Output for preview filtering
            if !self.session.outputs.contains(self.videoDataOutput) {
                if self.session.canAddOutput(self.videoDataOutput) {
                    self.session.addOutput(self.videoDataOutput)
                    // Get the connection for video data
                    self.videoDataOutputConnection = self.videoDataOutput.connection(with: .video)
                    // Set video orientation if possible
                    if let connection = self.videoDataOutputConnection,
                       connection.isVideoRotationAngleSupported(0) {
                        connection.videoRotationAngle = 0
                    }
                } else {
                    DispatchQueue.main.async { self.lastError = .configurationFailed }
                    self.session.commitConfiguration()
                    return
                }
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
    
    // MARK: - Preview Filtering Integration
    /// 设置预览视图代理，用于接收实时视频帧以应用滤镜
    /// - Parameter delegate: 遵循 PreviewViewDelegate 协议的对象
    func setPreviewViewDelegate(_ delegate: PreviewViewDelegate?) {
        previewViewDelegate = delegate
    }
}

// MARK: - Photo Capture Delegate
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

// MARK: - Video Data Output Sample Buffer Delegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 确保这是来自视频数据输出的连接
        guard output == videoDataOutput else { return }
        
        // 获取 pixel buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 通知代理（通常是 ViewModel）有新的帧到来，可以应用滤镜
        DispatchQueue.main.async {
            self.previewViewDelegate?.didReceiveNewVideoFrame(pixelBuffer)
        }
    }
}

// MARK: - Preview View Delegate
/// 协议定义，用于 CameraService 向 ViewModel 传递实时视频帧
protocol PreviewViewDelegate: AnyObject {
    /// 当 CameraService 捕获到新的视频帧时调用
    /// - Parameter pixelBuffer: 包含视频帧数据的 CVPixelBuffer
    func didReceiveNewVideoFrame(_ pixelBuffer: CVPixelBuffer)
}


