//
//  TimePickerView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

struct TimePickerView: View {
    @Binding var duration: TimeInterval
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    var body: some View {
        HStack(spacing: 0) {
            Picker(selection: $hours, label: Text("Hours")) {
                ForEach(0..<24, id: \.self) { hour in
                    Text("\(hour) h").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()
            .onChange(of: hours) { _, _ in
                updateDuration() }
            
            Picker(selection: $minutes, label: Text("Minutes")) {
                ForEach(0..<60, id: \.self) { minute in
                    Text("\(minute) m").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()
            .onChange(of: minutes) { _, _ in
                updateDuration() }
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .onAppear {
            let totalSeconds = Int(duration)
            
            hours = totalSeconds / 3600
            minutes = (totalSeconds % 3600) / 60
        }
    }
    
    private func updateDuration() {
        duration = TimeInterval(hours * 3600 + minutes * 60)
    }
}

extension TimeInterval {
    var formatted: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        return "\(hours > 0 ? "\(hours)h" : "" ) \(minutes > 0 ? "\(minutes)m" : "")"
    }
}


#Preview {
    TimePickerView(duration: .constant(10.0))
}
