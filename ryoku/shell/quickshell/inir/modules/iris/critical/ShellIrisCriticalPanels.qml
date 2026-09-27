pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import inir.modules.common
import inir.modules.iris.bar
import inir.modules.iris.frame

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
}
