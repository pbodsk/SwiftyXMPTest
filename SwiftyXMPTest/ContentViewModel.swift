//
//  ContentViewModel.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 08/01/2022.
//

import Combine
import Foundation
import SwiftUI
import SwiftyXMP
import CoreAudio

class ContentViewModel: ObservableObject {

  enum Action {
    case load
    case play
    case stop
  }

  private let modPlayer = ModPlayer()
  private var subscriptions = Set<AnyCancellable>()

  @Published var moduleName: String?
  @Published var durationString: String?

  init() {
    modPlayer.moduleInfoPublisher
      .sink(receiveValue: { [weak self] moduleInfo in
        self?.moduleName = moduleInfo.module.name
        let durationMin = (moduleInfo.sequenceData.duration + 500) / 60000
        let durationSec = ((moduleInfo.sequenceData.duration + 500) / 1000) % 60
        self?.durationString = "\(durationMin):\(durationSec)"
      })
      .store(in: &subscriptions)

    modPlayer.frameInfoPublisher
      .sink(receiveValue: { [weak self] frameInfo in
        print(frameInfo.time)
      })
      .store(in: &subscriptions)
  }

  func handle(_ action: Action) {
    switch action {
    case .load:
      modPlayer.load()
      modPlayer.initPlayer()
    case .play:
      modPlayer.play()
    case .stop:
      modPlayer.stop()
    }
  }
}
