//
//  sound.swift
//  b2t80s
//
//  Created by German Laullon on 12/9/23.
//

import Foundation
import AVFoundation

class SoundEngine {
    let audioEngine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    var buffer: AVAudioPCMBuffer
    let mixer = AVAudioMixerNode()
    let frameBufferLength = 700 // 3500000/50/1000
    var frame = 0
    let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 70000, channels: 2, interleaved: false)!

    var volumen: Double = 0 {
        didSet {
            mixer.outputVolume = Float(volumen)
        }
    }

    init() {
        
        buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(frameBufferLength))!
        buffer.frameLength = AVAudioFrameCount(frameBufferLength)

        audioEngine.attach(mixer)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)

        audioEngine.attach(player)
        audioEngine.connect(player, to: mixer, format: fmt)
        
        mixer.outputVolume = 0

        do{
            try audioEngine.start()
        }catch{
            fatalError(error.localizedDescription)
        }
        player.play()
        self.initNewBuffer()
    }
    
    func initNewBuffer() {
        buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(frameBufferLength))!
        buffer.frameLength = AVAudioFrameCount(frameBufferLength)
    }
    
    func tick(_ b: Bool) {
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        if b {
            left[frame] = 1
            right[frame] = 1
        } else {
            left[frame] = 00
            right[frame] = 00
        }
        frame += 1
        if frame == frameBufferLength {
            frame = 0
            player.scheduleBuffer(buffer)
            initNewBuffer()
        }
    }
}
