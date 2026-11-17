import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Hands-busy cooking: one large step per page, swipe or tap to move on.
struct CookView: View {
    @State private var viewModel: CookViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CookViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressView(viewModel.progressLabel, value: viewModel.progress)
                    .font(.headline)
                    .tint(.primary)
                pages
                HStack {
                    Button("Back", systemImage: "chevron.left") {
                        withAnimation { viewModel.previous() }
                    }
                    .disabled(!viewModel.canGoBack)
                    Spacer()
                    if viewModel.isDone {
                        Button("Finish", systemImage: "checkmark") { dismiss() }
                            .buttonStyle(.primary)
                            .frame(maxWidth: 160)
                    } else {
                        Button("Next", systemImage: "chevron.right") {
                            withAnimation { viewModel.next() }
                        }
                        .buttonStyle(.primary)
                        .frame(maxWidth: 160)
                    }
                }
                .controlSize(.large)
                .font(.title3)
            }
            .padding()
            .navigationTitle(viewModel.title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close", systemImage: "xmark") { dismiss() }
            }
        }
        .onAppear { setScreenStaysAwake(true) }
        .onDisappear { setScreenStaysAwake(false) }
    }

    private var pages: some View {
        TabView(selection: $viewModel.page) {
            ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                ScrollView {
                    Text(step)
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tag(index)
            }
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("Enjoy your meal!").font(.largeTitle).bold()
            }
            .tag(viewModel.steps.count)
        }
        #if !os(macOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    private func setScreenStaysAwake(_ awake: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = awake
        #endif
    }
}

#Preview {
    CookView(viewModel: CookViewModel(
        title: "Spinach & Tomato Omelette",
        steps: ["Whisk the eggs.", "Sauté spinach and tomato.", "Add eggs and cook."]
    ))
}
