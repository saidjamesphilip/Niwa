import SwiftUI
import SwiftData

struct SoundsView: View {
    let soundManager: SoundManager
    let profileManager: UserProfileManager

    @State private var soundsEnabled: Bool = true
    @State private var volume: Double = 0.7

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Master toggle
                HStack {
                    Image(systemName: soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(soundsEnabled ? DesignTokens.Colors.primary : DesignTokens.Colors.textMuted)

                    Text("Sound Effects")
                        .font(DesignTokens.Typography.bodyFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Spacer()

                    Toggle("", isOn: $soundsEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(DesignTokens.Colors.primary)
                        .onChange(of: soundsEnabled) { _, newValue in
                            profileManager.profile?.soundsEnabled = newValue
                            profileManager.save()
                        }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)

                if soundsEnabled {
                    // Volume slider
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.Colors.textMuted)

                        Slider(value: $volume, in: 0...1, step: 0.05)
                            .tint(DesignTokens.Colors.primary)
                            .onChange(of: volume) { _, newValue in
                                soundManager.setVolume(newValue)
                            }

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.Colors.textMuted)

                        Text("\(Int(volume * 100))%")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(DesignTokens.Colors.textMuted)
                            .frame(width: 32, alignment: .trailing)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.sm)

                    Divider()
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    VStack(spacing: 2) {
                        ForEach(SoundEvent.allCases, id: \.rawValue) { event in
                            SoundEventRow(
                                event: event,
                                soundManager: soundManager
                            )
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            soundsEnabled = profileManager.profile?.soundsEnabled ?? true
            volume = profileManager.profile?.soundVolume ?? 0.7
        }
    }
}

private struct SoundEventRow: View {
    let event: SoundEvent
    let soundManager: SoundManager

    @State private var currentSound: String = ""
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: event.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .frame(width: 20)

                    Text(event.rawValue)
                        .font(DesignTokens.Typography.bodyFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Spacer()

                    Text(SoundEvent.displayName(for: currentSound))
                        .font(DesignTokens.Typography.captionFont)
                        .foregroundStyle(DesignTokens.Colors.textMuted)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded options
            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(event.options, id: \.self) { option in
                        Button {
                            currentSound = option
                            soundManager.setSound(for: event, to: option)
                            soundManager.preview(option)
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: currentSound == option ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(currentSound == option ? DesignTokens.Colors.primary : DesignTokens.Colors.textMuted)

                                Text(SoundEvent.displayName(for: option))
                                    .font(DesignTokens.Typography.bodyFont)
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                                Spacer()

                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, DesignTokens.Spacing.xs)
                .background(DesignTokens.Colors.backgroundSecondary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.bottom, DesignTokens.Spacing.xs)
            }
        }
        .onAppear {
            currentSound = soundManager.soundName(for: event)
        }
    }
}
