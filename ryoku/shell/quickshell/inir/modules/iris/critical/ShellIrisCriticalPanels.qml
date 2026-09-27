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

    // The lightweight bare-desktop surface shows only when the widget canvas is
    // off; the canvas itself lives in ShellIrisPanelsImpl.
    CriticalPanelLoader {
        identifier: "irisBackground"
        extraCondition: !(Config.options?.iris?.modules?.desktopWidgets ?? true)
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
