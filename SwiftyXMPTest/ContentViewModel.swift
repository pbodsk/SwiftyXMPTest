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
  @Published var currentTimeString: String?

  init() {
    modPlayer.moduleInfoPublisher
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] moduleInfo in
        self?.moduleName = moduleInfo.module.name
        let durationMin = (moduleInfo.sequenceData.duration + 500) / 60000
        let durationSec = ((moduleInfo.sequenceData.duration + 500) / 1000) % 60
        self?.durationString = "\(durationMin):\(durationSec)"
      })
      .store(in: &subscriptions)

    modPlayer.frameInfoPublisher
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] frameInfo in
        let normalizedTime = frameInfo.time / 100
        let hours = (normalizedTime / (60 * 600))
        let minutes = (normalizedTime / 600) % 60
        let seconds = (normalizedTime / 10) % 60
        let miliseconds = normalizedTime % 10

        self?.currentTimeString = String(format: "%3d:%02d:%02d.%d", hours, minutes, seconds, miliseconds)
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
