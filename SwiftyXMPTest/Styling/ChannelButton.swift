import SwiftUI

struct ChannelButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .frame(width: 40, height: 40, alignment: .center)
      .background(Color.yellow)
      .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5.0, height: 5.0)))
  }
}
