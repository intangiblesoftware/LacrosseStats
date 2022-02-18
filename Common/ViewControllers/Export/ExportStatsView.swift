//
//  ExportStatsView.swift
//  LacrosseStats
//
//  Created by Jim Dabrowski on 2/16/22.
//  Copyright © 2022 Intangible Software. All rights reserved.
//

import SwiftUI
import MessageUI

struct ExportStatsView: View {
    @Environment(\.presentationMode) var presentationMode

    var fileGenerator: StatsFileGenerator
    
    @State private var canExportStats: Bool = true {
        willSet {
            if newValue {
                message = ""
            } else {
                message = "Unable to send email at this time. Please check your mail settings and try again."
            }
        }
    }
    
    @State var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView: Bool = false
        
    @AppStorage(INSOExportGameSummaryDefaultKey) private var exportGameSummary = true
    @AppStorage(INSOExportPlayerStatsDefaultKey) private var exportPlayerStats = true
    @AppStorage(INSOExportMaxPrepsDefaultKey) private var exportMaxPreps = true
    
    @State private var message: String = "Your message goes here."
        
    var body: some View {
        NavigationView {
            VStack() {
                Text("Select the stats you want to export.")
                    .padding(.vertical)
                Group {
                    Toggle("Game summary: ", isOn: $exportGameSummary)
                    Toggle("Individual player stats: ", isOn: $exportPlayerStats)
                    Toggle(isOn: $exportMaxPreps) {
                        Image("MaxPrepsLogo01")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200.0)
                    }
                }.toggleStyle(SwitchToggleStyle(tint: Color("main")))
                    .padding(.bottom)
                    .disabled(!canExportStats)
                ExportStatsButton(isShowingMailView: $isShowingMailView)
                    .disabled(!canExportStats)
                Text("\(message)").padding()
                    .multilineTextAlignment(.center)
                Spacer()
            }.padding(.horizontal)
                .background(Color("background"))
                .navigationTitle("Export Stats")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            // dismiss
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Done")
                                .foregroundColor(Color.white)
                        }
                    }
                }
        }.onAppear {
            // Variety of ways to control appearance of nav bar views.
            // I chose this one since I only have one nav bar
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.mainColor()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            canExportStats = MFMailComposeViewController.canSendMail()
        }
    }
    
    func canWeExportStats() -> Bool {
        return false
    }
}

struct ExportStatsButton: View {
    @Binding var isShowingMailView: Bool
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        Button {
            if MFMailComposeViewController.canSendMail() {
                self.isShowingMailView.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "envelope")
                Text("Export Stats")
            }
        }.buttonStyle(INSOButtonStyle())
            .sheet(isPresented: $isShowingMailView) {
                MailView(result: $result)
            }
    }
}

struct ExportStatsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportStatsView(fileGenerator: StatsFileGenerator())
            .previewLayout(.sizeThatFits)
    }
}
