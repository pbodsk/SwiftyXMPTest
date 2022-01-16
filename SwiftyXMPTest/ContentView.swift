//
//  ContentView.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 02/01/2022.
//

import UniformTypeIdentifiers
import SwiftUI

struct ContentView {
  @ObservedObject var viewModel = ContentViewModel()
  @ObservedObject var playerSettings: PlayerSettings
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

      ProgressView(value: viewModel.currentTime, total: viewModel.totalTime)

      HStack {
        Button(action: { viewModel.handle(.play) }) {
          Image(systemName: "play.circle.fill")
        }

        Button(action: { viewModel.handle(.stop) }) {
          Image(systemName: "stop.circle.fill")
        }
        .onAppear {
          viewModel.connect(with: playerSettings)
        }
      }
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(playerSettings: PlayerSettings())
  }
}
