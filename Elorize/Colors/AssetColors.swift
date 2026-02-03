import Foundation
#if canImport(SwiftUI)
import SwiftUI

public struct AssetColors {
    public typealias AppColor = Elorize.AppColor

    @inlinable
    public static func color(_ color: AppColor, bundle: Bundle = .main) -> Color {
        Color(color.rawValue, bundle: bundle)
    }
}
#endif

