import SwiftUI

struct AssessmentView: View {
    @ObservedObject var viewModel: AssessmentViewModel

    var body: some View {
        VStack(spacing: 24) {
            if let error = viewModel.loadError {
                errorView(error)
            } else if let question = viewModel.currentQuestion {
                ProgressView(value: viewModel.progress)
                    .padding(.horizontal)

                Text(question.text)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                questionInput(for: question)

                Spacer()

                Button {
                    viewModel.submitCurrentAnswer()
                } label: {
                    Text(isLastQuestion ? "Ergebnis anzeigen" : "Weiter")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.blue : Color.gray.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSubmit)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            } else {
                ProgressView("Lade Fragen …")
            }
        }
        .navigationDestination(isPresented: $viewModel.isFinished) {
            ResultView(viewModel: viewModel)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Eingabe je nach Fragetyp

    @ViewBuilder
    private func questionInput(for question: Question) -> some View {
        switch question.type {
        case .choice:
            VStack(spacing: 12) {
                ForEach(question.options ?? []) { option in
                    Button {
                        viewModel.selectedOptionID = option.id
                    } label: {
                        Text(option.text)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                viewModel.selectedOptionID == option.id
                                    ? Color.blue.opacity(0.85)
                                    : Color.gray.opacity(0.15)
                            )
                            .foregroundStyle(
                                viewModel.selectedOptionID == option.id ? .white : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal, 24)

        case .slider:
            VStack(spacing: 12) {
                Text("\(Int(viewModel.sliderValue)) \(question.sliderUnit ?? "")")
                    .font(.headline)
                Slider(
                    value: $viewModel.sliderValue,
                    in: (question.sliderMin ?? 0)...(question.sliderMax ?? 1),
                    step: question.sliderStep ?? 1
                )
            }
            .padding(.horizontal, 32)

        case .text:
            TextField("Deine Antwort …", text: $viewModel.textAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .padding(.horizontal, 24)
        }
    }

    private func errorView(_ error: AssessmentError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error.errorDescription ?? "Unbekannter Fehler")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var isLastQuestion: Bool {
        viewModel.currentIndex == viewModel.questions.count - 1
    }

    /// Steuert, ob der "Weiter"-Button aktiv ist: Auswahl- und Slider-Fragen benötigen
    /// zwingend eine Eingabe, Textfragen sind optional (Reflexion, keine Wertung).
    private var canSubmit: Bool {
        guard let question = viewModel.currentQuestion else { return false }
        switch question.type {
        case .choice:
            return viewModel.selectedOptionID != nil
        case .slider:
            return true
        case .text:
            return true
        }
    }
}
