//
//  PlayerSettings.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 16/01/2022.
//

import Combine
import Foundation

class PlayerSettings: ObservableObject {
  var fileSelectedSubject = PassthroughSubject<URL, Never>()
}
