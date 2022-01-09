//
//  ContentView.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 02/01/2022.
//

import SwiftUI

struct ContentView {
  @ObservedObject var viewModel = ContentViewModel()
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
            viewModel.handle(.load)
            viewModel.handle(.play)
          }

          Button("Stop") {
            viewModel.handle(.stop)
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
