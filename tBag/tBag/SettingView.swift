//
//  SettingView.swift
//  Arenavi
//
//  Created by Manabu Tonosaki on 2025/05/05.
//

#if os(macOS)
    import SwiftData
    import SwiftUI

    struct SettingView: View {
        @AppStorage("isResetLocalDataAtNextLaunch") private var isResetLocalDataAtNextLaunch = false
        @AppStorage("latestAccountId") private var latestAccountId = ""
        @State private var tabPage: Int = 1

        var body: some View {
            TabView(selection: $tabPage) {
                VStack(alignment: .leading) {
                    Text("Setting.tab.general")
                }
                .tabItem {
                    Label("Setting.tab.general", systemImage: "gear")
                }
                .tag(1)
                .navigationTitle("Arenavi")
                .navigationSubtitle("Setting.tab.general")
                .padding(16)

                VStack {
                    GroupBox("Setting.title.data") {
                        HStack {
                            Label("Setting.resetForNextLaunch", systemImage: "info.circle")
                            Spacer()
                            Button {
                                isResetLocalDataAtNextLaunch = true
                            } label: {
                                Text("Setting.resetForNextLaunch.exec")
                            }
                        }.padding(16)
                    }
                    Spacer()
                }
                .tabItem {
                    Label("Setting.tab.advanced", systemImage: "star")
                }
                .tag(2)
                .navigationTitle("Arenavi")
                .navigationSubtitle("Setting.tab.advanced")
                .padding(16)
            }
            .tabViewStyle(.tabBarOnly)
            .frame(width: 400, alignment: .topLeading)
            .onAppear {
                tabPage = 1
            }
        }
    }

    #Preview {
        SettingView()
    }

#endif
