//
//  Toast.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/20.
//

import SwiftUI

typealias DisplayToastAction = @MainActor (String) -> Void

struct DisplayToastkey: EnvironmentKey {
    static var defaultValue: DisplayToastAction? = nil
}

extension EnvironmentValues {
    var displayToast: DisplayToastAction? {
        get { self[DisplayToastkey.self] }
        set { self[DisplayToastkey.self] = newValue }
    }
}

@Observable
final class ToastHandler {
    @MainActor
    private(set) var currentToastMessage: String?

    @ObservationIgnored private var toastQueue: [String] = []
    @ObservationIgnored private var currentToastShowingTask: Task<Void, Never>?

    private var toastShowingDuration: Duration {
        .seconds(3)
    }

    private var defaultToastHidingDuration: Duration {
        .milliseconds(450)
    }

    @MainActor
    func queueMessage(_ message: String) {
        toastQueue.append(message)
        displayNextToastIfAvailable()
    }

    @MainActor
    func skipCurrent(in duration: Duration) {
        removeCurrentToast()
        Task {
            try? await Task.sleep(for: duration)
            displayNextToastIfAvailable()
        }
    }

    @MainActor
    private func displayNextToastIfAvailable() {
        guard currentToastMessage == nil, let message = toastQueue.first else { return }

        toastQueue.removeFirst()
        currentToastMessage = message

        currentToastShowingTask?.cancel()
        currentToastShowingTask = Task {
            do {
                try await Task.sleep(for: toastShowingDuration)
                if Task.isCancelled { return }
                skipCurrent(in: defaultToastHidingDuration)
            } catch {
                print("Toast error.")
            }
        }
    }

    @MainActor
    private func removeCurrentToast() {
        if currentToastMessage == nil {
            return
        }
        currentToastShowingTask?.cancel()
        currentToastMessage = nil
    }
}

struct ToastDisplayModifier<Toast: View>: ViewModifier {
    var alignment: Alignment
    var toastHandler: ToastHandler
    var toastMaker: (ToastHandler) -> Toast

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                toastMaker(toastHandler)
            }
            .environment(\.displayToast, toastHandler.queueMessage(_:))
    }
}

extension View {
    func displayToast<Toast: View>(
        on alignment: Alignment,
        handledBy toastHandler: ToastHandler,
        toastMaker: @escaping (ToastHandler) -> Toast
    ) -> some View {
        self.modifier(
            ToastDisplayModifier(
                alignment: alignment,
                toastHandler: toastHandler,
                toastMaker: toastMaker
            )
        )
    }
}

struct ToastView: View {
    var toastHandler: ToastHandler

    private var toastHidingDuration: Duration {
        .milliseconds(10)
    }

    var body: some View {
        Group {
            if let toastMessage = toastHandler.currentToastMessage {
                ToastDesign(toastMessage: toastMessage)
                    .transition(MoveTransition.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: toastHandler.currentToastMessage)
        .onTapGesture {
            toastHandler.skipCurrent(in: toastHidingDuration)
        }
    }
}

extension View {
    func displayToast(handledBy toastHandler: ToastHandler) -> some View {
        self.displayToast(
            on: .top,
            handledBy: toastHandler,
            toastMaker: { ToastView(toastHandler: $0) }
        )
    }
}

struct ToastDesign: View {
    var toastMessage: String
    var body: some View {
        ZStack {
            Label(toastMessage, systemImage: "info.bubble")
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .font(.headline)
                .foregroundColor(Color.accentText)
                .frame(alignment: .center)
        }
        .background(Color.accentColor)
        .cornerRadius(8)
        .shadow(radius: 1)
        .padding(.horizontal, 4)
    }
}


#Preview {
    ToastDesign(toastMessage: "Hello SwiftUI Toast !")
        .padding(20)
}
