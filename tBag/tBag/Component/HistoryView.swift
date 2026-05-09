//
//  HistoryView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026/04/30.
//

import SwiftUI
import Tono

struct HistoryView: View {
    var history: [AttributeData]
    var openEnvelope: (_ sealedString: SealedEnvelopeBase64String ) -> PlainString
    
    init(history: [AttributeData]? = nil, openEnvelope: @escaping (_: SealedEnvelopeBase64String) -> PlainString) {
        if history == nil {
            self.history = []
        } else {
            self.history = history!
        }
        self.openEnvelope = openEnvelope
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("History")
                .font(.headline)
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    let sortedHistory = history.sorted(by: { $0.updatedAt > $1.updatedAt })
                    
                    ForEach(Array(sortedHistory.enumerated()), id: \.element.updatedAt) { index, item in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("No.\(sortedHistory.count - index)")
                                    .font(.system(size: 9.0, weight: .thin))
                                    .foregroundColor(.gray)
                                    .frame(width: 24, alignment: .leading)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .padding(.bottom, 1)
                                
                                Text(makeLocalDateString(from: item.updatedAt))
                                    .font(.body.monospaced())
                                    .foregroundColor(.gray)
                                
                                if index == 0 {
                                    Text("← Current")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Text(openEnvelope(item.encryptedValue))
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                            
                            if index < sortedHistory.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct HistoryBadge: View {
    @Binding var count: Int
        
    var body: some View {
        Text("\(count)")
            .font(.system(size: 8))
            .foregroundColor(.white)
            .padding(2)
            .background(.gray)
            .clipShape(Circle())
            .offset(x: 6, y: -6)
    }
}

func makeLocalDateString(from date: Date) -> String {
    var style = Date.ISO8601FormatStyle()
    style.timeZone = TimeZone.current
    return date.formatted(style)
}

#Preview {
    let shortText = "dummy"
    let mediumText = """
    hoge = 1
    fuga = 2
    piyo = 3
    poki = 4
    """
    let longText = """
    これは、SwiftUIでのレイアウト確認や、テキスト選択の動作をテストするためのプレビュー用文章です。アプリ開発において、読みやすい文字サイズや行間、適切な余白を確認することは、快適な操作性を提供するために重要です。
    
    特にシートやモーダルといった画面では、スワイプ操作との競合により、文字がコピーできない不具合が起こる場合があります。このように長めのテキストを配置して、意図通りに選択できるか検証しましょう。
    """

    let formatter = ISO8601DateFormatter()
    HistoryView(history: [
        AttributeData(createdAt: formatter.date(from: "2025-05-01T12:00:00Z")!, encryptedValue: mediumText),
        AttributeData(createdAt: formatter.date(from: "2025-05-02T12:00:00Z")!, encryptedValue: longText),
        AttributeData(createdAt: formatter.date(from: "2025-05-03T12:00:00Z")!, encryptedValue: shortText)
    ]) { sealedValue in
        return sealedValue
    }
    .padding()
}
