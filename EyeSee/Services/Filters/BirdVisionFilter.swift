import CoreImage

/// 模拟鸟类视觉（更宽广的色域，可能包含紫外线）的滤镜
/// 注意：这是一个高度简化的模拟，真实鸟类视觉远比此复杂。
final class BirdVisionFilter {
    
    /// 应用鸟类视觉滤镜到 CIImage
    /// - Parameter inputImage: 输入的 CIImage
    /// - Returns: 应用滤镜后的 CIImage，如果失败则返回原图
    static func apply(to inputImage: CIImage) -> CIImage {
        // 许多鸟类拥有四色视觉，能看到紫外线(UV)，这使它们看到的世界色彩比人类丰富得多。
        // 它们对蓝色和紫外线非常敏感。
        // 这个滤镜尝试模拟：
        // 1. 增强蓝色通道。
        // 2. 增加整体饱和度，以体现更丰富的色彩。
        // 3. 微调红色和绿色通道。
        // 颜色矩阵 (Column-Major order for Core Image):
        // [ R' ]   [ 1.1  0.0  0.0  0.0 ]   [ R ]
        // [ G' ] = [ 0.0  1.0  0.0  0.0 ] * [ G ]
        // [ B' ]   [ 0.0  0.0  1.4  0.0 ]   [ B ]
        // [ A' ]   [ 0.0  0.0  0.0  1.0 ]   [ A ]
        // Bias Vector: [ 0.0, 0.0, 0.0, 0.0 ]
        
        guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else {
            print("Failed to create CIColorMatrix filter for Bird Vision")
            return inputImage
        }
        
        colorMatrixFilter.setValue(inputImage, forKey: kCIInputImageKey)
        
        // 设置 R 通道输出向量 (R' = 1.1 * R) - 略微增强红色
        colorMatrixFilter.setValue(CIVector(x: 1.1, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
        // 设置 G 通道输出向量 (G' = 1.0 * G) - 保持绿色通道
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0), forKey: "inputGVector")
        // 设置 B 通道输出向量 (B' = 1.4 * B) - 显著增强蓝色
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.4, w: 0.0), forKey: "inputBVector")
        // 设置 A 通道输出向量 (A' = 1.0 * A)
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0), forKey: "inputAVector")
        // 设置偏移向量 (无偏移)
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputBiasVector")
        
        guard let colorMatrixOutput = colorMatrixFilter.outputImage else {
            print("Failed to get output image from CIColorMatrix filter for Bird Vision")
            return inputImage
        }
        
        // 添加饱和度滤镜以增强视觉效果
        guard let saturationFilter = CIFilter(name: "CIColorControls") else {
            print("Failed to create CIColorControls filter for Bird Vision")
            return colorMatrixOutput // Return the color matrix result even if saturation fails
        }
        
        saturationFilter.setValue(colorMatrixOutput, forKey: kCIInputImageKey)
        // 保持对比度不变
        saturationFilter.setValue(1.0, forKey: kCIInputContrastKey)
        // 保持亮度不变
        saturationFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
        // 增加饱和度
        saturationFilter.setValue(1.3, forKey: kCIInputSaturationKey)
        
        guard let finalOutput = saturationFilter.outputImage else {
            print("Failed to get output image from CIColorControls filter for Bird Vision")
            return colorMatrixOutput // Return the color matrix result
        }
        
        return finalOutput
    }
}