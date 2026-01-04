import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root

    property bool nightModeEnabled: false
    property double latitude: 40.7128  // Default: New York
    property double longitude: -74.0060  // Default: New York
    property bool isChangingState: false
    property string mode: "auto" // "auto" or "manual"
    property int temperature: 4000  // Color temperature in Kelvin (2500-6000)
    
    // Calculated sunrise/sunset times (in minutes since midnight)
    property int sunriseMinutes: 0
    property int sunsetMinutes: 0
    
    // Custom time settings (in minutes since midnight)
    property bool useCustomTimes: false  // Use custom times instead of sunrise/sunset
    property int customStartTime: 1260  // Default: 9:00 PM (21:00 = 21*60 = 1260)
    property int customEndTime: 420  // Default: 7:00 AM (7*60 = 420)
    
    // Current time in minutes since midnight
    property int currentMinutes: 0
    
    onNightModeEnabledChanged: {
        console.log("Night mode changed to:", nightModeEnabled)
    }
    
    // Popout content for location settings
    popoutContent: Component {
        PopoutComponent {
            id: popout
            
            headerText: "Night Light"
            detailsText: root.mode === "auto" ? "Automatically enables night mode at sunset and disables at sunrise based on your location" : "Manually control night mode on/off"
            showCloseButton: true
            
            Column {
                width: parent.width
                spacing: Theme.spacingS
                
                // Mode selection buttons
                StyledRect {
                    width: parent.width
                    height: 44
                    color: autoMouseArea.containsMouse ? Theme.surfaceContainerHighest : (root.mode === "auto" ? Theme.primary : Theme.surfaceContainerHigh)
                    radius: Theme.cornerRadius
                    border.width: 0
                    
                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Auto (Sunrise/Sunset)"
                        color: root.mode === "auto" ? Theme.onPrimary : Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    
                    MouseArea {
                        id: autoMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.mode = "auto"
                        }
                    }
                }
                
                StyledRect {
                    width: parent.width
                    height: 44
                    color: manualMouseArea.containsMouse ? Theme.surfaceContainerHighest : (root.mode === "manual" ? Theme.primary : Theme.surfaceContainerHigh)
                    radius: Theme.cornerRadius
                    border.width: 0
                    
                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Manual (On/Off)"
                        color: root.mode === "manual" ? Theme.onPrimary : Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    
                    MouseArea {
                        id: manualMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.mode = "manual"
                        }
                    }
                }
                
                // Manual toggle button
                StyledRect {
                    width: parent.width
                    height: 44
                    visible: root.mode === "manual"
                    color: toggleMouseArea.containsMouse ? Theme.surfaceContainerHighest : (root.nightModeEnabled ? Theme.primary : Theme.surfaceContainerHigh)
                    radius: Theme.cornerRadius
                    border.width: 0
                    
                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.nightModeEnabled ? "Disable Night Mode" : "Enable Night Mode"
                        color: root.nightModeEnabled ? Theme.onPrimary : Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    
                    MouseArea {
                        id: toggleMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.handleClick()
                        }
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }
                
                // Color Temperature (available in both modes)
                StyledText {
                    width: parent.width
                    text: "Color Temperature"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
                
                StyledText {
                    width: parent.width
                    text: root.temperature + " K"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primary
                }
                
                // Temperature slider
                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    
                    StyledText {
                        text: "2500K"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        id: temperatureSlider
                        width: parent.width - 120
                        from: 2500
                        to: 6000
                        stepSize: 100
                        value: root.temperature
                        
                        property bool isUserDragging: false
                        
                        onPressedChanged: {
                            isUserDragging = pressed
                        }
                        
                        onMoved: {
                            var newTemp = Math.round(value / 100) * 100
                            if (newTemp !== root.temperature) {
                                root.setTemperature(newTemp)
                            }
                        }
                        
                        background: Rectangle {
                            x: temperatureSlider.leftPadding
                            y: temperatureSlider.topPadding + temperatureSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: temperatureSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: Theme.surfaceContainerHigh
                            
                            Rectangle {
                                width: temperatureSlider.visualPosition * parent.width
                                height: parent.height
                                color: Theme.primary
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: temperatureSlider.leftPadding + temperatureSlider.visualPosition * (temperatureSlider.availableWidth - width)
                            y: temperatureSlider.topPadding + temperatureSlider.availableHeight / 2 - height / 2
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: temperatureSlider.pressed ? Theme.primary : Theme.surfaceContainerHighest
                            border.color: Theme.primary
                            border.width: 2
                        }
                    }
                    
                    StyledText {
                        text: "6000K"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    visible: root.mode === "auto"
                }
                
                // Location settings (only shown in auto mode)
                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.mode === "auto"
                    
                    StyledText {
                        width: parent.width
                        text: "Location Settings"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }
                    
                    StyledText {
                        width: parent.width
                        text: "Search by city name or enter coordinates manually"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                    
                    // City search
                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS
                        
                        StyledText {
                            text: "Search City"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                        
                        StyledText {
                            text: "e.g., New York, London, Tokyo"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        
                        Row {
                            width: parent.width
                            spacing: Theme.spacingS
                            
                            StyledRect {
                                width: parent.width - 80
                                height: 40
                                color: Theme.surfaceContainerHigh
                                radius: Theme.cornerRadius
                                border.width: 1
                                border.color: cityInput.activeFocus ? Theme.primary : Theme.outlineVariant
                                
                                TextInput {
                                    id: cityInput
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    selectByMouse: true
                                    
                                    onAccepted: {
                                        if (text.trim() !== "") {
                                            root.searchCity(text.trim())
                                        }
                                    }
                                }
                            }
                            
                            StyledRect {
                                width: 70
                                height: 40
                                color: searchButtonMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.primary
                                radius: Theme.cornerRadius
                                border.width: 0
                                
                                StyledText {
                                    anchors.centerIn: parent
                                    text: geocodeProcess.running ? "..." : "Search"
                                    color: Theme.onPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                                
                                MouseArea {
                                    id: searchButtonMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (cityInput.text.trim() !== "" && !geocodeProcess.running) {
                                            root.searchCity(cityInput.text.trim())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outlineVariant
                    }
                    
                    StyledText {
                        width: parent.width
                        text: "Or enter coordinates manually:"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                    
                    // Latitude input
                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS
                        
                        StyledText {
                            text: "Latitude"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                        
                        StyledRect {
                            width: parent.width
                            height: 40
                            color: Theme.surfaceContainerHigh
                            radius: Theme.cornerRadius
                            border.width: 1
                            border.color: latInput.activeFocus ? Theme.primary : Theme.outlineVariant
                            
                            TextInput {
                                id: latInput
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.latitude.toFixed(6)
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                selectByMouse: true
                                validator: DoubleValidator {
                                    bottom: -90
                                    top: 90
                                    decimals: 6
                                }
                                
                                onAccepted: {
                                    var val = parseFloat(text)
                                    if (!isNaN(val) && val >= -90 && val <= 90) {
                                        root.latitude = val
                                        root.saveLocationSettings()
                                    } else {
                                        text = root.latitude.toFixed(6)
                                    }
                                }
                                
                                onEditingFinished: {
                                    var val = parseFloat(text)
                                    if (!isNaN(val) && val >= -90 && val <= 90) {
                                        root.latitude = val
                                        root.saveLocationSettings()
                                    } else {
                                        text = root.latitude.toFixed(6)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Longitude input
                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS
                        
                        StyledText {
                            text: "Longitude"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                        
                        StyledRect {
                            width: parent.width
                            height: 40
                            color: Theme.surfaceContainerHigh
                            radius: Theme.cornerRadius
                            border.width: 1
                            border.color: lonInput.activeFocus ? Theme.primary : Theme.outlineVariant
                            
                            TextInput {
                                id: lonInput
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.longitude.toFixed(6)
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                selectByMouse: true
                                validator: DoubleValidator {
                                    bottom: -180
                                    top: 180
                                    decimals: 6
                                }
                                
                                onAccepted: {
                                    var val = parseFloat(text)
                                    if (!isNaN(val) && val >= -180 && val <= 180) {
                                        root.longitude = val
                                        root.saveLocationSettings()
                                    } else {
                                        text = root.longitude.toFixed(6)
                                    }
                                }
                                
                                onEditingFinished: {
                                    var val = parseFloat(text)
                                    if (!isNaN(val) && val >= -180 && val <= 180) {
                                        root.longitude = val
                                        root.saveLocationSettings()
                                    } else {
                                        text = root.longitude.toFixed(6)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Save button
                    StyledRect {
                        width: parent.width
                        height: 44
                        color: saveButtonMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.primary
                        radius: Theme.cornerRadius
                        border.width: 0
                        
                        StyledText {
                            anchors.centerIn: parent
                            text: "Save Location"
                            color: Theme.onPrimary
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        
                        MouseArea {
                            id: saveButtonMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var latVal = parseFloat(latInput.text)
                                var lonVal = parseFloat(lonInput.text)
                                
                                if (!isNaN(latVal) && latVal >= -90 && latVal <= 90 &&
                                    !isNaN(lonVal) && lonVal >= -180 && lonVal <= 180) {
                                    root.latitude = latVal
                                    root.longitude = lonVal
                                    root.saveLocationSettings()
                                }
                            }
                        }
                    }
                    
                    StyledText {
                        width: parent.width
                        text: "Or use DMS IPC: dms ipc call night location <lat> <lon>"
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: "monospace"
                        color: Theme.primary
                        wrapMode: Text.WordWrap
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outlineVariant
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outlineVariant
                    }
                    
                    StyledText {
                        width: parent.width
                        text: "Time Settings"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }
                    
                    // Toggle between sunrise/sunset and custom times
                    StyledRect {
                        width: parent.width
                        height: 44
                        color: customTimesMouseArea.containsMouse ? Theme.surfaceContainerHighest : (root.useCustomTimes ? Theme.primary : Theme.surfaceContainerHigh)
                        radius: Theme.cornerRadius
                        border.width: 0
                        
                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Use Custom Times"
                            color: root.useCustomTimes ? Theme.onPrimary : Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        
                        MouseArea {
                            id: customTimesMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.useCustomTimes = !root.useCustomTimes
                                root.saveTimeSettings()
                                if (root.mode === "auto") {
                                    checkAndUpdateNightMode()
                                }
                            }
                        }
                    }
                    
                    // Custom time inputs (shown when useCustomTimes is true)
                    Column {
                        width: parent.width
                        spacing: Theme.spacingM
                        visible: root.useCustomTimes
                        
                        StyledText {
                            width: parent.width
                            text: "Set custom start and end times for night mode"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                        }
                        
                        // Start time input
                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS
                            
                            StyledText {
                                text: "Start Time (when night mode enables)"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }
                            
                            StyledRect {
                                width: parent.width
                                height: 40
                                color: Theme.surfaceContainerHigh
                                radius: Theme.cornerRadius
                                border.width: 1
                                border.color: startTimeInput.activeFocus ? Theme.primary : Theme.outlineVariant
                                
                                TextInput {
                                    id: startTimeInput
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    selectByMouse: true
                                    
                                    Component.onCompleted: {
                                        var hours = Math.floor(root.customStartTime / 60) % 24
                                        var mins = root.customStartTime % 60
                                        text = hours.toString().padStart(2, '0') + ":" + mins.toString().padStart(2, '0')
                                    }
                                    
                                    onAccepted: {
                                        var parts = text.split(":")
                                        if (parts.length === 2) {
                                            var hours = parseInt(parts[0])
                                            var mins = parseInt(parts[1])
                                            if (!isNaN(hours) && !isNaN(mins) && hours >= 0 && hours < 24 && mins >= 0 && mins < 60) {
                                                var time = hours * 60 + mins
                                                root.customStartTime = time
                                                root.saveTimeSettings()
                                                if (root.mode === "auto") {
                                                    root.checkAndUpdateNightMode()
                                                }
                                            } else {
                                                var h = Math.floor(root.customStartTime / 60) % 24
                                                var m = root.customStartTime % 60
                                                text = h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0')
                                            }
                                        }
                                    }
                                    
                                    onEditingFinished: {
                                        var parts = text.split(":")
                                        if (parts.length === 2) {
                                            var hours = parseInt(parts[0])
                                            var mins = parseInt(parts[1])
                                            if (!isNaN(hours) && !isNaN(mins) && hours >= 0 && hours < 24 && mins >= 0 && mins < 60) {
                                                var time = hours * 60 + mins
                                                root.customStartTime = time
                                                root.saveTimeSettings()
                                                if (root.mode === "auto") {
                                                    root.checkAndUpdateNightMode()
                                                }
                                            } else {
                                                var h = Math.floor(root.customStartTime / 60) % 24
                                                var m = root.customStartTime % 60
                                                text = h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0')
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // End time input
                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS
                            
                            StyledText {
                                text: "End Time (when night mode disables)"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }
                            
                            StyledRect {
                                width: parent.width
                                height: 40
                                color: Theme.surfaceContainerHigh
                                radius: Theme.cornerRadius
                                border.width: 1
                                border.color: endTimeInput.activeFocus ? Theme.primary : Theme.outlineVariant
                                
                                TextInput {
                                    id: endTimeInput
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    selectByMouse: true
                                    
                                    Component.onCompleted: {
                                        var hours = Math.floor(root.customEndTime / 60) % 24
                                        var mins = root.customEndTime % 60
                                        text = hours.toString().padStart(2, '0') + ":" + mins.toString().padStart(2, '0')
                                    }
                                    
                                    onAccepted: {
                                        var parts = text.split(":")
                                        if (parts.length === 2) {
                                            var hours = parseInt(parts[0])
                                            var mins = parseInt(parts[1])
                                            if (!isNaN(hours) && !isNaN(mins) && hours >= 0 && hours < 24 && mins >= 0 && mins < 60) {
                                                var time = hours * 60 + mins
                                                root.customEndTime = time
                                                root.saveTimeSettings()
                                                if (root.mode === "auto") {
                                                    root.checkAndUpdateNightMode()
                                                }
                                            } else {
                                                var h = Math.floor(root.customEndTime / 60) % 24
                                                var m = root.customEndTime % 60
                                                text = h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0')
                                            }
                                        }
                                    }
                                    
                                    onEditingFinished: {
                                        var parts = text.split(":")
                                        if (parts.length === 2) {
                                            var hours = parseInt(parts[0])
                                            var mins = parseInt(parts[1])
                                            if (!isNaN(hours) && !isNaN(mins) && hours >= 0 && hours < 24 && mins >= 0 && mins < 60) {
                                                var time = hours * 60 + mins
                                                root.customEndTime = time
                                                root.saveTimeSettings()
                                                if (root.mode === "auto") {
                                                    root.checkAndUpdateNightMode()
                                                }
                                            } else {
                                                var h = Math.floor(root.customEndTime / 60) % 24
                                                var m = root.customEndTime % 60
                                                text = h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0')
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sunrise/Sunset info (shown when NOT using custom times)
                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS
                        visible: !root.useCustomTimes
                        
                        StyledText {
                            width: parent.width
                            text: "Sunrise: " + root.formatTime(root.sunriseMinutes)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        
                        StyledText {
                            width: parent.width
                            text: "Sunset: " + root.formatTime(root.sunsetMinutes)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outlineVariant
                    }
                    
                    StyledText {
                        width: parent.width
                        text: "Current Status"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }
                    
                    StyledText {
                        width: parent.width
                        text: "Night Mode: " + (root.nightModeEnabled ? "Enabled" : "Disabled")
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.nightModeEnabled ? Theme.primary : Theme.surfaceVariantText
                    }
                    
                    StyledText {
                        width: parent.width
                        text: "Current: " + root.formatTime(root.currentMinutes)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                    
                    StyledText {
                        width: parent.width
                        text: root.useCustomTimes ? 
                              ("Night mode: " + root.formatTime(root.customStartTime) + " - " + root.formatTime(root.customEndTime)) :
                              ("Night mode: " + root.formatTime(root.sunsetMinutes) + " - " + root.formatTime(root.sunriseMinutes))
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                    
                }
            }
        }
    }

    // Bar indicator for horizontal bar
    horizontalBarPill: Component {
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.handleClick()
            }
            
            DankIcon {
                anchors.centerIn: parent
                name: "nightlight"
                color: root.nightModeEnabled ? Theme.primary : Theme.surfaceText
                size: 20
                opacity: root.nightModeEnabled ? 1.0 : 0.3
            }
        }
    }

    // Bar indicator for vertical bar
    verticalBarPill: Component {
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.handleClick()
            }
            
            DankIcon {
                anchors.centerIn: parent
                name: "nightlight"
                color: root.nightModeEnabled ? Theme.primary : Theme.surfaceText
                size: 20
                opacity: root.nightModeEnabled ? 1.0 : 0.3
            }
        }
    }

    // Timer to check current time and update night mode
    Timer {
        id: checkTimer
        interval: 60000 // Check every minute
        running: true
        repeat: true
        onTriggered: {
            // Update location from pluginData if available
            if (pluginData) {
                if (pluginData.latitude !== undefined && pluginData.latitude !== root.latitude) {
                    root.latitude = pluginData.latitude
                }
                if (pluginData.longitude !== undefined && pluginData.longitude !== root.longitude) {
                    root.longitude = pluginData.longitude
                }
            }
            
            updateCurrentTime()
            if (root.mode === "auto") {
                calculateSunriseSunset()
                checkAndUpdateNightMode()
            }
        }
    }

    // Process to get night mode status
    Process {
        id: statusProcess
        command: ["dms", "ipc", "call", "night", "status"]

        property string output: ""

        stdout: SplitParser {
            onRead: line => {
                statusProcess.output += line + "\n"
            }
        }

        onExited: {
            var trimmed = statusProcess.output.trim().toLowerCase()
            // Parse status - typically returns something like "enabled" or "disabled"
            var isEnabled = trimmed.includes("enabled") || trimmed.includes("true") || trimmed === "1"
            
            if (isEnabled !== root.nightModeEnabled && !root.isChangingState) {
                root.nightModeEnabled = isEnabled
            }
            statusProcess.output = ""
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.trim()) {
                    console.warn("Night status error:", line)
                }
            }
        }
    }

    // Process to enable night mode
    Process {
        id: enableProcess
        command: ["dms", "ipc", "call", "night", "enable"]

        stdout: SplitParser {
            onRead: line => {
                console.log("Night enable response:", line)
            }
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.trim()) {
                    console.error("Night enable error:", line)
                }
            }
        }

        onExited: (exitCode) => {
            if (exitCode === 0) {
                console.log("Night mode successfully enabled")
                root.nightModeEnabled = true
            } else {
                console.error("Failed to enable night mode, exit code:", exitCode)
            }
            root.isChangingState = false
        }
    }

    // Process to disable night mode
    Process {
        id: disableProcess
        command: ["dms", "ipc", "call", "night", "disable"]

        stdout: SplitParser {
            onRead: line => {
                console.log("Night disable response:", line)
            }
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.trim()) {
                    console.error("Night disable error:", line)
                }
            }
        }

        onExited: (exitCode) => {
            if (exitCode === 0) {
                console.log("Night mode successfully disabled")
                root.nightModeEnabled = false
            } else {
                console.error("Failed to disable night mode, exit code:", exitCode)
            }
            root.isChangingState = false
        }
    }

    // Process to set location via IPC
    Process {
        id: locationProcess
        command: [] // Will be set dynamically

        stdout: SplitParser {
            onRead: line => {
                console.log("Location set response:", line)
            }
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.trim()) {
                    console.warn("Location set error:", line)
                }
            }
        }
    }
    
    function setLocationViaIPC() {
        // Use -- to separate flags from arguments, preventing negative numbers from being interpreted as flags
        locationProcess.command = ["dms", "ipc", "call", "night", "location", "--", root.latitude.toString(), root.longitude.toString()]
        locationProcess.running = true
    }

    // Process to get temperature
    Process {
        id: temperatureGetProcess
        command: ["dms", "ipc", "call", "night", "temperature"]

        property string output: ""

        stdout: SplitParser {
            onRead: line => {
                temperatureGetProcess.output += line + "\n"
            }
        }

        onExited: {
            var trimmed = temperatureGetProcess.output.trim()
            // Try to extract temperature value (could be just a number or "temperature: 4000" format)
            var tempMatch = trimmed.match(/(\d+)/)
            if (tempMatch) {
                var temp = parseInt(tempMatch[1])
                if (!isNaN(temp) && temp >= 2500 && temp <= 6000) {
                    root.temperature = temp
                }
            }
            temperatureGetProcess.output = ""
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.trim()) {
                    console.warn("Temperature get error:", line)
                }
            }
        }
    }

    // Process to set temperature
    Process {
        id: temperatureSetProcess
        command: [] // Will be set dynamically

        stdout: SplitParser {
            onRead: line => {
                console.log("Temperature set response:", line)
            }
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.trim()) {
                    console.warn("Temperature set error:", line)
                }
            }
        }
    }

    // Process to geocode city name
    Process {
        id: geocodeProcess
        
        property string output: ""
        property string currentCity: ""
        command: [] // Initialize with empty command

        stdout: SplitParser {
            onRead: line => {
                geocodeProcess.output += line + "\n"
            }
        }

        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    var jsonData = JSON.parse(geocodeProcess.output.trim())
                    if (jsonData && jsonData.length > 0) {
                        var result = jsonData[0]
                        var lat = parseFloat(result.lat)
                        var lon = parseFloat(result.lon)
                        
                        if (!isNaN(lat) && !isNaN(lon)) {
                            root.latitude = lat
                            root.longitude = lon
                            root.saveLocationSettings()
                            console.log("City geocoded: " + geocodeProcess.currentCity + " -> " + lat + ", " + lon)
                        } else {
                            console.error("Failed to parse coordinates from geocoding response")
                        }
                    } else {
                        console.warn("No results found for city: " + geocodeProcess.currentCity)
                    }
                } catch (e) {
                    console.error("Failed to parse geocoding response:", e, geocodeProcess.output)
                }
            } else {
                console.error("Geocoding failed with exit code:", exitCode)
            }
            geocodeProcess.output = ""
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.trim()) {
                    console.warn("Geocoding error:", line)
                }
            }
        }
    }

    function updateCurrentTime() {
        var now = new Date()
        root.currentMinutes = now.getHours() * 60 + now.getMinutes()
    }

    function calculateSunriseSunset() {
        // Calculate sunrise and sunset using astronomical algorithms
        // Based on NOAA's algorithm for solar position calculations
        
        // Only calculate if we have valid coordinates
        if (root.latitude === 0 && root.longitude === 0) {
            console.warn("Cannot calculate sunrise/sunset: coordinates not set")
            return
        }
        
        try {
            var now = new Date()
            var year = now.getFullYear()
            var month = now.getMonth() + 1
            var day = now.getDate()
            
            // Calculate day of year
            var dayOfYear = getDayOfYear(year, month, day)
            
            // Calculate solar declination (in radians)
            var declination = 23.45 * Math.sin((360 * (284 + dayOfYear) / 365) * Math.PI / 180) * Math.PI / 180
            
            // Calculate equation of time (in minutes)
            var B = (360 / 365) * (dayOfYear - 81) * Math.PI / 180
            var equationOfTime = 9.87 * Math.sin(2 * B) - 7.53 * Math.cos(B) - 1.5 * Math.sin(B)
            
            // Calculate solar noon (in minutes from midnight, local time)
            // Solar noon occurs when the sun is at its highest point
            // Account for equation of time and longitude offset from timezone meridian
            // Approximate timezone meridian from system timezone offset
            var now2 = new Date()
            var timezoneOffsetHours = -now2.getTimezoneOffset() / 60  // System timezone offset in hours
            var timezoneMeridian = timezoneOffsetHours * 15  // Approximate timezone meridian (degrees)
            var longitudeOffset = (root.longitude - timezoneMeridian) * 4 / 60  // Offset in hours
            var solarNoon = 12.0 - longitudeOffset - equationOfTime / 60  // In hours
            
            // Convert to minutes
            var solarNoonMinutes = solarNoon * 60
            
            // Calculate hour angle (when sun is at horizon)
            var latRad = root.latitude * Math.PI / 180
            var cosHourAngle = -Math.tan(latRad) * Math.tan(declination)
            
            // Handle polar day/night cases
            if (cosHourAngle > 1) {
                // Sun never sets (polar day)
                root.sunriseMinutes = 0
                root.sunsetMinutes = 1439
                console.log("Polar day detected - sun never sets")
                return
            }
            if (cosHourAngle < -1) {
                // Sun never rises (polar night)
                root.sunriseMinutes = 720
                root.sunsetMinutes = 720
                console.log("Polar night detected - sun never rises")
                return
            }
            
            // Calculate hour angle in degrees
            var hourAngle = Math.acos(cosHourAngle) * 180 / Math.PI
            
            // Convert hour angle to time (1 degree = 4 minutes)
            var timeOffset = hourAngle * 4
            
            // Calculate sunrise and sunset (in minutes from midnight)
            root.sunriseMinutes = Math.round(solarNoonMinutes - timeOffset)
            root.sunsetMinutes = Math.round(solarNoonMinutes + timeOffset)
            
            // Normalize to 0-1439 (minutes in a day)
            while (root.sunriseMinutes < 0) root.sunriseMinutes += 1440
            while (root.sunriseMinutes >= 1440) root.sunriseMinutes -= 1440
            while (root.sunsetMinutes < 0) root.sunsetMinutes += 1440
            while (root.sunsetMinutes >= 1440) root.sunsetMinutes -= 1440
            
            // Validate and log
            var sunriseHour = Math.floor(root.sunriseMinutes / 60)
            var sunsetHour = Math.floor(root.sunsetMinutes / 60)
            
            if (sunriseHour < 3 || sunriseHour > 11 || sunsetHour < 14 || sunsetHour > 23) {
                console.warn("Calculated sunrise/sunset times seem unusual. Sunrise:", root.formatTime(root.sunriseMinutes), 
                            "Sunset:", root.formatTime(root.sunsetMinutes), "Check your location coordinates.")
            } else {
                console.log("Sunrise:", root.formatTime(root.sunriseMinutes), "Sunset:", root.formatTime(root.sunsetMinutes), 
                           "Current:", root.formatTime(root.currentMinutes))
            }
        } catch (e) {
            console.error("Error calculating sunrise/sunset:", e)
            // Set default values on error
            root.sunriseMinutes = 420  // 7:00 AM
            root.sunsetMinutes = 1260  // 9:00 PM
        }
    }
    
    function getDayOfYear(year, month, day) {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        // Check for leap year
        if ((year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0)) {
            daysInMonth[1] = 29
        }
        var dayOfYear = day
        for (var i = 0; i < month - 1; i++) {
            dayOfYear += daysInMonth[i]
        }
        return dayOfYear
    }

    function formatTime(minutes) {
        var hours = Math.floor(minutes / 60) % 24
        var mins = minutes % 60
        var period = hours >= 12 ? "PM" : "AM"
        var displayHours = hours % 12
        if (displayHours === 0) displayHours = 12
        return displayHours.toString().padStart(2, '0') + ":" + mins.toString().padStart(2, '0') + " " + period
    }
    
    function formatTimeForInput(minutes) {
        var hours = Math.floor(minutes / 60) % 24
        var mins = minutes % 60
        return hours.toString().padStart(2, '0') + ":" + mins.toString().padStart(2, '0')
    }
    
    function parseTimeInput(timeString) {
        // Parse "HH:MM" format to minutes since midnight
        var parts = timeString.split(":")
        if (parts.length !== 2) return -1
        var hours = parseInt(parts[0])
        var mins = parseInt(parts[1])
        if (isNaN(hours) || isNaN(mins) || hours < 0 || hours >= 24 || mins < 0 || mins >= 60) {
            return -1
        }
        return hours * 60 + mins
    }

    function handleClick() {
        if (root.mode === "manual") {
            // Toggle night mode manually
            if (root.nightModeEnabled) {
                root.disableNightMode()
            } else {
                root.enableNightMode()
            }
        }
    }
    
    function enableNightMode() {
        console.log("Manually enabling night mode")
        root.isChangingState = true
        root.nightModeEnabled = true
        if (enableProcess.running) {
            enableProcess.running = false
        }
        Qt.callLater(() => {
            enableProcess.running = true
        })
    }
    
    function disableNightMode() {
        console.log("Manually disabling night mode")
        root.isChangingState = true
        root.nightModeEnabled = false
        if (disableProcess.running) {
            disableProcess.running = false
        }
        Qt.callLater(() => {
            disableProcess.running = true
        })
    }
    
    function saveLocationSettings() {
        // Save location to pluginData
        if (pluginData) {
            pluginData.latitude = root.latitude
            pluginData.longitude = root.longitude
            console.log("Location settings saved: " + root.latitude + ", " + root.longitude)
            
            // Also set via IPC
            setLocationViaIPC()
            
            // Recalculate sunrise/sunset if in auto mode
            if (root.mode === "auto") {
                calculateSunriseSunset()
                checkAndUpdateNightMode()
            }
        }
    }
    
    function saveTimeSettings() {
        // Save time settings to pluginData
        if (pluginData) {
            pluginData.useCustomTimes = root.useCustomTimes
            pluginData.customStartTime = root.customStartTime
            pluginData.customEndTime = root.customEndTime
            console.log("Time settings saved: useCustomTimes=" + root.useCustomTimes + 
                       ", start=" + root.customStartTime + ", end=" + root.customEndTime)
        }
    }
    
    function setTemperature(temp) {
        root.temperature = temp
        temperatureSetProcess.command = ["dms", "ipc", "call", "night", "temperature", temp.toString()]
        if (temperatureSetProcess.running) {
            temperatureSetProcess.running = false
        }
        Qt.callLater(() => {
            temperatureSetProcess.running = true
        })
    }
    
    function searchCity(cityName) {
        if (cityName.trim() === "") {
            return
        }
        
        geocodeProcess.currentCity = cityName
        // Build curl command with proper URL encoding
        var encodedCity = encodeURIComponent(cityName)
        var url = "https://nominatim.openstreetmap.org/search?q=" + encodedCity + "&format=json&limit=1"
        
        geocodeProcess.command = ["curl", "-s", url]
        
        if (geocodeProcess.running) {
            geocodeProcess.running = false
        }
        Qt.callLater(() => {
            geocodeProcess.running = true
        })
    }
    
    function checkAndUpdateNightMode() {
        // Only run automatic updates in auto mode
        if (root.mode !== "auto") {
            return
        }
        
        // Determine if we should have night mode enabled
        var shouldBeEnabled = false
        var currentHour = Math.floor(root.currentMinutes / 60)
        var sunriseHour = 0
        var sunsetHour = 0
        
        if (root.useCustomTimes) {
            // Use custom times
            // Handle case where start time is after end time (e.g., 9 PM to 7 AM)
            if (root.customStartTime > root.customEndTime) {
                // Night mode: after start time OR before end time
                shouldBeEnabled = root.currentMinutes >= root.customStartTime || root.currentMinutes < root.customEndTime
            } else {
                // Night mode: between start and end time
                shouldBeEnabled = root.currentMinutes >= root.customStartTime && root.currentMinutes < root.customEndTime
            }
        } else {
            // Use sunrise/sunset times
            // Validate that we have valid sunrise/sunset times
            if (root.sunriseMinutes === 0 && root.sunsetMinutes === 0) {
                console.warn("Invalid sunrise/sunset times, skipping night mode check")
                return
            }
            
            sunriseHour = Math.floor(root.sunriseMinutes / 60)
            sunsetHour = Math.floor(root.sunsetMinutes / 60)
            
            // Additional validation: if sunrise is after 12 PM or sunset is before 12 PM, calculation is likely wrong
            // In this case, don't enable night mode during normal daytime hours (8 AM - 8 PM)
            var calculationSeemsWrong = (sunriseHour >= 12 || sunsetHour < 12)
            
            if (calculationSeemsWrong) {
                // If calculation seems wrong and it's clearly daytime (8 AM - 8 PM), disable night mode
                if (currentHour >= 8 && currentHour < 20) {
                    console.warn("Sunrise/sunset calculation appears incorrect. Disabling night mode during clear daytime hours.")
                    shouldBeEnabled = false
                } else {
                    // Outside normal daytime, use the calculation anyway
                    if (root.sunriseMinutes < root.sunsetMinutes) {
                        shouldBeEnabled = root.currentMinutes >= root.sunsetMinutes || root.currentMinutes < root.sunriseMinutes
                    } else {
                        shouldBeEnabled = root.currentMinutes >= root.sunsetMinutes && root.currentMinutes < root.sunriseMinutes
                    }
                }
            } else {
                // Normal case: sunrise before sunset (typical day)
                // Night mode should be enabled: after sunset OR before sunrise
                if (root.sunriseMinutes < root.sunsetMinutes) {
                    shouldBeEnabled = root.currentMinutes >= root.sunsetMinutes || root.currentMinutes < root.sunriseMinutes
                } 
                // Edge case: sunset before sunrise (polar regions - midnight sun or polar night)
                else if (root.sunsetMinutes < root.sunriseMinutes) {
                    // Night mode: between sunset and sunrise
                    shouldBeEnabled = root.currentMinutes >= root.sunsetMinutes && root.currentMinutes < root.sunriseMinutes
                }
                // If they're equal, something is wrong - default to disabled
                else {
                    console.warn("Sunrise and sunset are equal, keeping current state")
                    return
                }
            }
        }
        
        // Debug logging
        if (root.useCustomTimes) {
            console.log("Night mode check: shouldBeEnabled=" + shouldBeEnabled + ", current=" + root.nightModeEnabled + 
                       ", currentHour=" + currentHour + ", customStart=" + root.formatTime(root.customStartTime) + ", customEnd=" + root.formatTime(root.customEndTime))
        } else {
            console.log("Night mode check: shouldBeEnabled=" + shouldBeEnabled + ", current=" + root.nightModeEnabled + 
                       ", currentHour=" + currentHour + ", sunriseHour=" + sunriseHour + ", sunsetHour=" + sunsetHour)
        }
        
        // Only update if state needs to change and we're not already changing it
        if (shouldBeEnabled !== root.nightModeEnabled && !root.isChangingState) {
            root.isChangingState = true
            if (shouldBeEnabled) {
                console.log("Enabling night mode (night time: after sunset or before sunrise)")
                root.nightModeEnabled = true
                if (enableProcess.running) {
                    enableProcess.running = false
                }
                Qt.callLater(() => {
                    enableProcess.running = true
                })
            } else {
                console.log("Disabling night mode (daytime: after sunrise and before sunset)")
                root.nightModeEnabled = false
                if (disableProcess.running) {
                    disableProcess.running = false
                }
                Qt.callLater(() => {
                    disableProcess.running = true
                })
            }
        }
    }

    Component.onCompleted: {
        console.info("NightLight plugin started")
        
        // Initialize from pluginData if available
        if (pluginData) {
            if (pluginData.latitude !== undefined) {
                root.latitude = pluginData.latitude
            }
            if (pluginData.longitude !== undefined) {
                root.longitude = pluginData.longitude
            }
            if (pluginData.useCustomTimes !== undefined) {
                root.useCustomTimes = pluginData.useCustomTimes
            }
            if (pluginData.customStartTime !== undefined) {
                root.customStartTime = pluginData.customStartTime
            }
            if (pluginData.customEndTime !== undefined) {
                root.customEndTime = pluginData.customEndTime
            }
        }
        
        console.info("Location: " + root.latitude + ", " + root.longitude)
        
        // Delay initialization to avoid issues
        Qt.callLater(() => {
            // Set location via IPC if we have valid coordinates
            if (root.latitude !== 0 || root.longitude !== 0) {
                setLocationViaIPC()
            }
            
            // Initial calculations
            updateCurrentTime()
            calculateSunriseSunset()
            
            // Get current status
            statusProcess.running = true
            
            // Get current temperature
            temperatureGetProcess.running = true
            
            // Check and update immediately
            checkAndUpdateNightMode()
            
            // Mark as initialized so handlers can run
            root._isInitialized = true
        })
    }

    // Watch for location changes (but not during initial load)
    property bool _isInitialized: false
    
    onLatitudeChanged: {
        if (_isInitialized && (root.latitude !== 0 || root.longitude !== 0)) {
            setLocationViaIPC()
            calculateSunriseSunset()
            checkAndUpdateNightMode()
        }
    }
    
    onLongitudeChanged: {
        if (_isInitialized && (root.latitude !== 0 || root.longitude !== 0)) {
            setLocationViaIPC()
            if (root.mode === "auto") {
                calculateSunriseSunset()
                checkAndUpdateNightMode()
            }
        }
    }
    
    onModeChanged: {
        console.log("Mode changed to:", root.mode)
        if (root.mode === "auto") {
            // Recalculate and check when switching to auto mode
            updateCurrentTime()
            calculateSunriseSunset()
            checkAndUpdateNightMode()
        }
    }
}

