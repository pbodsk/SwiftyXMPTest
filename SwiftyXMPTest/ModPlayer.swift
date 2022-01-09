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
  static var swiftyXMP = SwiftyXMP()

  private let kQueueSize:UInt32 = 50000
  private let kBufferCount:Int = 3
  var volume: Float = 1.0
  var playerState: PlayerState?

  public var moduleInfoPublisher: AnyPublisher<XMPModuleInfo, Never> {
    moduleInfoSubject.eraseToAnyPublisher()
  }
  private var moduleInfoSubject = PassthroughSubject<XMPModuleInfo, Never>()

  public var frameInfoPublisher: AnyPublisher<XMPFrameInfo, Never> {
    ModPlayer.frameInfoSubject.eraseToAnyPublisher()
  }
  private static var frameInfoSubject = PassthroughSubject<XMPFrameInfo, Never>()

  init() {
    self.playerState = PlayerState(bufferByteSize: kQueueSize)
  }

  deinit {
    disposePlayer()
  }

  private func disposePlayer() {
    if let playerStatus = playerState {
      playerStatus.isRunning = false
      playerStatus.isValid = false
      ModPlayer.swiftyXMP.stop()
      if playerStatus.audioQueue != nil {
        let disposeStatus = AudioQueueDispose(playerStatus.audioQueue!, true)
        print("disposeStatus: \(disposeStatus)")
      }
    }
    self.playerState = nil
  }

  func initPlayer() {
    guard playerState != nil else {
      print("no playerState")
      return
    }
    var err = audioQueueInit(playerState: &playerState!)
    if err != noErr {
      print("queue init failed, error: \(err)")
      disposePlayer()
      return
    }

    ModPlayer.swiftyXMP.start()

    AudioQueueSetParameter(playerState!.audioQueue!, AudioQueueParameterID(kAudioQueueParam_Volume), Float32(volume))

    // setup buffers
    for i in 0..<kBufferCount {
      err = allocateBuffer(playerState: &playerState!, bufferPos: i)
      if err != noErr {
        print("Buffer Alloc failed. OSStatus \(err)")
        disposePlayer()
        return
      }
    }
  }

  func load() {
    let url = URL(fileURLWithPath: "/Users/peter/Downloads/enigma.mod")

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

  func stop() {
    ModPlayer.swiftyXMP.stop()
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
        print("something here")
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
        print("something here")
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



