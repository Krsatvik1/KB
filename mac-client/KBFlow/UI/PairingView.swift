import SwiftUI

/// Shown when the server requires a PIN to authorize a new Mac.
struct PairingView: View {
    @Binding var pin: String
    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.043, green: 0.059, blue: 0.102).ignoresSafeArea()

            VStack(spacing: 28) {
                // Logo glow decorator
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "00D4FF").opacity(0.35), .clear],
                                center: .center, startRadius: 0, endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                }

                VStack(spacing: 8) {
                    Text("New Device Pairing")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "E8EAF6"))
                    Text("Enter the 6-digit PIN shown on Windows")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6B7280"))
                }

                // PIN digit boxes
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        PINDigitBox(digit: $digits[i], isFocused: focusedIndex == i)
                            .focused($focusedIndex, equals: i)
                            .onChange(of: digits[i]) { oldValue, newValue in
                                if newValue.count > 1 {
                                    digits[i] = String(newValue.last!)
                                }
                                if !newValue.isEmpty && i < 5 {
                                    focusedIndex = i + 1
                                }
                                if digits.allSatisfy({ $0.count == 1 }) {
                                    let code = digits.joined()
                                    onSubmit(code)
                                }
                            }
                    }
                }

                HStack(spacing: 12) {
                    Button("Cancel") { onCancel() }
                        .buttonStyle(FlowDeskSecondaryButton())
                    Button("Pair") {
                        onSubmit(digits.joined())
                    }
                    .buttonStyle(FlowDeskPrimaryButton())
                    .disabled(digits.joined().count < 6)
                }
            }
            .padding(36)
            .frame(width: 400)
        }
        .onAppear { focusedIndex = 0 }
    }
}

private struct PINDigitBox: View {
    @Binding var digit: String
    var isFocused: Bool

    var body: some View {
        TextField("", text: $digit)
            .font(.system(size: 22, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "E8EAF6"))
            .multilineTextAlignment(.center)
            .frame(width: 44, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "111827"))
                    .shadow(color: Color(hex: "00D4FF").opacity(isFocused ? 0.5 : 0), radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isFocused ? Color(hex: "00D4FF") : Color(hex: "00D4FF").opacity(0.15),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
    }
}
