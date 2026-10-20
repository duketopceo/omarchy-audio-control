import QtQuick 6.11
import qs.Ui
import qs.Commons

// Thin live level meter: instantaneous fill, a held-peak tick, and a clip
// state. Same visual as the fan plugin's sparkline rows — always-on signal,
// zero chrome. Drive it from a PwNodePeakMonitor via Model.audioMeterLevel;
// when inactive (muted / no device) it dims instead of pretending.
Rectangle {
  id: root

  property real level: 0
  property real peakHold: 0
  property bool clipping: false
  property color foreground
  property color urgent
  property bool active: true

  implicitHeight: Math.max(Style.space(5), Style.spacing.xs)
  color: Util.alpha(root.foreground, 0.18)
  opacity: root.active ? 1.0 : 0.35

  Rectangle {
    height: parent.height
    width: parent.width * root.level
    color: root.clipping ? root.urgent : root.foreground
    Behavior on width { NumberAnimation { duration: 70 } }
  }

  Rectangle {
    visible: root.peakHold > 0.02
    width: Math.max(1, Style.space(2))
    height: parent.height + Style.space(4)
    x: Math.max(0, Math.min(parent.width - width,
      parent.width * root.peakHold - width / 2))
    anchors.verticalCenter: parent.verticalCenter
    color: root.peakHold >= 0.98 ? root.urgent : root.foreground
  }
}
