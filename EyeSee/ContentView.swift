//
//  ContentView.swift
//  EyeSee
//
//  Created by chii_magnus on 2025/8/10.
//

import SwiftUI
import SwiftData

// MARK: - Neo-Brutalism Color Extensions
extension Color {
    static let brutalBackground = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let brutalForeground = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let brutalPrimary = Color(red: 0.8, green: 0.27, blue: 0.27) // #C44
    static let brutalPrimaryForeground = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let brutalSecondary = Color(red: 0.44, green: 0.93, blue: 0.86) // #7ED
    static let brutalSecondaryForeground = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let brutalMuted = Color(red: 0.94, green: 0.94, blue: 0.94) // #F0F0F0
    static let brutalBorder = Color(red: 0.0, green: 0.0, blue: 0.0)
}

// MARK: - Neo-Brutalism Shadow Extensions
extension View {
    func brutalShadow() -> some View {
        self.shadow(color: .black, radius: 0, x: 4, y: 4)
    }
    
    func brutalShadowPressed() -> some View {
        self.shadow(color: .black, radius: 0, x: 2, y: 2)
    }
}

struct ContentView: View {
    var body: some View {
        MainCameraView()
    }
}

struct MainCameraView: View {
    var body: some View {
        ZStack {
            // Background
            Color.brutalBackground
            
            VStack(spacing: 0) {
                // Camera Preview Area
                CameraPreviewView()
                
                // Bottom Control Bar
                BottomControlBar()
            }
        }
        .ignoresSafeArea()
    }
}

struct CameraPreviewView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview background
                Color.black
                
                // Placeholder text
                Text("CAMERA PREVIEW")
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(
                        Color.brutalBorder,
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [5, 5]
                        )
                    )
                    .shadow(color: .black, radius: 0, x: 4, y: 4)
            )
            .padding(10)
        }
    }
}

struct BottomControlBar: View {
    var body: some View {
        HStack(spacing: 40) {
            // Gallery Button
            ControlButton(icon: "photo", action: {
                // Gallery action
            })
            
            // Capture Button
            ControlButton(icon: "circle.fill", isCaptureButton: true, action: {
                // Capture action
            })
            
            // Filter Button
            ControlButton(icon: "camera.filters", action: {
                // Filter action
            })
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(Color.brutalMuted)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.brutalBorder),
            alignment: .top
        )
        .shadow(color: .black, radius: 0, x: 4, y: 4)
    }
}

struct ControlButton: View {
    var icon: String
    var isCaptureButton: Bool = false
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(isCaptureButton ? .brutalPrimaryForeground : .brutalForeground)
                .frame(width: isCaptureButton ? 80 : 70, height: isCaptureButton ? 80 : 70)
                .background(isCaptureButton ? Color.brutalPrimary : Color.brutalBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: isCaptureButton ? 40 : 35)
                        .stroke(Color.brutalBorder, lineWidth: 2)
                )
                .modifier(BrutalShadowModifier(isPressed: isPressed))
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct BrutalShadowModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        if isPressed {
            content
                .shadow(color: .black, radius: 0, x: 1, y: 1)
        } else {
            content
                .brutalShadow()
        }
    }
}

#Preview {
    MainCameraView()
}
