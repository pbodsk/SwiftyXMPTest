//
//  ModInfoRow.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 13/03/2022.
//

import SwiftUI

struct ModInfoRow: View {
  let title: String
  let content: String?

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Text(content ?? "")
        .font(.system(.body, design: .monospaced).monospacedDigit())
    }
  }
}

struct ModInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        ModInfoRow(title: "Number of Instruments", content: "4")
    }
}
