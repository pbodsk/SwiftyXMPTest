import SwiftUI

struct ControlButton: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .background(isEnabled ? Color.black : Color.gray)
      .clipShape(Circle())
  }
}
