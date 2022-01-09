//
//  ContentView.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 02/01/2022.
//

import SwiftUI

struct ContentView {
  @ObservedObject var viewModel = ContentViewModel()
  @State var showFileChooser = false
}

extension ContentView: View {
    var body: some View {
      VStack {
        HStack {
          Text("Name:")
          Spacer()
          Text(viewModel.moduleName ?? "")
        }
        HStack {
          Text("Duration:")
          Spacer()
          Text(viewModel.durationString ?? "")
        }
        HStack {
          Text("Current time:")
          Spacer()
          Text(viewModel.currentTimeString ?? "")
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Button("Play") {
            viewModel.handle(.play)
          }

          Button("Stop") {
            viewModel.handle(.stop)
          }

          Button("Select MOD") {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK {
              viewModel.fileURL = panel.url
              viewModel.handle(.load)
            }
          }
        }


      }
      .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
