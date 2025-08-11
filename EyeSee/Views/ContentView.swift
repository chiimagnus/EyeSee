//
//  ContentView.swift
//  EyeSee
//
//  Created by chii_magnus on 2025/8/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 相机预览区域
            CameraPreviewView()
            
            // 底部控制栏
            BottomControlBar()
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    ContentView()
}

// MARK: - 相机预览视图
struct CameraPreviewView: View {
    var body: some View {
        ZStack {
            // 占位符背景色
            Color.black
            
            // 居中的预览文本
            Text("相机预览")
                .foregroundColor(.white)
                .font(.title2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(.black, width: 2) // 黑色实线边框
    }
}

// MARK: - 底部控制栏
struct BottomControlBar: View {
    var body: some View {
        HStack(spacing: 50) {
            // 图库按钮
            ControlButton(iconName: "photo", action: {
                // 图库按钮点击事件
            })
            
            // 拍照按钮
            CaptureButton(action: {
                // 拍照按钮点击事件
            })
            
            // 滤镜按钮
            ControlButton(iconName: "camera.filters", action: {
                // 滤镜按钮点击事件
            })
        }
        .padding(.vertical, 20)
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
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(.primary)
        }
        .frame(width: 70, height: 70)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.black, lineWidth: 2)
        )
        .shadow(color: .black, radius: 0, x: 4, y: 4) // Neo-Brutalism 风格阴影
        .buttonStyle(ControlButtonStyle())
    }
}

// MARK: - 拍照按钮
struct CaptureButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.orange) // 橙色填充
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(.black, lineWidth: 2)
                )
        }
        .shadow(color: .black, radius: 0, x: 4, y: 4) // Neo-Brutalism 风格阴影
        .buttonStyle(CaptureButtonStyle())
    }
}

// MARK: - 控制按钮样式
struct ControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .shadow(color: .black, radius: 0, x: configuration.isPressed ? 2 : 4, y: configuration.isPressed ? 2 : 4)
    }
}

// MARK: - 拍照按钮样式
struct CaptureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .shadow(color: .black, radius: 0, x: configuration.isPressed ? 2 : 4, y: configuration.isPressed ? 2 : 4)
    }
}