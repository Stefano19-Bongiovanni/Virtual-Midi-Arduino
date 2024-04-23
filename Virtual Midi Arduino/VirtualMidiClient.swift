//
//  VirtualMidiClient.swift
//  Virtual Midi Arduino
//
//  Created by Stefano Bongiovanni on 23/04/24.
//

import Foundation
import CoreMIDI

//Define constant USE_EXTERNAL_DEVICE
let USE_EX = true







class VirtualMidi {
    var midiClient: MIDIClientRef = 0
    var midiOutputPort: MIDIPortRef = 0
    var midiSource: MIDIEndpointRef = 0

 
    
    
    init(){
        print("Midi device initializing")
        let statusClient: OSStatus =  MIDIClientCreate("Virtual Midi Arduino" as CFString, nil, nil, &midiClient)
        print("Status client: ", statusClient)
        print("Client: ", midiClient)
        MIDIOutputPortCreate(midiClient,  "MIDISenderOutputPort" as CFString, &midiOutputPort)
        let statusSource: OSStatus =  MIDISourceCreateWithProtocol(midiClient, "Sorgente Arduino" as CFString, MIDIProtocolID._1_0, &midiSource)
        print("Status source: ", statusSource)
        print("Source: ", midiSource)



        
    }
    
    func sendSliderData(_ sliderData: SliderData){
        guard !sliderData.values.isEmpty else {
            print("Slider data is empty.")
            return
        }
        
        let destination = MIDIGetDestination(0)
        var eventList = MIDIEventList()
        var packet = MIDIEventPacket()
        
        

        //https://www.songstuff.com/recording/article/midi-message-format/
        eventList.numPackets = 1
        for (index, value) in sliderData.values.enumerated() {
            
            
            let convertedValue: UInt8 = UInt8(value / 8)
            //let message: MIDIMessage_32 = MIDI1UPControlChange(0 as UInt8, 0 as UInt8, UInt8(index), convertedValue)
            
            print("Adding event ", index, "with value ", convertedValue)
            let controllerNumber = UInt8(20 + index)
            let data: [UInt8] = [0xB0, controllerNumber, UInt8(value % 128)]
            let uint32Data = data.map { UInt32($0) }
            
            packet = MIDIEventListAdd(&eventList, 1024, &packet, 0, uint32Data.count, uint32Data).pointee
        }
        
        
        
        MIDISendEventList(midiOutputPort, destination, &eventList)
        
        
    }
    
    deinit {

     
        print("Deinit")
        MIDIClientDispose(midiClient)
        MIDIPortDispose(midiOutputPort)

        
    }
    
}

