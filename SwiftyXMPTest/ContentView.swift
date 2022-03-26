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
      VStack {
        HStack {
          Text("General Info")
            .font(.title2)
          Spacer()
        }

        ForEach(viewModel.generalInfoItems, id: \.title) {
          ModInfoRow(title: $0.title, content: $0.value)
        }
      }
      .padding(.bottom, 10)

      VStack {
        HStack {
          Text("Mod Info")
            .font(.title2)
          Spacer()
        }

        ForEach(viewModel.modInfoItems, id: \.title) {
          ModInfoRow(title: $0.title, content: $0.value)
        }
      }
      .padding(.bottom, 10.0)

      VStack {
        HStack {
          Text("Time Info")
            .font(.title2)
          Spacer()
        }

        ForEach(viewModel.frameInfoItems, id: \.title) {
          ModInfoRow(title: $0.title, content: $0.value)
        }
      }

      Spacer()

      Slider(
        value: $viewModel.currentTime,
        in: 0...viewModel.totalTime,
        onEditingChanged: { updating in
          if updating {
            viewModel.handle(.updatePositionStart)
          } else {
            viewModel.handle(.updatePositionStop)
          }
        }
      )

      Text(viewModel.currentTimeString ?? "0:00:00.0")
        .font(.system(.headline, design: .monospaced).monospacedDigit())

      HStack {
        Button(action: { viewModel.handle(.skipBackwards) }) {
          Image(systemName: "backward.fill").foregroundColor(Color.white)
        }
        .disabled(viewModel.currentPlayerState.isDisabled)
        .buttonStyle(ControlButton())

        if(viewModel.showPlayButton) {
          Button(action: { viewModel.handle(.play) }) {
            Image(systemName: "play.fill").foregroundColor(Color.white)
          }
          .disabled(viewModel.currentPlayerState.isDisabled)
          .buttonStyle(ControlButton())

        } else {
          Button(action: { viewModel.handle(.pause) }) {
            Image(systemName: "pause.fill").foregroundColor(Color.white)
          }
          .keyboardShortcut("P")
          .disabled(viewModel.currentPlayerState.isDisabled)
          .buttonStyle(ControlButton())
        }
        
        Button(action: { viewModel.handle(.stop) }) {
          Image(systemName: "stop.fill").foregroundColor(Color.white)
        }
        .disabled(viewModel.currentPlayerState.isDisabled)
        .buttonStyle(ControlButton())

        Button(action: { viewModel.handle(.skipForwards) }) {
          Image(systemName: "forward.fill").foregroundColor(Color.white)
        }
        .disabled(viewModel.currentPlayerState.isDisabled)
        .buttonStyle(ControlButton())
        .onAppear {
          viewModel.connect(with: playerSettings)
        }
      }

      Text("Channel Controls").font(.headline)

      HStack {
        Button(action: { viewModel.handle(.toggleMute(channel: 0)) }) {
          Text("1")
        }
        .foregroundColor(viewModel.channelOneState == .muted ? Color.gray : Color.black)
        .disabled(viewModel.currentPlayerState.isDisabled)
        .buttonStyle(ChannelButton())

        Button(action: { viewModel.handle(.toggleMute(channel: 1)) }) {
          Text("2")
        }
        .foregroundColor(viewModel.channelTwoState == .muted ? Color.gray : Color.black)
        .disabled(viewModel.currentPlayerState.isDisabled)
        .buttonStyle(ChannelButton())

        Button(action: { viewModel.handle(.toggleMute(channel: 2)) }) {
          Text("3")
        }
        .foregroundColor(viewModel.channelThreeState == .muted ? Color.gray : Color.black)
        .disabled(viewModel.currentPlayerState.isDisabled)
        .buttonStyle(ChannelButton())

        Button(action: { viewModel.handle(.toggleMute(channel: 3)) }) {
          Text("4")
        }
        .foregroundColor(viewModel.channelFourState == .muted ? Color.gray : Color.black)
        .disabled(viewModel.currentPlayerState.isDisabled)
        .buttonStyle(ChannelButton())
      }
    }
    .frame(
      minWidth: 200.0,
      maxWidth: 700.0,
      minHeight: 600.0,
      maxHeight: 600.0,
      alignment: .center
    )
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(playerSettings: PlayerSettings())
  }
}
