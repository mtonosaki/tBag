//
//  IconView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-02-07.
//

import SwiftUI

struct IconView: View {
    @Bindable var item: Item
    @State private var icon: Image = Image(.no)
    
    init(_ item: Item) {
        self.item = item
    }
    var body: some View {
        icon
            .resizable()
            .scaledToFit()
            .onChange(of: item.iconFileName) { _, newValue in
                guard let iconFileName = newValue else { return }
                guard let image = LocalImageStore.loadImage(folder: .icons, fileName: iconFileName) else { return }

                self.icon = image
            }
            .onAppear {
                if let iconFileName = item.iconFileName, let image = LocalImageStore.loadImage(folder: .icons, fileName: iconFileName) {
                    self.icon = image
                }
    }}
}
