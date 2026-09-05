import SwiftUI

struct ShrinkButtonStyle: ButtonStyle {
    var shrinkAmount: CGFloat = 0.92
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? shrinkAmount : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
