import Foundation
#if canImport(SwiftUI)
import SwiftUI

public extension Color {
    /// Convenience accessor for app asset colors.
    /// Usage: Color.app(.background_primary)
    static func app(_ color: AssetColors.AppColor, bundle: Bundle = .main) -> Color {
        AssetColors.color(color, bundle: bundle)
    }
}
#endif

#if canImport(UIKit)
import UIKit
public extension UIColor {
    /// Convenience accessor for app asset colors.
    /// Usage: UIColor.app(.background_primary)
    static func app(_ color: AssetColors.AppColor, bundle: Bundle = .main) -> UIColor {
        UIColor(named: color.rawValue, in: bundle, compatibleWith: nil) ?? UIColor.clear
    }
}
#endif

