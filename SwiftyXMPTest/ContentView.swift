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

        HStack {
          Text("Name:")
          Spacer()
          Text(viewModel.moduleName ?? "")
        }

        HStack {
          Text("Type:")
          Spacer()
          Text(viewModel.type)
        }
      }
      .padding(.bottom, 10)

      VStack {
        HStack {
          Text("Mod Info")
            .font(.title2)
          Spacer()
        }

        HStack {
          Text("Duration:")
          Spacer()
          Text(viewModel.durationString ?? "")
        }
        HStack {
          Text("Length in Patterns:")
          Spacer()
          Text(viewModel.lengthInPatterns)
        }

        HStack {
          Text("Number of Instruments:")
          Spacer()
          Text(viewModel.numberOfInstruments)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Text("Number of Samples:")
          Spacer()
          Text(viewModel.numberOfSamples)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }


        HStack {
          Text("Number of Channels:")
          Spacer()
          Text(viewModel.numberOfVirtuelChannels)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Text("Number of Rows:")
          Spacer()
          Text(viewModel.numberOfRows)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }
        HStack {
          Text("Number of Patterns:")
          Spacer()
          Text(viewModel.numberOfPatterns)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }
        HStack {
          Text("Number of Tracks:")
          Spacer()
          Text(viewModel.numberOfTracks)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }
        HStack {
          Text("Tracks per Pattern:")
          Spacer()
          Text(viewModel.tracksPerPattern)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }


      }
      .padding(.bottom, 10.0)

      VStack {
        HStack {
          Text("Time Info")
            .font(.title2)
          Spacer()
        }

        HStack {
          Text("Current time:")
          Spacer()
          Text(viewModel.currentTimeString ?? "")
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Text("Row:")
          Spacer()
          Text(viewModel.row)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Text("Position:")
          Spacer()
          Text(viewModel.pos)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Text("Pattern:")
          Spacer()
          Text(viewModel.pattern)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Text("Speed:")
          Spacer()
          Text(viewModel.speed)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }

        HStack {
          Text("Loop count:")
          Spacer()
          Text(viewModel.loopCount)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }


        HStack {
          Text("Current Sequence:")
          Spacer()
          Text(viewModel.currentSequence)
            .font(.system(.body, design: .monospaced).monospacedDigit())
        }
      }

      ProgressView(value: viewModel.currentTime, total: viewModel.totalTime)

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
