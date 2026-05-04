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
    var openEnvelope: (_ sealedString : SealedEnvelopeBase64String ) -> PlainString
        
    var body: some View {
        VStack(alignment: .leading) {
            Text("History")
                .font(.headline)
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    let latest = history.max(by: { $0.updatedAt < $1.updatedAt })!
                    
                    ForEach(history.sorted(by: { $0.updatedAt > $1.updatedAt }), id: \.updatedAt) { history in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(makeLocalDateString(from: history.updatedAt))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                if latest.updatedAt == history.updatedAt {
                                    Text("← Current")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Text(openEnvelope(history.encryptedValue))
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
