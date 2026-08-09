import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result = viewModel.result {
                    Text(result.category.rawValue)
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 32)

                    Text("\(result.totalScore) von \(result.maxPossibleScore) Punkten")
                        .foregroundStyle(.secondary)

                    Text(result.category.tip)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if !result.reflectionAnswers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deine Gedanken dazu")
                                .font(.headline)
                            ForEach(result.reflectionAnswers, id: \.self) { answer in
                                Text("„\(answer)“")
                                    .italic()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    }

                    if let last = viewModel.lastResult, last != result {
                        Text("Letztes Mal: \(last.category.rawValue) → Jetzt: \(result.category.rawValue)")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                    }

                    Button {
                        viewModel.restart()
                        dismiss()
                    } label: {
                        Text("Nochmal starten")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
