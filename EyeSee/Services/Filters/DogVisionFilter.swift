import CoreImage

/// 模拟狗狗视觉（主要是红绿色盲）的滤镜
final class DogVisionFilter {
    
    /// 应用狗狗视觉滤镜到 CIImage
    /// - Parameter inputImage: 输入的 CIImage
    /// - Returns: 应用滤镜后的 CIImage，如果失败则返回原图
    static func apply(to inputImage: CIImage) -> CIImage {
        // 狗狗的视锥细胞类型与人类不同，它们是二色视觉（dichromatic vision），
        // 主要对蓝色和黄色敏感，缺乏对红色和绿色敏感的视锥细胞。
        // 这导致它们看到的红色和绿色会显得比较暗淡，趋向于黄色或灰色。
        // 这里使用一个简化的颜色矩阵来近似模拟这种效果。
        // 参考来源（简化）：
        // 1. 将红色 (R) 和绿色通道 (G) 的信息混合，减弱其饱和度。
        // 2. 保留蓝色 (B) 通道信息。
        // 3. Alpha 通道 (A) 保持不变。
        // 颜色矩阵 (Column-Major order for Core Image):
        // [ R' ]   [ 0.625  0.375  0.0    0.0 ]   [ R ]
        // [ G' ] = [ 0.625  0.375  0.0    0.0 ] * [ G ]
        // [ B' ]   [ 0.0    0.0    1.0    0.0 ]   [ B ]
        // [ A' ]   [ 0.0    0.0    0.0    1.0 ]   [ A ]
        // Bias Vector: [ 0.0, 0.0, 0.0, 0.0 ]
        
        guard let filter = CIFilter(name: "CIColorMatrix") else {
            print("Failed to create CIColorMatrix filter")
            return inputImage
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        
        // 设置 R 通道输出向量 (R' = 0.625*R + 0.375*G)
        filter.setValue(CIVector(x: 0.625, y: 0.375, z: 0.0, w: 0.0), forKey: "inputRVector")
        // 设置 G 通道输出向量 (G' = 0.625*G + 0.375*R) - 这里为了简化，使用与R相同的混合
        filter.setValue(CIVector(x: 0.625, y: 0.375, z: 0.0, w: 0.0), forKey: "inputGVector")
        // 设置 B 通道输出向量 (B' = 1.0 * B)
        filter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0), forKey: "inputBVector")
        // 设置 A 通道输出向量 (A' = 1.0 * A)
        filter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0), forKey: "inputAVector")
        // 设置偏移向量 (无偏移)
        filter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputBiasVector")
        
        guard let outputImage = filter.outputImage else {
            print("Failed to get output image from CIColorMatrix filter")
            return inputImage
        }
        
        return outputImage
    }
}