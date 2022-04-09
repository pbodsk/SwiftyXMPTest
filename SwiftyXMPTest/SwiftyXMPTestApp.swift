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
  private let acceptedDropTypes = ["public.file-url"]

  let supportedFileTypes: [UTType] = [
    .init(filenameExtension: "mod")!,
    .init(filenameExtension: "xm")!
  ]

  var body: some Scene {
    WindowGroup {
      ContentView(playerSettings: playerSettings)
        .onDrop(of: acceptedDropTypes, isTargeted: nil) { providers in
          guard let provider = providers.first else { return false }
          provider.loadDataRepresentation(forTypeIdentifier: acceptedDropTypes.first!) { (data, error) in
            guard
              let data = data,
              let path = NSString(data: data, encoding: 4) as String?,
              let selectedURL = URL(string: path)
            else {
              return
            }
            DispatchQueue.main.async {
              playerSettings.fileSelectedSubject.send(selectedURL)
            }
          }
          return true
        }
    }
    .commands {
      CommandGroup(replacing: .newItem) {
        Button("Open...") {
          let panel = NSOpenPanel()
          panel.allowsMultipleSelection = false
          panel.canChooseDirectories = false
          panel.allowedContentTypes = supportedFileTypes
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
