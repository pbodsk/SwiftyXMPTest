//
//  ModPlayer.swift
//  SwiftyXMPTest
//
//  Created by Peter Bødskov on 02/01/2022.
//

import AudioToolbox
import Combine
import Foundation
import SwiftyXMP

class PlayerState {
  var dataFormat: AudioStreamBasicDescription
  var audioQueue: AudioQueueRef!
  var buffers: [AudioQueueBufferRef?]
  let bufferByteSize: UInt32
  var position: Int = 0
  var seconds: Int = 0
  var isRunning: Bool = false
  var isValid: Bool = false

  private let channelsPerFrame: UInt32 = 2  //1 - mono, 2 - stereo
  private let bitsPerChannel: UInt32 = 16   //16 or 8 for XMP
  private let bytesPerChannel: UInt32 = 2

  init(bufferByteSize: UInt32) {
    self.buffers = Array<AudioQueueBufferRef?>(repeating: nil, count: 3)

    self.bufferByteSize = bufferByteSize

    let dataFormat = AudioStreamBasicDescription(
      mSampleRate: 44100,
      mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsSignedInteger,
      mBytesPerPacket: bytesPerChannel * channelsPerFrame,
      mFramesPerPacket: 1,
      mBytesPerFrame: bytesPerChannel * channelsPerFrame,
      mChannelsPerFrame: channelsPerFrame,
      mBitsPerChannel: bitsPerChannel,
      mReserved: 0
    )
    self.dataFormat = dataFormat
  }
}


class ModPlayer {

  enum ChannelState {
    case muted
    case unmuted

    init?(xmpChannelState: XMPChannelState) {
      switch xmpChannelState {
      case .muted:
        self = .muted
      case .unmuted:
        self = .unmuted
      case .query:
        return nil
      }
    }

    var xmpChannelState: XMPChannelState {
      switch self {
      case .muted:
        return .muted
      case .unmuted:
        return .unmuted
      }
    }

    var toggled: ChannelState {
      switch self {
      case .muted:
        return .unmuted
      case .unmuted:
        return .muted
      }
    }
  }

  static var swiftyXMP = SwiftyXMP()

  private let kQueueSize:UInt32 = 50000
  private let kBufferCount:Int = 3
  var volume: Float = 1.0
  var playerState: PlayerState?
  private (set) var playerIsInitialized = false
  
  public var moduleInfoPublisher: AnyPublisher<XMPModuleInfo, Never> {
    moduleInfoSubject.eraseToAnyPublisher()
  }
  private var moduleInfoSubject = PassthroughSubject<XMPModuleInfo, Never>()

  public var frameInfoPublisher: AnyPublisher<XMPFrameInfo, Never> {
    ModPlayer.frameInfoSubject.eraseToAnyPublisher()
  }
  private static var frameInfoSubject = PassthroughSubject<XMPFrameInfo, Never>()

  public var modEndedPublisher: AnyPublisher<Bool, Never> {
    ModPlayer.modEndedSubject.eraseToAnyPublisher()
  }
  private static var modEndedSubject = PassthroughSubject<Bool, Never>()

  init() {
    self.playerState = PlayerState(bufferByteSize: kQueueSize)
  }

  deinit {
    disposePlayer()
  }

  func disposePlayer() {
    if let playerStatus = playerState {
      playerStatus.isRunning = false
      playerStatus.isValid = false
      stopPlayer()
    }
    playerIsInitialized = false
  }

  private func stopPlayer() {
    if let playerStatus = playerState {
      ModPlayer.swiftyXMP.stop()
      if playerStatus.audioQueue != nil {
        let disposeStatus = AudioQueueDispose(playerStatus.audioQueue!, true)
        print("disposeStatus: \(disposeStatus)")
      }
    }
  }

  func initPlayer() {
    guard playerState != nil else {
      print("no playerState")
      return
    }
    let err = audioQueueInit(playerState: &playerState!)
    if err != noErr {
      print("queue init failed, error: \(err)")
      disposePlayer()
      return
    }
    AudioQueueSetParameter(playerState!.audioQueue!, AudioQueueParameterID(kAudioQueueParam_Volume), Float32(volume))

    // setup buffers
    for i in 0..<kBufferCount {
      let err = allocateBuffer(playerState: &playerState!, bufferPos: i)
      if err != noErr {
        print("Buffer Alloc failed. OSStatus \(err)")
        disposePlayer()
        return
      }
    }

  }

  func startPlayer() {
    ModPlayer.swiftyXMP.start()
  }

  func load(url: URL) {
    do {
      try ModPlayer.swiftyXMP.load(url)
      moduleInfoSubject.send(ModPlayer.swiftyXMP.moduleInfo())
    } catch {
      print(error)
    }
  }

  func play() {
    guard playerState != nil && playerState!.audioQueue != nil else { return }
    for i in 0..<kBufferCount {
      let xmpStatus = audioQueuePrimeFrame(playerState: &playerState!, bufferPos: i)
      if xmpStatus != 0 {
        print("Prime fames failed. xmp_status \(xmpStatus)")
        //disposePlayer()
        return
      }
    }
    let status = AudioQueueStart(playerState!.audioQueue!, nil)
    if status == 0 {
      playerState?.isRunning = true
    }
  }

  func pause() {
    AudioQueuePause(playerState!.audioQueue!)
  }

  func resume() {
    let status = AudioQueueStart(playerState!.audioQueue!, nil)
    if status == 0 {
      playerState?.isRunning = true
    }
  }

  func stop() {
    stopPlayer()
//    disposePlayer()
  }

  func updateProgress(newValue: Double) {
    do {
      _ = try ModPlayer.swiftyXMP.seek(to: Int32(newValue))
    } catch {
      print(error)
    }
  }

  @discardableResult
  func skipForwards() -> Int {
    Int(ModPlayer.swiftyXMP.nextPosition())
  }

  @discardableResult
  func skipBackwards() -> Int {
    Int(ModPlayer.swiftyXMP.previousPosition())
  }

  func state(for channel: Int) -> ModPlayer.ChannelState? {
    guard let xmpChannelState = try? ModPlayer.swiftyXMP.updateChannel(Int32(channel), to: .query)
    else { return nil }
    return ModPlayer.ChannelState(xmpChannelState: xmpChannelState)
  }

  func changeState(for channel: Int, to newState: ModPlayer.ChannelState) throws -> ModPlayer.ChannelState? {
    let newXMPState = newState.xmpChannelState
    if let _ = try ModPlayer.swiftyXMP.updateChannel(Int32(channel), to: newXMPState) {
      return newState
    }
    print("WHAT THE!!")
    return nil
  }

  private func audioQueueInit(playerState: inout PlayerState) -> OSStatus {
    AudioQueueNewOutput(
      &playerState.dataFormat,
      callback,
      &playerState,
      nil,
      nil,
      0,
      &playerState.audioQueue
    )
  }

  private func allocateBuffer(playerState: inout PlayerState, bufferPos: Int) -> OSStatus {
    guard let audioQueueRef = playerState.audioQueue else { return -1 }
    return AudioQueueAllocateBuffer(audioQueueRef, playerState.bufferByteSize, &playerState.buffers[bufferPos])
  }

  private func audioQueuePrimeFrame(playerState: inout PlayerState, bufferPos: Int) -> OSStatus {
    var frameStatus: OSStatus

    if
      let inAudioQueueRef = playerState.audioQueue,
      let inBuffer = playerState.buffers[bufferPos]
    {
      frameStatus = queueFrame(playerState: &playerState, inQueue: inAudioQueueRef, inBuffer: inBuffer)
      if frameStatus == 0 {
        frameStatus = AudioQueueEnqueueBuffer(
          inAudioQueueRef, inBuffer,
          0,
          nil
        )
        if frameStatus != noErr {
          print("ALSO DEAD: \(frameStatus)")
        }
        return frameStatus
      } else {
        print("DEADER! \(frameStatus)")
        return -1
      }
    } else {
      print("DEAD!")
      return -1
    }
  }

  func queueFrame(playerState: inout PlayerState, inQueue: AudioQueueRef, inBuffer: AudioQueueBufferRef ) -> Int32 {

    var status: Int32 = 0
    do {
      let frameInfo = try ModPlayer.swiftyXMP.playFrame()
      ModPlayer.frameInfoSubject.send(frameInfo)
      if frameInfo.loopCount != 0 {
        // the mod has ended
        playerState.isRunning = false
        ModPlayer.modEndedSubject.send(true)
        status = -1
      }
      inBuffer.pointee.mAudioData.copyMemory(from: frameInfo.buffer, byteCount: Int(frameInfo.bufferSize))
      inBuffer.pointee.mAudioDataByteSize = UInt32(frameInfo.bufferSize)

    } catch {
      print("no frame - status: \(error)")
      status = -1
    }
    return status
  }

  private let callback: AudioQueueOutputCallback = { aqData, inAQ, inBuffer in
    var playerState = aqData.unsafelyUnwrapped.load(as: PlayerState.self)

    if !playerState.isRunning {
      print("not running")
    }

    var status = 0
    do {
      var frameInfo = try ModPlayer.swiftyXMP.playFrame()
      ModPlayer.frameInfoSubject.send(frameInfo)
      if frameInfo.loopCount != 0 {
        // the mod has ended
        playerState.isRunning = false
        ModPlayer.modEndedSubject.send(true)
        status = -1
      }
      inBuffer.pointee.mAudioData.copyMemory(from: frameInfo.buffer, byteCount: Int(frameInfo.bufferSize))
      inBuffer.pointee.mAudioDataByteSize = UInt32(frameInfo.bufferSize)

    } catch {
      print("no frame - status: \(error)")
      status = -1
    }
    if status == 0 {
      AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
    }
  }
}
