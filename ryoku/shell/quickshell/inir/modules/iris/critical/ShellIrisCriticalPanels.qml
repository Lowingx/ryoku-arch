pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import inir.modules.common
import inir.modules.iris.bar
import inir.modules.iris.frame
import inir.modules.iris.background
import inir.modules.closeConfirm
import inir.modules.regionSelector

Item {
    id: root

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    LazyLoader {
        active: Config.ready
        component: IrisReservations {}
    }

    CriticalPanelLoader {
        identifier: "irisBar"
        component: IrisBar {}
    }

    // The bare iRiS background surface paints nothing, so the wallpaper shows
    // through. Ryoku's own desktop is the single desktop-widget host, so the
    // inir widget canvas is retired and this passthrough is always present.
    CriticalPanelLoader {
        identifier: "irisBackground"
        component: IrisBackground {}
    }

    // Always-on IPC hosts: the close-window confirmation and the region-capture
    // router (its `region` IPC target is what the compositor keybinds reach).
    LazyLoader {
        active: Config.ready
        component: CloseConfirm {}
    }

    LazyLoader {
        active: Config.ready
        component: RegionSelectorRouter {}
    }
}
