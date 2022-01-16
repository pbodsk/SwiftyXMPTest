//
//  SwiftyXMPTestApp.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 02/01/2022.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct SwiftyXMPTestApp: App {

  @StateObject var playerSettings = PlayerSettings()

    var body: some Scene {
        WindowGroup {
            ContentView(playerSettings: playerSettings)
        }
        .commands {
          CommandGroup(replacing: .newItem) {
            Button("Open...") {
              let allowedContentTypes: [UTType] = [
                .init(filenameExtension: "mod")!
              ]
              let panel = NSOpenPanel()
              panel.allowsMultipleSelection = false
              panel.canChooseDirectories = false
              panel.allowedContentTypes = allowedContentTypes
              if panel.runModal() == .OK {
                if let selectedURL = panel.url {
                  playerSettings.fileSelectedSubject.send(selectedURL)
                }
              }
            }
          }
        }
    }
}
