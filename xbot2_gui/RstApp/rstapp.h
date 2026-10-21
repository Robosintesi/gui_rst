#pragma once

#include <QList>
#include <QString>

namespace rst {

// Starts a Robosintesi app: Rst style and fonts, appData for QML, then the main.qml of the QML
// module qmlModule (an RstWindow). version is {major, minor, patch}. Returns the exit code.
int runApp(int &argc, char *argv[], const QString &appName, const QString &qmlModule,
           const QList<int> &version);

}
