import SwiftUI

/// Typografie-Tokens mit Dynamic Type (system scales).
enum TRTypography {
    static func heroTitle() -> Font {
        .largeTitle.weight(.bold)
    }

    static func title() -> Font {
        .title.weight(.bold)
    }

    static func title2() -> Font {
        .title2.weight(.semibold)
    }

    static func headline() -> Font {
        .headline
    }

    static func body() -> Font {
        .body
    }

    static func bodyBold() -> Font {
        .body.weight(.semibold)
    }

    static func callout() -> Font {
        .callout
    }

    static func subheadline() -> Font {
        .subheadline
    }

    static func caption() -> Font {
        .caption
    }

    static func captionSmall() -> Font {
        .caption2
    }
}
