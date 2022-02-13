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
    case pause
    case stop
    case skipForwards
    case skipBackwards
    case toggleMute(channel: Int)
  }

  enum PlayerState {
    case stopped
    case playing
    case paused

    var isDisabled: Bool {
      switch self {
      case .stopped:
        return true
      case .playing:
        return false
      case .paused:
        return false
      }
    }
  }

  private let modPlayer = ModPlayer()
  private var subscriptions = Set<AnyCancellable>()
  public var fileURL: URL?

  @Published var moduleName: String?
  @Published var type: String = ""
  @Published var numberOfPatterns: String = ""
  @Published var numberOfTracks: String = ""
  @Published var tracksPerPattern: String = ""
  @Published var numberOfInstruments: String = ""
  @Published var numberOfSamples: String = ""
  @Published var lengthInPatterns: String = ""
  @Published var durationString: String?
  @Published var currentTimeString: String?
  @Published var totalTime: Float = 100.0
  @Published var currentTime: Float = 0.0
  @Published var frameTime: String = ""
  @Published var loopCount: String = ""
  @Published var numberOfRows: String = ""
  @Published var numberOfVirtuelChannels: String = ""
  @Published var pattern: String = ""
  @Published var pos: String = ""
  @Published var row: String = ""
  @Published var currentSequence: String = ""
  @Published var speed: String = ""
  @Published var virtuelChannelsUsed: String = ""

  @Published var channelOneState: ModPlayer.ChannelState = .unmuted
  @Published var channelTwoState: ModPlayer.ChannelState = .unmuted
  @Published var channelThreeState: ModPlayer.ChannelState = .unmuted
  @Published var channelFourState: ModPlayer.ChannelState = .unmuted

  @Published var currentPlayerState: PlayerState

  init() {
    currentPlayerState = .stopped

    modPlayer.moduleInfoPublisher
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] moduleInfo in
        self?.moduleName = moduleInfo.module.name
        let durationMin = (moduleInfo.sequenceData.duration + 500) / 60000
        let durationSec = ((moduleInfo.sequenceData.duration + 500) / 1000) % 60
        self?.durationString = String(format: "%02d:%02d", durationMin, durationSec)
        self?.totalTime = Float(moduleInfo.sequenceData.duration)
        self?.type = moduleInfo.module.type
        self?.numberOfPatterns = String(moduleInfo.module.numberOfPatterns)
        self?.numberOfTracks = String(moduleInfo.module.numberOfTracks)
        self?.tracksPerPattern = String(moduleInfo.module.tracksPerPattern)
        self?.numberOfInstruments = String(moduleInfo.module.numberOfInstruments)
        self?.numberOfSamples = String(moduleInfo.module.numberOfSamples)
        self?.lengthInPatterns = String(moduleInfo.module.lengthInPatterns)
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

        self?.frameTime = String(frameInfo.frameTime)
        self?.loopCount = String(frameInfo.loopCount)
        self?.numberOfRows = String(frameInfo.numberOfRows)
        self?.numberOfVirtuelChannels = String(frameInfo.numberOfVirtuelChannels)
        self?.pattern = String(frameInfo.pattern)
        self?.pos = String(frameInfo.pos)
        self?.row = String(frameInfo.row)
        self?.currentSequence = String(frameInfo.currentSequence)
        self?.speed = String(frameInfo.speed)
        self?.virtuelChannelsUsed = String(frameInfo.virtuelChannelsUsed)
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
      modPlayer.play()
      currentPlayerState = .playing
    case .play:
      modPlayer.stop()
      if currentPlayerState == .paused {
        modPlayer.resume()
      } else {
        modPlayer.play()
      }
      currentPlayerState = .playing
    case .pause:
      modPlayer.pause()
      currentPlayerState = .paused
    case .stop:
      modPlayer.stop()
      currentPlayerState = .stopped
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

  var showPlayButton: Bool {
    currentPlayerState == .stopped || currentPlayerState == .paused
  }
}
