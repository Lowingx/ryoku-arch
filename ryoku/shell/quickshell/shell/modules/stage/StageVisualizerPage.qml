pragma ComponentBehavior: Bound
import QtQuick
import "../desktop"
import "../desktop/options" as Opts
import Ryoku.Ui.Singletons
import "../visualizer/Singletons" as VizCfg
import "Singletons" as StageCfg
import stage.modules.common as StageIsland

// The Stage Editor's Visualizer catalogue: the editor the spectrum used to
// have on its own, folded into the mode. On and off at the top, then the
// look's whole options file a section per tab (look, place, colour, playback,
// shape, field). Opening it selects the look on the card, so its frame and
// grip come up where the knobs below move it.
StageSheet {
    id: page

    content: Component {
        Opts.VisualizerOptions {
            widget: "visualizer"
        }
    }

    Component.onCompleted: if (VizCfg.Config.enabled)
        StageCfg.StageSession.select("visualizer")

    // On and off go through the catalogue's own add and remove, so either
    // is one step on the walk-back like a widget dropped or taken away.
    MenuRow {
        label: I18n.tr("Show the visualizer")
        value: VizCfg.Config.enabled ? I18n.tr("On") : I18n.tr("Off")
        on: VizCfg.Config.enabled
        closeOnTrigger: false
        onTriggered: {
            if (VizCfg.Config.enabled) {
                StageIsland.Config.removeWidgetInstance("visualizer");
                return;
            }
            StageIsland.Config.addWidgetToDesktop("visualizer");
            StageCfg.StageSession.select("visualizer");
        }
    }
}
