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

      ControlsView(viewModel: viewModel)

      if !viewModel.channels.isEmpty {
        Text("Channel Controls").font(.headline)
      }

      HStack {
        ForEach(viewModel.channels) { channel in
          Button(action: { viewModel.handle(.toggleMuteFor(channelID: channel.id)) } ) {
            Text(channel.title)
          }
          .foregroundColor(channel.state == .muted ? Color.gray : Color.black)
          .disabled(viewModel.currentPlayerState.isDisabled)
          .buttonStyle(ChannelButton())
        }
      }
    }
    .onAppear {
      viewModel.connect(with: playerSettings)
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
