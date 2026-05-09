//
//  ScrollLetter.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-02-16.
//

import SwiftUI
import SwiftData

struct SideListTapScrollView: View {
    let firstLetter: String
    let proxy: ScrollViewProxy

    @State var isHover = false
    
    var body: some View {
        Text(firstLetter)
#if os(iOS)
            .font(.custom("Menlo", size: 18))
#else
            .font(.custom("Menlo", size: 12))
#endif
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .foregroundColor(isHover ?  Color.accentText :  Color.accentColor)
            .background(isHover ? Color.accentColor :  Color.clear)
            .offset(x: isHover ? -4 : 0, y: 0)
            .animation(.easeInOut(duration: 0.2), value: isHover)
            .onHover { isHover in
                withAnimation {
                    self.isHover = isHover
                }
            }
            .onTapGesture {
                withAnimation {
                    proxy.scrollTo(firstLetter, anchor: .top)
                }
            }
    }
}
