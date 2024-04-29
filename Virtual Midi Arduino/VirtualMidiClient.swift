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


let messages: [UInt8]  = [
    
    0x0C, //Effect Control 1
    0x0D, //Effect Control 2
    
    0x10, //General Purpose Slider 1
    0x11, //General Purpose Slider 2
    0x12, //General Purpose Slider 3
    0x13, //General Purpose Slider 4
    0x50, //General Purpose Slider 5
    
    
    0x07 // Volume
    

]




class VirtualMidi {
    var midiClient: MIDIClientRef = 0
    var midiOutputPort: MIDIPortRef = 0
    var midiInputPort: MIDIPortRef = 0
    var midiSource: MIDIEndpointRef = 0
    
    var midiPacketList: MIDIPacketList = MIDIPacketList()
    var midiCurPacket: UnsafeMutablePointer<MIDIPacket>? = nil
    
    var lastSent: [UInt8] = [0,0,0,0,0,0,0,0]
 
    

    
    init(){
        print("Midi device initializing")
        let statusClient: OSStatus =  MIDIClientCreate("Virtual Midi Arduino" as CFString, nil, nil, &midiClient)
        print("Status client: ", statusClient)
        print("Client: ", midiClient)
        MIDIOutputPortCreate(midiClient,  "MIDISenderOutputPort" as CFString, &midiOutputPort)
        MIDIInputPortCreateWithProtocol(midiClient, "MIDISenderInputPort" as CFString, MIDIProtocolID._1_0, &midiInputPort, receiveBlock)
        
        let statusSource: OSStatus =  MIDISourceCreateWithProtocol(midiClient, "Sorgente Arduino" as CFString, MIDIProtocolID._1_0, &midiSource)
        print("Status source: ", statusSource)
        print("Source: ", midiSource)
        
        initPacketList()
  
    }
    
    
    
 var  receiveBlock: MIDIReceiveBlock = { eventList, context in
     // Your code to handle MIDI events
     print("Received MIDI event")
     print("Event list: ", eventList)
 }
    
    func initPacketList(){
        midiCurPacket = MIDIPacketListInit(&midiPacketList)
    }
    
    func addControlpacket(controlNumber: UInt8, controlValue: UInt8){
            
        let packet: [UInt8] = [0xB0, controlNumber, controlValue]
        midiCurPacket = MIDIPacketListAdd(&midiPacketList, 512, midiCurPacket!, 0, 3, packet)
        //print("Packet added", packet, "curPacket: ", midiCurPacket as Any)
    }
    // "send" a packet, really pretends that our virtual device source received a packet
    func sendPacketList(){
        let statusSend: OSStatus = MIDIReceived(midiSource, &midiPacketList)
        //print("Status send: ", statusSend)
        if statusSend != 0 {
            print("Error sending packet")
        }
        initPacketList()
    }
    

    

    
    
    func sendSliderData(_ sliderData: SliderData){
        guard !sliderData.values.isEmpty else {
            //print("Slider data is empty.")
            return
        }
        
        
        func convertValueToUInt8(_ value: Int) -> UInt8 {
            if (value < 0) {
                return UInt8(0)
            }
            if (value > 1023) {
                return UInt8(127)
            }
            
            //Convert from 0-1023 to 0-127
            return UInt8(value / 8)
        }
  
        
        func createRandomFrom127() -> UInt8 {
            return UInt8.random(in: 0...127)
        }

        //https://www.songstuff.com/recording/article/midi-message-format/
        
        
        
        var sendNumber = 0
        for (index, value) in sliderData.values.enumerated() {
            

            let controlValue: UInt8 = convertValueToUInt8(value)
            if controlValue == lastSent[index] {
                continue
            }
            let controlNumber: UInt8 = messages[index]
            addControlpacket(controlNumber: controlNumber, controlValue: controlValue)
            sendNumber += 1
            lastSent[index] = controlValue
            
        }
        if sendNumber > 0 {
            sendPacketList()
        }
        sendPacketList()
        
        

      
  
    }
    
    deinit {

     
        print("Deinit")
        MIDIClientDispose(midiClient)
        MIDIPortDispose(midiOutputPort)
        MIDIEndpointDispose(midiSource)
        

        
    }
    
}

