import SwiftUI

/// Central palette and metrics for Racc's dark "club chassis" look:
/// a near-black cool-grey enclosure with one saturated accent per deck.
enum Theme {

    // MARK: Chassis

    /// Window background — the darkest surface.
    static let background = Color(hex: 0x0B0D10)
    /// Deck / module panels sitting on the background.
    static let panel = Color(hex: 0x15181D)
    /// Recessed areas: waveform display, fader slots.
    static let well = Color(hex: 0x0E1116)
    /// Raised controls: buttons, capsules.
    static let raised = Color(hex: 0x1E232A)
    /// Hairline separators and control outlines.
    static let stroke = Color(hex: 0x2A3038)

    // MARK: Text

    static let textPrimary = Color(hex: 0xE8ECF1)
    static let textSecondary = Color(hex: 0x8A94A3)
    static let textDim = Color(hex: 0x5A6472)

    // MARK: Accents

    /// Deck A — cyan.
    static let deckA = Color(hex: 0x22D3EE)
    /// Deck B — amber.
    static let deckB = Color(hex: 0xFF9F43)
    static let danger = Color(hex: 0xFF4D5E)

    /// `Controls` uses `backgroundColor` for both a knob's unfilled arc *and*
    /// its label, so this tone has to read as a subtle track and legible text.
    static let controlTrack = Color(hex: 0x6B7684)

    // MARK: Metrics

    static let panelCorner: CGFloat = 14
    static let controlCorner: CGFloat = 10
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension Font {
    /// Small all-caps label, as used for hardware legends.
    static func legend(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Building blocks

extension View {
    /// A module panel, faintly outlined in its accent color.
    func panelStyle(accent: Color) -> some View {
        background(
            RoundedRectangle(cornerRadius: Theme.panelCorner)
                .fill(Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelCorner)
                .strokeBorder(accent.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
    }

    /// A recessed display or slot.
    func wellStyle(cornerRadius: CGFloat = Theme.controlCorner) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.well)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// All-caps legend text above a control.
    func legendLabel() -> some View {
        font(.legend())
            .tracking(1.4)
            .foregroundStyle(Theme.textDim)
    }
}

/// Transport / utility button: dark capsule that lights up in the deck accent.
struct DeckButtonStyle: ButtonStyle {
    var accent: Color
    var isActive = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let tint = isActive ? accent : Theme.textPrimary

        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isEnabled ? tint : Theme.textDim)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? accent.opacity(0.18) : Theme.raised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isActive ? accent.opacity(0.7) : Theme.stroke,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isActive && isEnabled ? accent.opacity(0.35) : .clear,
                radius: 6
            )
            .opacity(configuration.isPressed ? 0.65 : 1)
            .animation(.easeOut(duration: 0.12), value: isActive)
    }
}

/// Small indicator lamp, e.g. deck playing state.
struct StatusLED: View {
    var color: Color
    var isOn: Bool

    var body: some View {
        Circle()
            .fill(isOn ? color : Theme.stroke)
            .frame(width: 8, height: 8)
            .shadow(color: isOn ? color.opacity(0.9) : .clear, radius: 5)
            .animation(.easeOut(duration: 0.15), value: isOn)
    }
}
