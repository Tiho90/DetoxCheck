import SwiftUI

struct StartView: View {
    @StateObject private var viewModel = AssessmentViewModel()
    @State private var didStart = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "iphone.gen3")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("DetoxCheck")
                    .font(.largeTitle)
                    .bold()

                Text("Finde in wenigen Minuten heraus, wie stark dein Alltag vom Smartphone bestimmt wird, und erhalte passende Tipps für einen bewussteren Umgang.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

                if let last = viewModel.lastResult {
                    Text("Letztes Ergebnis: \(last.category.rawValue)")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    viewModel.loadQuestions()
                    didStart = true
                } label: {
                    Text("Test starten")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $didStart) {
                AssessmentView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    StartView()
}
