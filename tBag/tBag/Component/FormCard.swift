//
//  Card.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/21.
//

import SwiftUI
import Tono

struct FormCard<Content: View>: View {
    @Environment(\.displayToast) var toast
    @Binding var history: [AttributeData]?
    @State private var isShowingHistory = false

    let text: String
    let systemImage: String
    let content: Content
    var copyText: () -> String? = { nil }
    var openEnvelope: (_ sealedString: SealedEnvelopeBase64String) -> PlainString = { _ in "" }

    init(
        _ text: String,
        systemImage: String,
        history: Binding<[AttributeData]?>,
        @ViewBuilder content: () -> Content,
        copyText: @escaping () -> String?,
        openEnvelope: @escaping (_ sealedString: SealedEnvelopeBase64String) -> PlainString
    ) {
        self.text = text
        self.systemImage = systemImage
        self.content = content()
        self.copyText = copyText
        self._history = history
        self.openEnvelope = openEnvelope
    }

    init(
        _ text: String,
        systemImage: String,
        history: Binding<[AttributeData]?>,
        @ViewBuilder content: () -> Content,
        openEnvelope: @escaping (_ sealedString: SealedEnvelopeBase64String) -> PlainString
    ) {
        self.init(text, systemImage: systemImage, history: history, content: content, copyText: {nil}, openEnvelope: openEnvelope)
    }

    init(_ text: String, systemImage: String, @ViewBuilder content: () -> Content, copyText: @escaping () -> String?) {
        self.init(text, systemImage: systemImage, history: .constant([]), content: content, copyText: copyText, openEnvelope: {_ in ""})
    }

    init(_ text: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.init(text, systemImage: systemImage, history: .constant([]), content: content, copyText: {nil}, openEnvelope: {_ in ""})
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Label(text, systemImage: systemImage)
                        .font(.caption)
                        .foregroundColor(.secondary)
 
                    Spacer()
                    historyButton(history: history)
                    copyButton()
                }
                content
            }
            .padding()
        }
        .background(.bgColorPasswordCard)
        .cornerRadius(8)
        .shadow(radius: 1.5)
    }

    @ViewBuilder
    private func copyButton() -> some View {
        if let copyText = copyText() {
            if !copyText.isEmpty {
                Button {
#if os(iOS)
                    UIPasteboard.general.string = copyText
#elseif os(macOS)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(copyText, forType: .string)
#endif
                    toast?("Copy \(text)")
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
                .padding(.leading, 24)
                .font(.caption)
                .foregroundColor(.secondary)
#if os(macOS)
                .buttonStyle(.plain)
#endif
            }
        }
    }
    
    @ViewBuilder
    private func historyButton(history: [AttributeData]?) -> some View {
        if let history = history, history.count > 0 {
            Button {
                isShowingHistory = true
            } label: {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .overlay(alignment: .bottomTrailing) {
                        HistoryBadge(count: .constant(history.count))
                    }
            }
            .font(.caption)
            .foregroundColor(.secondary)
#if os(macOS)
            .buttonStyle(.plain)
#endif
            .sheet(isPresented: $isShowingHistory) {
                ZStack(alignment: .topTrailing) {
                    HistoryView(history: history) { sealedString in
                        openEnvelope(sealedString)
                    }
                    .frame(minWidth: 400)
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    Button {
                        isShowingHistory = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                    .padding()
#if os(macOS)
                    .buttonStyle(.plain)
#endif
                }
                .presentationDetents([.medium, .large])
                
            }
        }
    }
}

#Preview {
    @Previewable @State var text: String = "test text"
    @Previewable @State var history: [AttributeData]? = [
        AttributeData(createdAt: Date(), encryptedValue: "(encrypted-no1)"),
        AttributeData(createdAt: Date(), encryptedValue: "(encrypted-no2)")
    ]
    FormCard("HOGE", systemImage: "info.circle", history: $history) {
        TextField("input here", text: $text)
    } copyText: {
        return text
    } openEnvelope: { sealedValue in
        return "hoge-\(sealedValue)"
    }
        .padding()
}
