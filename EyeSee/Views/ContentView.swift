//
//  ContentView.swift
//  EyeSee
//
//  Created by chii_magnus on 2025/8/11.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 相机预览区域
            ZStack {
                CameraPreviewLayerView(session: viewModel.cameraService.session)
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

#Preview {
    ContentView()
}

// MARK: - AVCaptureVideoPreview SwiftUI 包装
struct CameraPreviewLayerView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
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