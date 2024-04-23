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
    var midiDevice: MIDIDeviceRef = 0
    var midiEntity: MIDIEntityRef = 0
 
    
    
    init(){
        print("Midi device initializing")
        MIDIClientCreate("Virtual Midi Arduino" as CFString, nil, nil, &midiClient)
        MIDIOutputPortCreate(midiClient,  "MIDISenderOutputPort" as CFString, &midiOutputPort)
        
        //create a virtual device
        var statusDevice: OSStatus
        if (USE_EX) {
            statusDevice = MIDIExternalDeviceCreate("Virtual Midi Arduino External" as CFString, "Stefano19" as CFString, "Arduino Micro" as CFString, &midiDevice)
        } else {
            statusDevice = MIDIDeviceCreate(nil, "Virtual Midi Arduino" as CFString, "Stefano19" as CFString, "Arduino Micro" as CFString, &midiDevice)
        }
        print("Status : ", statusDevice)
        print("Device: ", midiDevice)
        let statusEntity: OSStatus = MIDIDeviceNewEntity(midiDevice, "Entità 1" as CFString, MIDIProtocolID._1_0, true, 1, 1, &midiEntity)
        print("Status : ", statusEntity)
        print("Entity: ", midiEntity)
        
        
        
        
        
        
        
        if (USE_EX) {
            MIDISetupAddExternalDevice(midiDevice)
        } else {
            MIDISetupAddDevice(midiDevice)
        }
        
        MIDIRestart()
        
        
        //List all devices
        let numberOfDevices = MIDIGetNumberOfDevices()
        print("Number of devices: ", numberOfDevices)
        for i in 0..<numberOfDevices {
            let device = MIDIGetDevice(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name)
            print("Device ", i, ": ", name!.takeRetainedValue(), " (", device, ")")
        }
        

        
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
        print("Midi device deinitializing")
        
        if (USE_EX) {
            MIDISetupRemoveExternalDevice(midiDevice)
        } else {
            MIDISetupRemoveDevice(midiDevice)
        }
        
        MIDIClientDispose(midiClient)
        MIDIPortDispose(midiOutputPort)
        MIDIDeviceDispose(midiDevice)
        
    }
    
}

