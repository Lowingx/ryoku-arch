pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../desktop"
import Ryoku.Ui.Singletons

// The Stage Editor's Depth catalogue: the depth editor folded into the mode,
// one section per tab (the cut, its layers, their look, their motion, the
// widgets in front). Adding a layer from a picture stays in the Hub, which
// owns the file picker; the row below hands off to it.
StageSheet {
    id: page

    content: Component {
        StageDepthOptions {}
    }

    MenuRow {
        label: I18n.tr("Add a layer from a picture")
        value: I18n.tr("Hub")
        closeOnTrigger: false
        onTriggered: Quickshell.execDetached(["ryoku-shell", "hub", "open", "desktop-scene"])
    }
}
