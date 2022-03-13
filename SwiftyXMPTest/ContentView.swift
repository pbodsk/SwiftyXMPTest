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

        ModInfoRow(title: "Name", content: viewModel.moduleName)
        ModInfoRow(title: "Type", content: viewModel.type)
      }
      .padding(.bottom, 10)

      VStack {
        HStack {
          Text("Mod Info")
            .font(.title2)
          Spacer()
        }

        ModInfoRow(title: "Duration", content: viewModel.durationString)
        ModInfoRow(title: "Length in Patterns", content: viewModel.lengthInPatterns)
        ModInfoRow(title: "Number of Instruments", content: viewModel.numberOfInstruments)
        ModInfoRow(title: "Number of Samples", content: viewModel.numberOfSamples)
        ModInfoRow(title: "Number of Channels", content: viewModel.numberOfVirtuelChannels)
        ModInfoRow(title: "Number of Rows", content: viewModel.numberOfRows)
        ModInfoRow(title: "Number of Patterns", content: viewModel.numberOfPatterns)
        ModInfoRow(title: "Number of Tracks", content: viewModel.numberOfTracks)
        ModInfoRow(title: "Tracks per Pattern", content: viewModel.tracksPerPattern)
      }
      .padding(.bottom, 10.0)

      VStack {
        HStack {
          Text("Time Info")
            .font(.title2)
          Spacer()
        }
        
        ModInfoRow(title: "Row", content: viewModel.row)
        ModInfoRow(title: "Position", content: viewModel.pos)
        ModInfoRow(title: "Pattern", content: viewModel.pattern)
        ModInfoRow(title: "Speed", content: viewModel.speed)
        ModInfoRow(title: "Loop Count", content: viewModel.loopCount)
        ModInfoRow(title: "Current Sequence", content: viewModel.currentSequence)
      }



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
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(playerSettings: PlayerSettings())
  }
}
