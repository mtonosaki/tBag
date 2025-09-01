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
        @State private var confirmResetLocalData: Bool = false

        var body: some View {
            TabView(selection: $tabPage) {
                VStack(alignment: .leading) {
                    GroupBox("Account") {
                        HStack {
                            Label("User ID", systemImage: "info.circle")
                            Spacer()
                            Button {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(latestAccountId, forType: .string)

                            } label: {
                                Text(latestAccountId)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding()
                    Spacer()
                }
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(1)
                .navigationTitle("Arenavi")
                .navigationSubtitle("General")
                .padding(16)

                VStack {
                    GroupBox("Data (dangerous zone)") {
                        HStack {
                            Label("Reset for next launch", systemImage: "info.circle")
                            Spacer()
                            Button {
                                confirmResetLocalData = true
                            } label: {
                                Text("Reset now")
                            }
                        }
                        .alert(isPresented: $confirmResetLocalData, content: {
                            return Alert(
                                title: Text("Confirm"),
                                message: Text("Your data on all devices will be deleted immediately. This operation cannot be undo. Do you sill want to reset?"),
                                primaryButton: .destructive(Text("RESET"), action: {
                                    isResetLocalDataAtNextLaunch = true
                                    exit(0)
                                }),
                                secondaryButton: .default(Text("Cancel"), action: {
                                    isResetLocalDataAtNextLaunch = false
                                    confirmResetLocalData = false
                                })
                            )
                        })
                    }
                    .background(Color(.pink))
                    .padding()
                    Spacer()
                }
                .tabItem {
                    Label("Advanced", systemImage: "star")
                }
                .tag(2)
                .navigationTitle("Arenavi")
                .navigationSubtitle("Advanced")
                .padding()
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
