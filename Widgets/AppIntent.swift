//
//  AppIntent.swift
//  Widgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Input"
    static var description = IntentDescription("See the time and some inputted text.")

    // An example configurable parameter.
    @Parameter(title: "Input", default: "Default")
    var input: String
}
