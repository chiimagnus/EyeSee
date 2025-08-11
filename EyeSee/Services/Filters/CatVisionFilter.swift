import CoreImage

/// 模拟猫咪视觉（强化暗光，可能对蓝色更敏感）的滤镜
final class CatVisionFilter {
    
    /// 应用猫咪视觉滤镜到 CIImage
    /// - Parameter inputImage: 输入的 CIImage
    /// - Returns: 应用滤镜后的 CIImage，如果失败则返回原图
    static func apply(to inputImage: CIImage) -> CIImage {
        // 猫咪的视网膜中视杆细胞（负责暗光视觉）非常丰富，这使它们在低光环境下视力极佳。
        // 它们是三色视觉，但与人类不同，对蓝色光谱更敏感。
        // 这个滤镜将尝试模拟：
        // 1. 增强蓝色通道。
        // 2. 降低红色通道的强度，使其在暗光下不那么突出。
        // 3. 微调绿色通道。
        // 4. 增加整体对比度以模拟夜视的清晰感。
        // 颜色矩阵 (Column-Major order for Core Image):
        // [ R' ]   [ 0.7  0.0  0.0  0.0 ]   [ R ]
        // [ G' ] = [ 0.0  0.8  0.0  0.0 ] * [ G ]
        // [ B' ]   [ 0.0  0.0  1.3  0.0 ]   [ B ]
        // [ A' ]   [ 0.0  0.0  0.0  1.0 ]   [ A ]
        // Bias Vector: [ 0.0, 0.0, 0.0, 0.0 ]
        
        guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else {
            print("Failed to create CIColorMatrix filter for Cat Vision")
            return inputImage
        }
        
        colorMatrixFilter.setValue(inputImage, forKey: kCIInputImageKey)
        
        // 设置 R 通道输出向量 (R' = 0.7 * R)
        colorMatrixFilter.setValue(CIVector(x: 0.7, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
        // 设置 G 通道输出向量 (G' = 0.8 * G)
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.8, z: 0.0, w: 0.0), forKey: "inputGVector")
        // 设置 B 通道输出向量 (B' = 1.3 * B)
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.3, w: 0.0), forKey: "inputBVector")
        // 设置 A 通道输出向量 (A' = 1.0 * A)
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0), forKey: "inputAVector")
        // 设置偏移向量 (无偏移)
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputBiasVector")
        
        guard let colorMatrixOutput = colorMatrixFilter.outputImage else {
            print("Failed to get output image from CIColorMatrix filter for Cat Vision")
            return inputImage
        }
        
        // 添加对比度滤镜以增强视觉效果
        guard let contrastFilter = CIFilter(name: "CIColorControls") else {
            print("Failed to create CIColorControls filter for Cat Vision")
            return colorMatrixOutput // Return the color matrix result even if contrast fails
        }
        
        contrastFilter.setValue(colorMatrixOutput, forKey: kCIInputImageKey)
        // 增加一点对比度
        contrastFilter.setValue(1.1, forKey: kCIInputContrastKey)
        // 保持亮度不变
        contrastFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
        // 保持饱和度不变
        contrastFilter.setValue(1.0, forKey: kCIInputSaturationKey)
        
        guard let finalOutput = contrastFilter.outputImage else {
            print("Failed to get output image from CIColorControls filter for Cat Vision")
            return colorMatrixOutput // Return the color matrix result
        }
        
        return finalOutput
    }
}