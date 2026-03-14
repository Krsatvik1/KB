import SwiftUI
import AppKit

/// Design tokens matched to the FlowDesk logo palette.
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Button Styles

struct FlowDeskPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .background(
                LinearGradient(
                    colors: [Color(hex: "00D4FF"), Color(hex: "7B5CF0"), Color(hex: "B24BF3")],
                    startPoint: .leading, endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color(hex: "00D4FF").opacity(0.4), radius: configuration.isPressed ? 2 : 8, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FlowDeskSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(hex: "6B7280"))
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .background(Color(hex: "111827"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(hex: "00D4FF").opacity(0.15), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Glow Text Field

struct FlowDeskTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: String = "default"

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(Color(hex: "E8EAF6"))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(hex: "111827"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(hex: "00D4FF").opacity(0.2), lineWidth: 1)
            )
    }
}
