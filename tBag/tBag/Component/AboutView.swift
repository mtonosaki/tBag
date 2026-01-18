//
//  AboutView.swift
//  Arenavi
//
//  Created by Manabu Tonosaki on 2025/05/04.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("Banner")
                .resizable()
                .scaledToFit()
            
            let versionBuildText = "Version " + String(describing: Info.version) + "   Build " + String(describing: Info.build)
            Text(verbatim: versionBuildText)
                .font(.caption)
                .padding()
        }
    }
}

#Preview {
    AboutView()
        #if os(macOS)
            .frame(width: 640, height: 320)
        #endif
}
