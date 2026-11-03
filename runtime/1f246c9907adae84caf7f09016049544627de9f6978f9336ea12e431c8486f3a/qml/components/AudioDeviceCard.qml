import QtQuick 6.11
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "../core/Model.js" as Model

// Expandable device card. Collapsed row keeps the one-click default-switch
// fast path (click name/glyph); the chevron drills into per-device controls —
// live meter, volume slider, mute — without leaving the list. Same drill-down
// idiom as the fan plugin: summary outside, controls inside.
CursorSurface {
  id: root

  required property var node
  required property int rowIndex
  required property var bar
  required property string preferredName
  required property string label
  required property string section         // "output" | "input"
  required property bool outputGroup

  property var service: null
  property bool expanded: false
  property real volumeMaximum: 1.0
  // Meter feed — supplied only for the direction's default device.
  property real meterLevel: 0
  property real meterPeakHold: 0
  property bool meterClipping: false
  property bool metered: false

  signal claimed(string section, int index)
  signal activated(var node)
  signal expandToggled()

  readonly property bool isActive: Model.nodeName(root.node) !== ""
    && Model.nodeName(root.node) === root.preferredName
  readonly property color urgent: root.bar ? root.bar.urgent : Commons.Color.urgent

  function nodeVolume() {
    try { var v = Number(root.node.audio.volume); return isFinite(v) ? v : 0 }
    catch (_error) { return 0 }
  }
  function nodeMuted() {
    try { return root.node.audio.muted === true } catch (_error) { return false }
  }
  function nodeMutable() {
    try { return !!root.node && root.node.ready !== false && !!root.node.audio }
    catch (_error) { return false }
  }

  current: root.isActive
  implicitHeight: cardColumn.implicitHeight + Style.spacing.xl

  Column {
    id: cardColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(6)

    Row {
      width: parent.width
      height: collapsedInner.implicitHeight
      spacing: Style.space(8)

      // Left zone: glyph + label — the one-click default switch.
      Item {
        width: parent.width - collapsedRight.width - parent.spacing
        height: collapsedInner.implicitHeight

        Row {
          id: collapsedInner
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: root.section === "input"
              ? Model.sourceGlyph(root.node) : Model.sinkGlyph(root.node)
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            width: Style.space(22)
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            textFormat: Text.PlainText
            text: root.label
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: root.isActive
            elide: Text.ElideRight
            width: parent.width - Style.space(22) - Style.space(8)
              - (groupTag.visible ? groupTag.implicitWidth + Style.space(8) : 0)
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            textFormat: Text.PlainText
            id: groupTag
            visible: root.outputGroup
            text: "GROUP"
            color: Commons.Color.accent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onContainsMouseChanged: if (containsMouse)
            root.claimed(root.section, root.rowIndex)
          onClicked: root.activated(root.node)
        }
      }

      // Right zone: mini meter (default only), volume %, drill chevron.
      Row {
        id: collapsedRight
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(6)

        Rectangle {
          visible: root.metered
          width: Style.space(28)
          height: Style.space(3)
          anchors.verticalCenter: parent.verticalCenter
          color: Util.alpha(root.bar.foreground, 0.18)
          Rectangle {
            height: parent.height
            width: parent.width * root.meterLevel
            color: root.meterClipping ? root.urgent : root.bar.foreground
            Behavior on width { NumberAnimation { duration: 70 } }
          }
        }

        Text {
          textFormat: Text.PlainText
          text: Math.round(root.nodeVolume() * 100) + "%"
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: root.isActive
          opacity: root.nodeMuted() ? 0.5 : 1.0
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          textFormat: Text.PlainText
          visible: root.nodeMuted()
          text: "󰝟"
          color: root.urgent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          width: Style.space(18)
          height: Style.space(18)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: root.expanded ? "▾" : "▸"
            color: Qt.darker(root.bar.foreground, 1.5)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: if (containsMouse)
              root.claimed(root.section, root.rowIndex)
            onClicked: root.expandToggled()
          }
        }
      }
    }

    // ---- Drill-down: meter + per-device controls ----
    Column {
      visible: root.expanded
      width: parent.width
      spacing: Style.space(6)

      AudioMeterBar {
        visible: root.metered
        width: parent.width - Style.space(12)
        anchors.horizontalCenter: parent.horizontalCenter
        level: root.meterLevel
        peakHold: root.meterPeakHold
        clipping: root.meterClipping
        foreground: root.bar.foreground
        urgent: root.urgent
        active: !root.nodeMuted()
      }

      AudioSlider {
        width: parent.width - Style.space(12)
        anchors.horizontalCenter: parent.horizontalCenter
        bar: root.bar
        minimum: 0
        maximum: root.volumeMaximum
        step: 0.05
        value: root.nodeVolume()
        opacity: root.nodeMuted() ? 0.5 : 1.0
        enabled: root.nodeMutable()

        onMoved: function(v) {
          if (root.service) root.service.changeNode(root.node, { volume: v })
        }
        onRightClicked: {
          if (root.service && root.nodeMutable())
            root.service.changeNode(root.node, { muted: !root.nodeMuted() })
        }
      }

      Row {
        width: parent.width - Style.space(12)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(8)

        ToggleSwitch {
          checked: !root.nodeMuted()
          foreground: root.bar.foreground
          anchors.verticalCenter: parent.verticalCenter
          onToggled: {
            if (root.service && root.nodeMutable())
              root.service.changeNode(root.node, { muted: !root.nodeMuted() })
          }
        }

        Text {
          textFormat: Text.PlainText
          text: root.nodeMuted()
            ? "Muted"
            : (root.isActive
              ? (root.section === "input" ? "Default input" : "Default output")
              : "Volume and mute")
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
