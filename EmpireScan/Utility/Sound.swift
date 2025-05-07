/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import Foundation
import AVFoundation

open class Sound {
  private var player: AVAudioPlayer = AVAudioPlayer()
  public var volume: Float {
    get { return player.volume }
    set { player.volume = newValue }
  }

  public init?(filename: String, fileExtension: String, volume: Float = 0.4) {
    do {
      guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
        return
      }
      try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
      try AVAudioSession.sharedInstance().setActive(true)
      player = try AVAudioPlayer(contentsOf: url)
      player.volume = volume
    } catch {
      print("Audio Player initialization error: \(error)")
    }
  }

  public func play() {
    DispatchQueue.global(qos: .background).async { [weak self] in
      guard let self = self else { return }
      if !self.isPlaying() {
        self.player.play()
      }
    }
  }

  public func isPlaying() -> Bool {
    return player.isPlaying
  }
}
