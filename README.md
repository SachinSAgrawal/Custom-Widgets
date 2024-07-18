# Custom Widgets

<p>
<img src="screenshot1.png" alt="screenshot1.png" width="250"/>
<img src="screenshot2.png" alt="screenshot2.png" width="250"/>
<img src="screenshot3.png" alt="screenshot3.png" width="250"/>
</p>

## About
I wanted to create a fancy weather widget for my Lock Screen using OpenWeatherMap's [API](https://openweathermap.org/api), however, I didn't know where to start, so I created all these other (simpler) widgets to learn how to make them and also explore their different capabilities. If you like this app or found it useful, I would appreciate if you starred it or even shared it with your friends. I also don't expect to work on this too much more, as I am quite satisfied with the end result.

## Acknowledgments
Some of the widgets are heavily inspired by [pawello2222's](https://github.com/pawello2222/WidgetExamples) example widgets. However, I have modified a good bit of the syntax such that their widgets are simpler and more concise. Additionally, the fancy weather widget I mentioned earlier was inspired by the [Windy](https://apps.apple.com/us/app/windy-com-weather-radar/id1161387262) weather app's lock screen widget, however, I have improved upon it by adding more detail.

## Usage
If you would like to use the weather widget, please add your OpenWeatherMap API token to line `89` of `WeatherWidget.swift`. You can get a free token [here](https://home.openweathermap.org/subscriptions/unauth_subscribe/onecall_30/base), which allows for up to 1000 calls a day, more than this app will ever make, given that it only updates every half an hour. Also, you must ensure this app and widgets have access to your location such that the weather widget can display the local weather. If the app is unable to determine your location, it will just fall back to New York City. You should be prompted to share your location with the app upon the first install. Please see the list below for the details and functionalities of each specific widget.

## List
There are 8 widgets total, 7 for your home screen and 1 for your lock screen. Screenshots of all widgets are at the top of this file.

#### Home Screen
* Audio Widget - Play, pause, or stop music directly in the background. There is no need to even open the app. The default song is none other than Never Gonna Give You Up by Rick Astley, but this can easily be changed by replacing `song.mp3` inside of `Resources`.
* Count Widget - Interact with buttons to increment or reset a counter. The data is saved locally such that even if the widget is removed, the counter will still persist. Created to learn about App Intents and interactive widgets.
* Clock Widget - Display a clock that shows the time in various formats, including in 12 and 24 hour time and also with seconds. Created to learn about updating entries at a scheduled time, in this case, every minute.
* Timer Widget - Displays the time counting down from 1 minute. The time turns red when there are only 10 seconds left, and once it has ended, the text switches to the word "end". It's kind of an evolution of the clock widget above.
* Month Widget - Displays the current month with dates, where the current one is highlighted. Created to familiarize myself with LazyVGrids and recreate a native widget, but with control over the design and formatting.
* Input Widget - Displays inputted text that can be deep linked. Press and hold on the widget to edit the input text. Tap on the widget to have the text be deep linked and show up within the main app. Created to learn about configuration intents.
* Image Widget - Displays an image in the largest possible widget format, large. Since the audio widget plays Never Gonna Give You Up, this widget fittingly displays an image of Rick Astley from the music video. It can also be swapped out.

#### Lock Screen
* Weather Widget - Displays the 4-day weather forecast for your current location, which is in the top left of the widget. The top right shows your location, but in latitude and longitude, pulled directly from Apple's location services. Note that the location will lag behind every fetch because it relies on the location last saved to user defaults should this current update fail. The bottom left shows the current temperature and conditions, something Windy's does not have. The bottom right also shows the time since the weather was last fetched. If the app is unable to fetch the most recent weather because your device is not connected to WiFi or there is bad cellular service, it will simply keep on ticking until it is once again able to fetch the weather. If it does fetch the weather but all the data is null (and the app shows everything as being 0 with ?s for the condition), it will also try to refetch the weather as soon as it can until the data is no longer null. The middle section of the widget is split into four sections, with each one corresponding to a subsequent day. Below the day of the week are the high and low temperatures for that day, as well as the average condition expected. Underneath that is the percentage chance that it will rain, where one filled raindrop means that there is an additional 20% chance for rain. If none of the raindrops are filled, it should be a day without rain. I have found this to sometimes be slightly inaccurate. This is not an issue with my code but with the data received from the API call. Lastly, the squiggly line behind each day is a rough approximation of what the temperature will look like throughout the day, starting in the morning and extending into the night. Please note that it is only based on the four data points from the API and is being interpolated.

## Installation
1. Clone this repository or download it as a zip folder and uncompress it.
2. Open up the `.xcodeproj` file, which should automatically launch Xcode.
3. You might need to change the signing of the app from the current one.
4. If it is not already selected, choose the `WidgetsExtension` scheme.
5. Click the `Run` button near the top left of Xcode to build and install.
6. To add/view the widgets, please refer to Apple's official [support guide](https://support.apple.com/en-us/118610).

#### Prerequisites
Hopefully this goes without saying, but you need Xcode, which is only available on Macs.

#### Notes
You can run this app on the Xcode simulator or connect a physical device. <br>
The device must be either an iPhone or iPad running iOS 17.0 or newer.

## SDKs
* [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Helps you build great-looking apps across all Apple platforms.
* [WidgetKit](https://developer.apple.com/documentation/widgetkit) - Extend the reach of your app by creating widgets.
* [AppIntents](https://developer.apple.com/documentation/appintents) - Make your app’s actions discoverable with system experiences.
* [Charts](https://developer.apple.com/documentation/charts) - Construct and customize charts on every Apple platform.
* [CoreLocation](https://developer.apple.com/documentation/corelocation/) - Obtain the geographic location and orientation of a device.
* [Combine](https://developer.apple.com/documentation/combine) - Customize handling of asynchronous events using event-processing.

## Bugs
I have not tested this app super rigorously, so I would not be surprised if there some I am unaware of. If you find any, feel free to open up a new issue or even better, create a pull request fixing it.

## Contributors
Sachin Agrawal: I'm a self-taught programmer who knows many languages and I'm into app, game, and web development. For more information, check out my website or Github profile. If you would like to contact me, my email is [github@sachin.email](mailto:github@sachin.email).

## License
This package is licensed under the [MIT License](LICENSE.txt).
