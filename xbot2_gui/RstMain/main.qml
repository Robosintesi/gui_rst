import QtQuick

import Common
import Font
import Main
import RstApp

// general purpose Robosintesi app for robot monitoring; a project app has a main.qml like this one
RstWindow {
    id: win

    pages: [
        PageItem {
            name: "Network"
            page: "/qt/qml/RstNetwork/Network.qml"
            iconText: MaterialSymbolNames.netSettings
            active: true
            lazyLoad: false
        },
        PageItem {
            name: "Process"
            page: "/qt/qml/RstProcess/Process.qml"
            iconText: MaterialSymbolNames.terminal
            active: win.client.isConnected || win.dbg
        },
        PageItem {
            name: "Monitoring"
            page: "/qt/qml/RstMonitoring/Monitoring.qml"
            iconText: MaterialSymbolNames.gauge
            active: win.client.robotConnected || win.dbg
            lazyLoad: false
        },
        PageItem {
            name: "Plot"
            page: "/qt/qml/LivePlot/Plot.qml"
            iconText: MaterialSymbolNames.tableChart
            active: win.client.isConnected || win.dbg
        }
    ]
}
