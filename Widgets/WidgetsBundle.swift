//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        AudioWidget()
        CountWidget()
        ClockWidget()
        TimerWidget()
        MonthWidget()
        InputWidget()
        ImageWidget()
        
        WeatherWidget()
    }
}
