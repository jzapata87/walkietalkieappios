import UIKit
import AVFoundation
import Foundation
import SocketIO

//import ClusterWS_Client_Swift

class ViewController: UIViewController
{
    var session = AVAudioSession.sharedInstance()
    
    // The audio engine manages the sound system.
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    
    // The player node schedules the playback of the audio buffers.
    private let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    
    // Use standard non-interleaved PCM audio.
    private let audioFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)
        
        //AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 41000, channels: 2, interleaved: true)
        
        //AVAudioFormat(standardFormatWithSampleRate: 48000.0, channels: 2)
    
    private let mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    var manager:SocketManager!
    
    var socketIOClient: SocketIOClient!
    private (set) var audioManager:AudioManager!
    

    //fileprivate let incommingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 48000, channels: 2, interleaved: true)
    
    //let webSocket = ClusterWS(url: "ws://e0ceb300.ngrok.io")
//
//    let session = AVCaptureSession()
//    let mic = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
//    var mic_input: AVCaptureDeviceInput!
//
//    let audio_output = AVCaptureAudioDataOutput()
    
    override func viewDidLoad()
    {
        
        super.viewDidLoad()
        do {
            let desiredNumChannels = 1
            
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
            let maxChannels = session.maximumOutputNumberOfChannels
            
            if maxChannels >= desiredNumChannels {
                try session.setPreferredOutputNumberOfChannels(desiredNumChannels)
            }
            let actualChannelCount = session.outputNumberOfChannels
            print(actualChannelCount)
        } catch let error as NSError {
            print("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }
        
        let output = audioEngine.outputNode
        let outputHWFormat = output.outputFormat(forBus: 0)
        let mainMixer = audioEngine.mainMixerNode
        
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
        audioEngine.connect(mainMixer, to: output, format: outputHWFormat)
        audioEngine.connect(playerNode, to: mainMixer, format: audioFormat)
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine didn't start")
        }
        
       
        // Do any additional setup after loading the view, typically from a nib.
        //webSocket.delegate = self
        //webSocket.connect()

        
        
          ConnectToSocket()
//        setupMicrophone()
//
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func ConnectToSocket() {
        
        manager = SocketManager(socketURL: URL(string: "https://3835cc2b.ngrok.io")!, config: [.log(true), .compress])
        socketIOClient = manager.defaultSocket
        
        socketIOClient.on("news") {data, ack in
            
            print(data[0], "----------------------------------------------")
            guard let binary = data[0] as? NSData else { return }
            //print("start------------------------------")
            //self.audioManager.playData(data: binary)
            //print(binary as NSData, "-----------binary as NSData----------------------")
            //print("end---------------------------------")
            //print(ack)
            //getbsize(binary, <#T##UnsafeMutablePointer<Int>!#>)
            
            //print("count", data.count)
            //print("isrunning", self.audioEngine.isRunning)
            if (data.count  > 0 && self.audioEngine.isRunning)
            {
               
                let buffer = self.toPCMBuffer(data: binary as NSData)
                print(buffer, "----------------------------buffer------------")
                
                self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
                self.playerNode.prepare(withFrameCount: buffer.frameCapacity)
                print(buffer.frameCapacity, "----------------capacity-------------")
                self.playerNode.play()
                print(self.playerNode.isPlaying)
            }else{
                
                self.playerNode.stop()
            }
          
        }
        
        socketIOClient.on(clientEvent: .connect) {data, ack in
            
            //print(data)
            print("socket connected")
            
        }
        
        socketIOClient.on(clientEvent: .error) { (data, eck) in
            //print(data)
            print("socket error")
        }
        
        socketIOClient.on(clientEvent: .disconnect) { (data, eck) in
            //print(data)
            print("socket disconnect")
        }
        
        socketIOClient.on(clientEvent: SocketClientEvent.reconnect) { (data, eck) in
            //print(data)
            print("socket reconnect")
        }
        
        socketIOClient.connect()
    }
    
    fileprivate func toPCMBuffer(data: NSData) -> AVAudioPCMBuffer
    {
        
        let PCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(data.length) / (audioFormat!.streamDescription.pointee.mBytesPerFrame))!
        
        PCMBuffer.frameLength = PCMBuffer.frameCapacity
        
        let pcmFloatChannelData = PCMBuffer.floatChannelData!
        
        let channelCount = Int(PCMBuffer.format.channelCount)
        let frameLength = Int(PCMBuffer.frameLength)
        let stride = PCMBuffer.stride
        
        print(UInt32(data.length), "-----------------top number----------------")
        print(audioFormat!.streamDescription.pointee.mBytesPerFrame, "fm bytes per frame------------------")
        
        var result = Array(repeating: [Float](repeating: 0, count: frameLength), count: channelCount)
        //print("--------------channelcount", channelCount)
        for channel in 0..<channelCount {
            //print("------------framelength-----------", frameLength)
            // Make sure we go through all of the frames...
            for sampleIndex in 0..<frameLength {
                result[channel][sampleIndex] = pcmFloatChannelData[channel][sampleIndex * stride]
                print(pcmFloatChannelData[channel][sampleIndex * stride]*12345678999999999999999999999999)
            }
        }
        
        
        
       

        
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: Int(PCMBuffer.format.channelCount))
        data.getBytes(UnsafeMutableRawPointer(channels[0]) , length: data.length)
        //data.getBytes(UnsafeMutableRawPointer(channels[1]) , length: data.length)
        print(channels[0], "----channel 1-----")
        //print(channels[1], "----channel 2-----")
        print(PCMBuffer, "PCM bufffffer------")
        print(PCMBuffer.format.channelCount, "channel count------")
        return PCMBuffer
    }
    
    
    
    
    
//    func setupMicrophone()
//    {
//
//        let queue = DispatchQueue(label: "AudioSessionQueue", attributes: [])
//        session.sessionPreset = AVCaptureSession.Preset.medium
//        audio_output.setSampleBufferDelegate(self, queue: queue)
//
//        do
//        {
//            mic_input = try AVCaptureDeviceInput(device: mic!)
//        }
//        catch
//        {
//            return
//        }
//
//        session.addInput(mic_input)
//        session.addOutput(audio_output)
//        session.startRunning()
//
//    }
//
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let block = CMSampleBufferGetDataBuffer(sampleBuffer)
        var length = 0
        var data: UnsafeMutablePointer<Int8>? = nil
        let status = CMBlockBufferGetDataPointer(block!, 0, nil, &length, &data)    // TODO: check for errors
        let result = NSData(bytesNoCopy: data!, length: length, freeWhenDone: false)
        //socketIOClient.emit("my other event", result)
        //print(result)
        
        //webSocket.send(event: "greetBack", data: result)
        //print(sampleBuffer)
    }
    //    func onConnect() {
    //        print("connected")
    //    }
    //
    //    func onDisconnect(code: Int, reason: String) {
    //        print(code)
    //    }
    //
    //    func onError(error: Error) {
    //
    //        print(error.localizedDescription)
    //
    //        print(error.localizedDescription)
    //
    //    } AVCaptureAudioDataOutputSampleBufferDelegate
    
    
    
    
}










