//
//  AudioManager.swift
//  Audio
//
//  Created by Javier Zapata on 9/18/18.
//  Copyright © 2018 Javier Zapata. All rights reserved.
//

import AVFoundation



final class AudioManager {
    
    
    
    
    // The audio engine manages the sound system.
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    
    // The player node schedules the playback of the audio buffers.
    private let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    
    // Use standard non-interleaved PCM audio.
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 22050.0, channels: 1)
    
    
    init() {
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine didn't start")
        }
    }
    
    
    
    
    func playData(data:Data){
        
        print("count", data.count)
        print("isrunning", audioEngine.isRunning)
        if (data.count  > 0 && audioEngine.isRunning)
        {
            print("am i even playing!!!!!!!!!")
            let buffer = toPCMBuffer(data: data as NSData)
            playerNode.scheduleBuffer(buffer, completionHandler: nil)
            playerNode.prepare(withFrameCount: buffer.frameCapacity)
            playerNode.play()
        }else{
            
            playerNode.stop()
        }
    }
    
    
    
    
}

extension AudioManager {
    
    fileprivate func toData(PCMBuffer: AVAudioPCMBuffer) -> Data
    {
        
        let channelCount = 1
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: channelCount)
        
        let ch0Data = NSData(bytes: channels[0], length:Int(PCMBuffer.frameLength *
            PCMBuffer.format.streamDescription.pointee.mBytesPerFrame))
        return ch0Data as Data
    }
    
    fileprivate func toPCMBuffer(data: NSData) -> AVAudioPCMBuffer
    {
        
        let PCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(data.length) / (audioFormat!.streamDescription.pointee.mBytesPerFrame))!
        PCMBuffer.frameLength = PCMBuffer.frameCapacity
        
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: Int(PCMBuffer.format.channelCount))
        data.getBytes(UnsafeMutableRawPointer(channels[0]) , length: data.length)
        return PCMBuffer
    }
}
