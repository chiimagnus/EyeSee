import SwiftUI
import SwiftData

@Observable
class CameraViewModel {
    // MARK: - State
    var isCaptureButtonPressed = false
    var isFilterButtonPressed = false
    var isGalleryButtonPressed = false
    
    // MARK: - Actions
    func capturePhoto() {
        // 模拟拍照效果
        print("Capturing photo...")
        // 这里可以添加实际的拍照逻辑
    }
    
    func switchFilter() {
        // 切换滤镜
        print("Switching filter...")
        // 这里可以添加滤镜切换逻辑
    }
    
    func openGallery() {
        // 打开相册
        print("Opening gallery...")
        // 这里可以添加打开相册的逻辑
    }
    
    // MARK: - Button Press Handling
    func captureButtonPressed() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isCaptureButtonPressed = true
        }
    }
    
    func captureButtonReleased() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isCaptureButtonPressed = false
        }
        capturePhoto()
    }
    
    func filterButtonPressed() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isFilterButtonPressed = true
        }
    }
    
    func filterButtonReleased() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isFilterButtonPressed = false
        }
        switchFilter()
    }
    
    func galleryButtonPressed() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isGalleryButtonPressed = true
        }
    }
    
    func galleryButtonReleased() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isGalleryButtonPressed = false
        }
        openGallery()
    }
}

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
    @State private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.brutalBackground
            
            VStack(spacing: 0) {
                // Camera Preview Area
                CameraPreviewView()
                
                // Bottom Control Bar
                BottomControlBar(viewModel: viewModel)
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
    @Bindable var viewModel: CameraViewModel
    
    var body: some View {
        HStack(spacing: 40) {
            // Gallery Button
            ControlButton(
                icon: "photo",
                isPressed: viewModel.isGalleryButtonPressed,
                onPressed: viewModel.galleryButtonPressed,
                onReleased: viewModel.galleryButtonReleased
            )
            
            // Capture Button
            ControlButton(
                icon: "circle.fill",
                isCaptureButton: true,
                isPressed: viewModel.isCaptureButtonPressed,
                onPressed: viewModel.captureButtonPressed,
                onReleased: viewModel.captureButtonReleased
            )
            
            // Filter Button
            ControlButton(
                icon: "camera.filters",
                isPressed: viewModel.isFilterButtonPressed,
                onPressed: viewModel.filterButtonPressed,
                onReleased: viewModel.filterButtonReleased
            )
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
    var isPressed: Bool = false
    var onPressed: () -> Void = {}
    var onReleased: () -> Void = {}
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(isCaptureButton ? .brutalPrimaryForeground : .brutalForeground)
                .frame(width: isCaptureButton ? 80 : 70, height: isCaptureButton ? 80 : 70)
                .background(isCaptureButton ? Color.brutalPrimary : Color.brutalBackground)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.brutalBorder, lineWidth: 2)
                )
                .modifier(BrutalShadowModifier(isPressed: isPressed))
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPressed()
                }
                .onEnded { _ in
                    onReleased()
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
