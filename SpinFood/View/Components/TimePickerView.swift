//
//  TimePickerView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

struct TimePickerView: View {
    @Binding var duration: TimeInterval

    // The wheels read and write `duration` directly. They used to copy it into their own state when
    // they appeared, which happened before the recipe's time was loaded, and then wrote the default
    // (5 min) back over it, so saving any edit could change a recipe's time.
    private var hours: Binding<Int> {
        Binding(
            get: { Int(duration) / 3600 },
            set: { duration = TimeInterval($0 * 3600 + (Int(duration) % 3600) / 60 * 60) }
        )
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { (Int(duration) % 3600) / 60 },
            set: { duration = TimeInterval((Int(duration) / 3600) * 3600 + $0 * 60) }
        )
    }

    var body: some View {
        wheels
            // Only the wheels themselves: dragging them sideways never turns the book's page.
            .blocksPageAndSheetDrags()
            .frame(maxWidth: .infinity, maxHeight: 200)
    }

    private var wheels: some View {
        HStack(spacing: 0) {
            Picker(selection: hours, label: Text("Hours")) {
                ForEach(0..<24, id: \.self) { hour in
                    Text("\(hour) h").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()

            Picker(selection: minutes, label: Text("Minutes")) {
                ForEach(0..<60, id: \.self) { minute in
                    Text("\(minute) m").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()
        }
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
