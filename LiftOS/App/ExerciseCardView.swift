import SwiftUI

public struct ExerciseCardView: View {
    public enum CardState: Equatable {
        case pending
        case active
        case done
    }

    // MARK: - Inputs
    public let name: String
    public let tags: [String]
    public let accentColor: Color
    @Binding public var weight: String
    @Binding public var reps: String
    public var isProvisionalWeight: Bool
    public var isProvisionalReps: Bool
    public var state: CardState

    public var onTap: (() -> Void)? = nil
    public var onMarkDone: (() -> Void)? = nil

    // MARK: - Init
    public init(
        name: String,
        tags: [String] = [],
        accentColor: Color,
        weight: Binding<String>,
        reps: Binding<String>,
        isProvisionalWeight: Bool = false,
        isProvisionalReps: Bool = false,
        state: CardState = .pending,
        onTap: (() -> Void)? = nil,
        onMarkDone: (() -> Void)? = nil
    ) {
        self.name = name
        self.tags = tags
        self.accentColor = accentColor
        self._weight = weight
        self._reps = reps
        self.isProvisionalWeight = isProvisionalWeight
        self.isProvisionalReps = isProvisionalReps
        self.state = state
        self.onTap = onTap
        self.onMarkDone = onMarkDone
    }

    // MARK: - Body
    public var body: some View {
        let accentOpacity: Double = {
            switch state {
            case .pending: return 0.20
            case .active: return 1.00
            case .done: return 0.20
            }
        }()

        ZStack(alignment: .leading) {
            // Card background with glassy styling
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)

            // Left accent bar
            Rectangle()
                .fill(accentColor.opacity(accentOpacity))
                .frame(width: 6)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 10) {
                header
                inputs
            }
            .padding(.vertical, 12)
            .padding(.leading, 22) // content inset + accent width
            .padding(.trailing, 12)
        }
        .overlay(doneOverlay)
        .scaleEffect(state == .active ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: state)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { onTap?() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), weight and reps")
        .accessibilityHint("Double-tap to edit. Swipe to mark set done.")
    }

    // MARK: - Subviews
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if state == .done {
                    ChipView(title: "All sets done", systemImage: "checkmark.seal.fill")
                }
            }
            if !tags.isEmpty {
                Text(tags.joined(separator: " • "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var inputs: some View {
        HStack(spacing: 10) {
            pillField(title: "Weight", text: $weight, isProvisional: isProvisionalWeight, keyboard: .decimalPad)
            pillField(title: "Reps", text: $reps, isProvisional: isProvisionalReps, keyboard: .numberPad)
            Spacer(minLength: 0)
            if state != .done {
                Button {
                    onMarkDone?()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark done")
            }
        }
    }

    private func pillField(title: String, text: Binding<String>, isProvisional: Bool, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .font(.title3.monospacedDigit())
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(isProvisional ? .secondary : .primary)
                .accessibilityLabel(title)
        }
    }

    @ViewBuilder
    private var doneOverlay: some View {
        if state == .done {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.green.opacity(0.10))
        }
    }
}

// MARK: - Chip View
fileprivate struct ChipView: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .imageScale(.small)
            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: Capsule())
        .foregroundStyle(.secondary)
    }
}
