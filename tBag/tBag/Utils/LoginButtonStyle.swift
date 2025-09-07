//
//  CapsuleButtonStyle.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//


import SwiftUI
import SwiftData

struct LoginButtonStyle: ButtonStyle {
        
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .font(.body.bold())
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.75 : 1)
            .animation(.spring, value: configuration.isPressed)
            .shadow(radius: 4)
            
    }
}
