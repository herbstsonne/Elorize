import Foundation

/// Type-safe list of color assets available in the project.
/// These cases must match the names of your Color assets in Assets.xcassets exactly.
public enum AppColor: String, CaseIterable {
	case accent_default
	case accent_pressed
	case accent_subtle
	case background_primary
	case background_secondary
	case button_default
	case button_pressed
	case card_background_front
  case card_background_back
	case error
	case gold_primary
	case success
	case text_highlight
	case text_placeholder
	case text_primary
	case text_secondary
	case warning
}
