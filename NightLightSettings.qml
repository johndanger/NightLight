import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
  pluginId: "dev.johndanger.nightlight"

  StyledText {
    width: parent.width
    text: "NightLight Settings"
    font.pixelSize: Theme.fontSizeLarge
    font.weight: Font.Bold
    color: Theme.surfaceText
  }

  StyledText {
    width: parent.width
    text: "Location Settings"
    font.pixelSize: Theme.fontSizeMedium
    font.weight: Font.Bold
    color: Theme.surfaceText
  }

  StyledText {
    width: parent.width
    text: "Enter your location coordinates for accurate sunrise/sunset calculations. You can find your coordinates using online tools like Google Maps (right-click on your location)."
    font.pixelSize: Theme.fontSizeSmall
    color: Theme.surfaceVariantText
    wrapMode: Text.WordWrap
  }

  NumberSetting {
    settingKey: "latitude"
    label: "Latitude"
    description: "Your latitude coordinate (-90 to 90 degrees)"
    defaultValue: 40.7128
    minimum: -90
    maximum: 90
    decimals: 6
  }

  NumberSetting {
    settingKey: "longitude"
    label: "Longitude"
    description: "Your longitude coordinate (-180 to 180 degrees)"
    defaultValue: -74.0060
    minimum: -180
    maximum: 180
    decimals: 6
  }

  StyledText {
    width: parent.width
    text: "Examples: New York (40.7128, -74.0060), London (51.5074, -0.1278), Tokyo (35.6762, 139.6503)"
    font.pixelSize: Theme.fontSizeSmall
    color: Theme.surfaceVariantText
    wrapMode: Text.WordWrap
    leftPadding: Theme.spacingM
  }

  Rectangle {
    width: parent.width
    height: 1
    color: Theme.outlineVariant
  }

  StyledText {
    width: parent.width
    text: "Alternative: Set location via IPC command"
    font.pixelSize: Theme.fontSizeSmall
    color: Theme.surfaceVariantText
    wrapMode: Text.WordWrap
  }

  StyledText {
    width: parent.width
    text: "dms ipc call night location <lat> <lon>"
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

  StyledText {
    width: parent.width
    text: "The plugin automatically enables night mode at sunset and disables it at sunrise based on your location."
    font.pixelSize: Theme.fontSizeSmall
    color: Theme.surfaceVariantText
    wrapMode: Text.WordWrap
  }

}

