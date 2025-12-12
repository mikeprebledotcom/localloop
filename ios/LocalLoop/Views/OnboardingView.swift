import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome
            WelcomePage()
                .tag(0)

            // Page 2: How it works
            HowItWorksPage()
                .tag(1)

            // Page 3: Legal disclaimer
            LegalDisclaimerPage(hasCompletedOnboarding: $hasCompletedOnboarding)
                .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to Local Loop")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your personal voice diary")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 16) {
                FeatureRow(
                    icon: "mic.fill",
                    title: "Continuous Recording",
                    description: "Capture your thoughts throughout the day"
                )

                FeatureRow(
                    icon: "icloud.and.arrow.up",
                    title: "Automatic Backup",
                    description: "Recordings sync to your Google Drive"
                )

                FeatureRow(
                    icon: "doc.text",
                    title: "AI Transcription",
                    description: "Convert speech to searchable text"
                )
            }
            .padding(.horizontal)

            Spacer()

            Text("Swipe to continue")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding()
    }
}

struct HowItWorksPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How It Works")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            VStack(alignment: .leading, spacing: 32) {
                StepRow(
                    number: "1",
                    title: "Record",
                    description: "Press the button to start recording. Audio is saved in 10-minute chunks."
                )

                StepRow(
                    number: "2",
                    title: "Upload",
                    description: "Chunks automatically upload to your Google Drive when on WiFi."
                )

                StepRow(
                    number: "3",
                    title: "Transcribe",
                    description: "A script on your Mac downloads and transcribes the audio daily."
                )

                StepRow(
                    number: "4",
                    title: "Review",
                    description: "Transcripts are saved as Markdown files in your notes app."
                )
            }
            .padding(.horizontal)

            Spacer()

            Text("Swipe to continue")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding()
    }
}

struct LegalDisclaimerPage: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var hasAccepted = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Important Notice")
                .font(.largeTitle)
                .fontWeight(.bold)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recording Laws")
                        .font(.headline)

                    Text("Recording conversations may be subject to local laws. Many jurisdictions require consent from all parties being recorded.")
                        .foregroundStyle(.secondary)

                    Text("This app is designed for personal voice memos - recording your own thoughts and ideas. If you record conversations with others, you are responsible for obtaining appropriate consent.")
                        .foregroundStyle(.secondary)

                    Text("Data Storage")
                        .font(.headline)
                        .padding(.top)

                    Text("Your recordings are stored in your personal Google Drive account and processed by Google's Gemini API for transcription. You maintain control of your data.")
                        .foregroundStyle(.secondary)

                    Text("By using this app, you acknowledge that you understand these terms and accept full responsibility for compliance with applicable laws.")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                }
            }
            .frame(maxHeight: 300)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Toggle(isOn: $hasAccepted) {
                Text("I understand and accept these terms")
                    .font(.subheadline)
            }
            .padding(.horizontal)

            Button {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                hasCompletedOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hasAccepted ? Color.blue : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!hasAccepted)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct StepRow: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
