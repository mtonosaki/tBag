//
//  Card.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/21.
//


import SwiftUI

struct FormCard<Content: View>: View {
    @Environment(\.displayToast) var toast

    let text: String
    let systemImage: String
    let content: Content
    var copyText: () -> String? = { nil }
    
    init(_ text: String, systemImage: String, copyText: @escaping () -> String?, @ViewBuilder content: () -> Content) {
        self.text = text
        self.systemImage = systemImage
        self.content = content()
        self.copyText = copyText
    }
    
    init(_ text: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.text = text
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading){
                HStack {
                    Label(text, systemImage: systemImage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        if let copyText = copyText() {
                            UIPasteboard.general.string = copyText
                            toast?("Copy \(text)")
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                content
            }
            .padding()
        }
        .background(.bgColorPasswordCard)
        .cornerRadius(8)
        .shadow(radius: 1.5)
    }
}

#Preview {
    @Previewable @State var text: String = "test text"
    FormCard("HOGE", systemImage: "info.circle", copyText: { return text }){
        TextField("input here", text: $text)
    }.padding()
}
