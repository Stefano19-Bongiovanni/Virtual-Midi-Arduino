//
//  ContentView.swift
//  Virtual Midi Arduino
//
//  Created by Stefano Bongiovanni on 02/04/24.
//

import SwiftUI
import ORSSerial
import CoreMIDI

struct ContentView: View {
    @State private var selectedDeviceIndex: Int = 0
    @State private var midiDevice: VirtualMidi = VirtualMidi()
    @ObservedObject var serialDeviceModel: SerialDeviceModel = SerialDeviceModel()
    
    @ObservedObject var controller: SerialPortController = SerialPortController()
    
    var body: some View {
        VStack {
            HStack {
                Picker( "Select device",selection: $selectedDeviceIndex) {
                    ForEach(0..<serialDeviceModel.serialDevices.count, id: \.self) { index in
                        Text(serialDeviceModel.serialDevices[index].path) // Accessing device via index
                    }
                }
                
                Button(action: startListening) {
                    Text("Start")
                }
            }.padding()
            HStack {
                     
                            if let lastMessage = controller.messages.last {
                                SliderDataRow(sliderData: lastMessage)
                            } else {
                              
                            }
                        }
                        .padding()
            
            List {
                ForEach(controller.messages, id:\.id) {
                    sliderData in  SliderDataRow(sliderData: sliderData)
                }
            }
             
        }
    }
    
   
    
    func startListening(){
        let selectedPort: ORSSerialPort = serialDeviceModel.serialDevices[selectedDeviceIndex]
        //Call start listending and call onEvent
        controller.startListening(selectedPort: selectedPort, callback: midiDevice.sendSliderData)

    }

}

struct SliderDataRow: View {
    var sliderData: SliderData
    
    var body: some View {
        HStack() {
            Text("Values:")
            ForEach(sliderData.values, id: \.self) { value in
                Text("\(value)")
            }
         
        }
        .padding()
    }
}

struct SliderData: Hashable {
    var values: [Int] = []
    var id = UUID()
    
    init?(string: String) {
      
        let components = string.split(separator: "|")
        self.values = components.compactMap{ Int($0) }

        if self.values.isEmpty {
            return nil
        }
    }
    
    
  
    
}



class SerialPortController:  NSObject, ORSSerialPortDelegate, ObservableObject {
    @Published var messages: [SliderData] = []
    
    
     private var receivedMessage: String = ""
    private var callback: (SliderData) -> Void = { _ in }
    
    
    
    
    func startListening(selectedPort: ORSSerialPort, callback: @escaping (SliderData) -> Void) {
        selectedPort.baudRate = 9600
        selectedPort.delegate = self
        self.messages = []
        selectedPort.open()
        
        //Handle callback
        self.callback = callback
        
        
        
    
        
    }
    
    
    
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        if let receivedString = String(data: data, encoding: .ascii) {
            receivedMessage.append(receivedString)
            
                    let lines = self.receivedMessage.components(separatedBy: .newlines)
                    self.receivedMessage = ""
                    for line in lines  {
                        if !line.isEmpty {
                            
                            
                            let nElements = line.split(separator: "|").count
    
                            if nElements == 5 {
                                if let parsed = SliderData(string: line) {
                                    self.messages.append(parsed)
                                    self.callback(parsed)
                                } else {
                                    print("Failed to initialize SliderData")
                                }
                                
                            }
                        }}
                
                

               
           // }
            
        
            } else {
                print("Failed to decode received data.")
            }
        
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
            print("Serial port \(serialPort) encountered an error: \(error)")
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
            print("Opened")
        }
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        print("Closed")
    }
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("Removed from system")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}


class SerialDeviceModel: ObservableObject {
    @Published var serialDevices: [ORSSerialPort] = []
    
    init() {
        listSerialDevices()
    }
    
    // Function to list serial devices
    func listSerialDevices() {
        self.serialDevices = ORSSerialPortManager.shared().availablePorts
    }
    
}
