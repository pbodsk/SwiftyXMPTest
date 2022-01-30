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
    case skipForwards
    case skipBackwards
    case toggleMute(channel: Int)
  }

  private let modPlayer = ModPlayer()
  private var subscriptions = Set<AnyCancellable>()
  public var fileURL: URL?

  @Published var moduleName: String?
  @Published var durationString: String?
  @Published var currentTimeString: String?
  @Published var totalTime: Float = 100.0
  @Published var currentTime: Float = 0.0

  @Published var channelOneState: ModPlayer.ChannelState = .unmuted
  @Published var channelTwoState: ModPlayer.ChannelState = .unmuted
  @Published var channelThreeState: ModPlayer.ChannelState = .unmuted
  @Published var channelFourState: ModPlayer.ChannelState = .unmuted

  init() {
    modPlayer.moduleInfoPublisher
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] moduleInfo in
        self?.moduleName = moduleInfo.module.name
        let durationMin = (moduleInfo.sequenceData.duration + 500) / 60000
        let durationSec = ((moduleInfo.sequenceData.duration + 500) / 1000) % 60
        self?.durationString = "\(durationMin):\(durationSec)"
        self?.totalTime = Float(moduleInfo.sequenceData.duration)
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
        self?.currentTime = Float(frameInfo.time)
      })
      .store(in: &subscriptions)
  }

  func handle(_ action: Action) {
    switch action {
    case .load:
      if let fileURL = fileURL {
        modPlayer.load(url: fileURL)
      }
      modPlayer.initPlayer()
    case .play:
      modPlayer.play()
    case .stop:
      modPlayer.stop()
    case .skipForwards:
      modPlayer.skipForwards()
    case .skipBackwards:
      modPlayer.skipBackwards()
    case .toggleMute(channel: let channel):
      switch channel {
      case 0:
        do {
          if let updatedState = try modPlayer.changeState(for: channel, to: channelOneState.toggled) {
            channelOneState = updatedState
          }
        } catch {
          print("error")
        }
      case 1:
        do {
          if let newState = try modPlayer.changeState(for: channel, to: channelTwoState.toggled) {
            channelTwoState = newState
          }
        } catch {
          print("error")
        }
      case 2:
        do {
          if let newState = try modPlayer.changeState(for: channel, to: channelThreeState.toggled) {
            channelThreeState = newState
          }
        } catch {
          print("error")
        }
      case 3:
        do {
          if let newState = try modPlayer.changeState(for: channel, to: channelFourState.toggled) {
            channelFourState = newState
          }
        } catch {
          print("error")
        }
      default: break
      }
    }
  }

  func connect(with playerSettings: PlayerSettings) {
    playerSettings.fileSelectedSubject
      .sink(receiveValue: { selectedFileURL in
        self.fileURL = selectedFileURL
        self.handle(.load)
      })
      .store(in: &subscriptions)

  }
}
