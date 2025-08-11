//
//  ContentView.swift
//  EyeSee
//
//  Created by chii_magnus on 2025/8/11.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 相机预览区域
            CameraPreviewView(currentFilter: viewModel.currentFilter)
            
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
    }
}

#Preview {
    ContentView()
}

// MARK: - 相机预览视图
struct CameraPreviewView: View {
    let currentFilter: String
    
    var body: some View {
        ZStack {
            // 占位符背景色
            Color.black
            
            // 居中的预览文本
            VStack {
                Text("相机预览")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("当前滤镜: \(currentFilter)")
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(.black, width: 2) // 黑色实线边框
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