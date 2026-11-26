import UIKit

/// 封面加载 + 主色提取。主色决定整屏背景和唱片染色。
enum Artwork {
    private static let cache = NSCache<NSString, UIImage>()

    static func cached(_ url: URL?) -> UIImage? {
        guard let url else { return nil }
        return cache.object(forKey: url.absoluteString as NSString)
    }

    static func load(_ url: URL?, size: Int = 1000) async -> UIImage? {
        guard let url else { return nil }
        if let hit = cached(url) { return hit }
        do {
            var request = URLRequest(url: url)
            request.setValue(NetEase.userAgent, forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 20
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: url.absoluteString as NSString)
            return image
        } catch {
            return nil
        }
    }

    /// 平均色 → 提饱和提亮，得到截图里那种高纯度封面底色
    static func tint(from image: UIImage?) -> UIColor {
        guard let image else { return UIColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1) }
        let side: CGFloat = 1
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: side, height: side), true, 1)
        image.draw(in: rect)
        let tiny = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cg = tiny?.cgImage,
              let data = cg.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return .darkGray
        }
        let r = CGFloat(bytes[0]) / 255
        let g = CGFloat(bytes[1]) / 255
        let b = CGFloat(bytes[2]) / 255
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        var val: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(red: r, green: g, blue: b, alpha: 1).getHue(&hue, saturation: &sat, brightness: &val, alpha: &alpha)
        let boostedSat = min(1, sat * 1.25 + 0.10)
        let boostedVal = min(1, max(0.42, val * 1.05))
        return UIColor(hue: hue, saturation: boostedSat, brightness: boostedVal, alpha: 1)
    }

    /// 青/蓝类色反相太亮，测一下是不是深色封底，决定文字用白还是黑
    static func isLight(_ color: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.62
    }
}

/// 把封面做背景模糊墙用
extension UIImage {
    func blurred(radius: CGFloat) -> UIImage? {
        guard let cg = cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ci, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter?.outputImage else { return nil }
        let context = CIContext()
        guard let result = context.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: result)
    }
}
