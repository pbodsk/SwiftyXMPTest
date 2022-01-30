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
        Button(action: { viewModel.handle(.skipBackwards) }) {
          Image(systemName: "backward.fill")
        }

        Button(action: { viewModel.handle(.play) }) {
          Image(systemName: "play.fill")
        }

        Button(action: { viewModel.handle(.skipForwards) }) {
          Image(systemName: "forward.fill")
        }

        Button(action: { viewModel.handle(.stop) }) {
          Image(systemName: "stop.fill")
        }
        .onAppear {
          viewModel.connect(with: playerSettings)
        }
      }

      HStack {
        Button(action: { viewModel.handle(.toggleMute(channel: 0)) }) {
          Text("1")
        }
        .foregroundColor(viewModel.channelOneState == .muted ? Color.gray : Color.black)

        Button(action: { viewModel.handle(.toggleMute(channel: 1)) }) {
          Text("2")
        }
        .foregroundColor(viewModel.channelTwoState == .muted ? Color.gray : Color.black)

        Button(action: { viewModel.handle(.toggleMute(channel: 2)) }) {
          Text("3")
        }
        .foregroundColor(viewModel.channelThreeState == .muted ? Color.gray : Color.black)

        Button(action: { viewModel.handle(.toggleMute(channel: 3)) }) {
          Text("4")
        }
        .foregroundColor(viewModel.channelFourState == .muted ? Color.gray : Color.black)
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
