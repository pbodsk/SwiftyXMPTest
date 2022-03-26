//
//  ControlsView.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 26/03/2022.
//

import SwiftUI

struct ControlsView: View {
  @ObservedObject var viewModel: ContentViewModel
  
  var body: some View {
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
    }
  }
}

struct ControlsView_Previews: PreviewProvider {
  static var previews: some View {
    ControlsView(viewModel: ContentViewModel())
  }
}
