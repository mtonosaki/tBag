//
//  AboutView.swift
//  Arenavi
//
//  Created by Manabu Tonosaki on 2025/05/04.
//

import SwiftUI

struct AboutVew: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("Banner")
                .resizable()
                .scaledToFit()

            Text("Version \(Info.version)   Build \(Info.build)")
                .font(.caption)
                .padding()
        }
    }
}

#Preview {
    AboutVew()
        #if os(macOS)
            .frame(width: 640, height: 320)
        #endif
}
