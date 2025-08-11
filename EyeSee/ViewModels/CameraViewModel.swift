//
//  CameraViewModel.swift
//  EyeSee
//
//  Created by chii_magnus on 2025/8/11.
//

import Foundation
import SwiftUI
import Combine

@Observable
class CameraViewModel {
    // 相机状态
    var isCapturing = false
    var currentFilter: String = "无滤镜"
    
    // 按钮交互状态
    var isGalleryButtonPressed = false
    var isCaptureButtonPressed = false
    var isFilterButtonPressed = false
    
    // 滤镜选项
    let filters = ["无滤镜", "狗狗视角", "猫咪视角", "鸟类视角"]
    
    // 拍照功能
    func capturePhoto() {
        isCapturing = true
        
        // 模拟拍照过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 拍照完成后重置状态
            self.isCapturing = false
        }
    }
    
    // 切换滤镜
    func switchFilter() {
        // 简单循环切换滤镜
        if let currentIndex = filters.firstIndex(of: currentFilter),
           currentIndex < filters.count - 1 {
            currentFilter = filters[currentIndex + 1]
        } else {
            currentFilter = filters[0]
        }
    }
    
    // 打开图库
    func openGallery() {
        // 图库功能实现
        print("打开图库")
    }
}