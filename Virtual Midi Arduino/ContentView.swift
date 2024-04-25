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
                    }.disabled(controller.started)
                    
                    Button(action: startListening) {
                        Text("Start")
                    }.disabled(controller.started)
                }.padding()
                HStack {
                    
                    if let lastMessage = controller.messages.last {
                        SliderDataRow(sliderData: lastMessage)
                    } else {
                        
                    }
                }
                .padding()
                
                HStack {
                    //Send test sliderData
                    Button(action: {
                        let testSliderData = SliderData(string: "100|1022|683|081|853|542|881|1023")
                        midiDevice.sendSliderData( testSliderData! )
                    }) {
                        Text("Send test data")
                    }
                    
          
                    
                }.padding()
                
                
                
            }
        }
        
        
        
        func startListening(){
            let selectedPort: ORSSerialPort = serialDeviceModel.serialDevices[selectedDeviceIndex]
            //Call start listending and call onEvent
            controller.startListening(selectedPort: selectedPort, callback: midiDevice.sendSliderData)
            
        }
        
    }

struct RotatedGauge: View {
    @Binding var val: Double
    @State var MinMax: (min: Double, max: Double) = (0, 1023)
    
    var body: some View {
        VStack {
            Gauge(value: val, in: MinMax.min...MinMax.max) {
                //                Image(systemName: "heart.fill")
                //                    .foregroundColor(.red)
            }
            .frame(width: 160, height: 80) // horizontal size
            .rotationEffect(.degrees(-90))
            .frame(width: 80, height: 160) // resize after rotation
            .tint(Gradient(colors: [.green, .red]))
            .gaugeStyle(.accessoryLinear)
//            .border(Color.white)
            
            Text("\(Int(val))")
        }
    }
}

struct SliderDataRow: View {
    var sliderData: SliderData
    
    var body: some View {
        HStack() {
       
            ForEach(sliderData.values, id: \.self) { value in
                
                RotatedGauge(val: .constant(Double(value)))

            }
            
        }
        .padding()
    }
}

struct SliderData: Hashable {
    var values: [Int] = []
    var id = UUID()
    
    var description: String {
        return "Values: \(values)"
    }
    
    
    
    init?(string: String) {
        
        let components = string.split(separator: "|")
        guard components.count == 8 else {
            return nil
        }
        self.values = components.compactMap{ Int($0) }
        
        if self.values.isEmpty {
            return nil
        }
    }
    
    
    
    
}



class SerialPortController:  NSObject, ORSSerialPortDelegate, ObservableObject {
    @Published var messages: [SliderData] = []
    @Published var started = false
    
    
    
    
    private var receivedMessage: String = ""
    private var loading = false
    private var callback: (SliderData) -> Void = { _ in }
    
    
    
    
    func startListening(selectedPort: ORSSerialPort, callback: @escaping (SliderData) -> Void) {
        selectedPort.baudRate = 9600
        selectedPort.delegate = self
        self.messages = []
        selectedPort.open()
        
        //Handle callback
        self.callback = callback
        started = true
        
        
        
        
        
    }
    
    
    
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        
        for byte in data {
               // Check if byte represents a newline character
               let newline = byte == 0x0A // Assuming newline character is represented by byte value 0x0A (LF)
            let isCarriageReturn = byte == 0x0D // ASCII value for carriage return

                let char = Character(UnicodeScalar(byte))
               //print("Char: \(char) newline: \(newline) isCarriageReturn: \(isCarriageReturn)")
            if (newline) {
                if (loading) {
                    loading = false
                } else {
                    loading = true
                    //print("Received: \(receivedMessage)")
                    let sliderData = SliderData(string: receivedMessage)
                    if (sliderData != nil) {
                        //print("Received: \(sliderData?.values.count ?? 0)")
                        self.messages.append(sliderData!)
                        self.callback(sliderData!)
                    }
                }
                receivedMessage = ""
            } else if (!isCarriageReturn) {
                
                receivedMessage.append(char)
            }
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
