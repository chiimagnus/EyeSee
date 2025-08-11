import CoreImage

/// 一个用于管理和应用不同动物视觉滤镜的服务
final class AnimalVisionFilterService {
    
    enum AnimalFilterType: String, CaseIterable {
        case none = "无滤镜"
        case dog = "狗狗视角"
        case cat = "猫咪视角"
        case bird = "鸟类视角"
        // TODO: 添加更多动物滤镜，如 "蜜蜂视角"
    }
    
    /// 根据指定的动物类型应用滤镜
    /// - Parameters:
    ///   - image: 输入的 CIImage
    ///   - type: 要应用的动物滤镜类型
    /// - Returns: 应用滤镜后的 CIImage
    static func applyFilter(to image: CIImage, type: AnimalFilterType) -> CIImage {
        switch type {
        case .none:
            return image
        case .dog:
            return DogVisionFilter.apply(to: image)
        case .cat:
            return CatVisionFilter.apply(to: image)
        case .bird:
            return BirdVisionFilter.apply(to: image)
        }
    }
}