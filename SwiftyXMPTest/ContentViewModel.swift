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

struct ModInfoItem {
  let title: String
  let value: String?
}

class ContentViewModel: ObservableObject {
  enum Action {
    case load
    case play
    case pause
    case stop
    case skipForwards
    case skipBackwards
    case toggleMute(channel: Int)
    case updatePositionStart
    case updatePositionStop
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

  @Published var generalInfoItems: [ModInfoItem] = []
  @Published var modInfoItems: [ModInfoItem] = []
  @Published var frameInfoItems: [ModInfoItem] = []

  @Published var totalTime: Double = 100.0
  @Published var currentTime: Double = 0.0

  @Published var currentTimeString: String?

  @Published var channelOneState: ModPlayer.ChannelState = .unmuted
  @Published var channelTwoState: ModPlayer.ChannelState = .unmuted
  @Published var channelThreeState: ModPlayer.ChannelState = .unmuted
  @Published var channelFourState: ModPlayer.ChannelState = .unmuted

  @Published var currentPlayerState: PlayerState

  private var isUpdatingPosition = false

  init() {
    currentPlayerState = .stopped

    modPlayer.moduleInfoPublisher
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] moduleInfo in
        self?.populateGeneralModInfoItems(from: moduleInfo)
        self?.populateModInfoItems(from: moduleInfo)
        self?.totalTime = Double(moduleInfo.sequenceData.duration)
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
        self?.currentTime = Double(frameInfo.time)

        self?.populateTimeInfo(from: frameInfo)

      })
      .store(in: &subscriptions)

    modPlayer.modEndedPublisher
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: {[weak self] modEnded in
        if modEnded {
          self?.handle(.stop)
        }
      })
      .store(in: &subscriptions)
  }

  private func populateGeneralModInfoItems(from moduleInfo: XMPModuleInfo) {
    generalInfoItems.removeAll()
    generalInfoItems.append(.init(title: "Name", value: moduleInfo.module.name))
    generalInfoItems.append(.init(title: "Type", value: moduleInfo.module.type))
  }

  private func populateModInfoItems(from moduleInfo: XMPModuleInfo) {
    modInfoItems.removeAll()

    let durationMin = (moduleInfo.sequenceData.duration + 500) / 60000
    let durationSec = ((moduleInfo.sequenceData.duration + 500) / 1000) % 60

    modInfoItems.append(.init(title: "Duration", value: String(format: "%02d:%02d", durationMin, durationSec)))
    modInfoItems.append(.init(title: "Length in Patterns", value: String(moduleInfo.module.lengthInPatterns)))
    modInfoItems.append(.init(title: "Number of Instruments", value: String(moduleInfo.module.numberOfInstruments)))
    modInfoItems.append(.init(title: "Number of Samples", value: String(moduleInfo.module.numberOfSamples)))
    modInfoItems.append(.init(title: "Number of Patterns", value: String(moduleInfo.module.numberOfPatterns)))
    modInfoItems.append(.init(title: "Number of Tracks", value: String(moduleInfo.module.numberOfTracks)))
    modInfoItems.append(.init(title: "Tracks per Pattern", value: String(moduleInfo.module.tracksPerPattern)))
  }

  func populateTimeInfo(from frameInfo: XMPFrameInfo) {
    frameInfoItems.removeAll()

    frameInfoItems.append(.init(title: "Row", value: String(frameInfo.row)))
    frameInfoItems.append(.init(title: "Position", value: String(frameInfo.pos)))
    frameInfoItems.append(.init(title: "Pattern", value: String(frameInfo.pattern)))
    frameInfoItems.append(.init(title: "Speed", value: String(frameInfo.speed)))
    frameInfoItems.append(.init(title: "Loop Count", value: String(frameInfo.loopCount)))
    frameInfoItems.append(.init(title: "Current Sequence", value: String(frameInfo.currentSequence)))
    frameInfoItems.append(.init(title: "Number of Channels", value: String(frameInfo.virtuelChannelsUsed)))
    frameInfoItems.append(.init(title: "Number of Rows", value: String(frameInfo.numberOfRows)))
  }

  func handle(_ action: Action) {
    switch action {
    case .load:
      modPlayer.disposePlayer()
      if let fileURL = fileURL {
        modPlayer.load(url: fileURL)
      }
      if !modPlayer.playerIsInitialized {
        modPlayer.initPlayer()
      }
      modPlayer.startPlayer()

      modPlayer.play()
      currentPlayerState = .playing
    case .play:
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
      clearUI()
      currentPlayerState = .stopped
    case .skipForwards:
      modPlayer.skipForwards()
    case .skipBackwards:
      modPlayer.skipBackwards()
    case .updatePositionStart:
      if !isUpdatingPosition {
        modPlayer.pause()
        isUpdatingPosition = true
      }
    case .updatePositionStop:
      modPlayer.updateProgress(newValue: currentTime)
      modPlayer.resume()
      isUpdatingPosition = false
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

  private func clearUI() {
    currentTimeString = nil
    totalTime = 100.0
    currentTime = 0.0

    generalInfoItems.removeAll()
    modInfoItems.removeAll()
    frameInfoItems.removeAll()
  }

  var showPlayButton: Bool {
    currentPlayerState == .stopped || currentPlayerState == .paused
  }
}
