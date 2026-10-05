#include <QGuiApplication>
#include <QQmlApplicationEngine>


// rashin-app: the desktop's AI companion window. The process owns the C++
// types (the daemon bridge, the chat wire, markdown safety, the app's own
// preferences) and loads the embedded QML surfaces. One instance is guarded
// by a flock the launcher keybind holds around this process, so a second
// press raises the open window instead of spawning a twin.
//
// The app talks to the machine only through the rashin daemon: the chat
// stream rides the `ryoku-rashin chat --follow` wire, every system fact rides
// the daemon's HTTP API. Nothing here is authority; the daemon is.

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("Ryoku"));
    app.setOrganizationDomain(QStringLiteral("ryoku.dev"));
    app.setApplicationName(QStringLiteral("rashin-app"));
    app.setApplicationDisplayName(QStringLiteral("Rashin"));
    app.setDesktopFileName(QStringLiteral("rashin-app"));

    QQmlApplicationEngine engine;
    // The embedded module loads by URI from the binary's own resources.
    engine.loadFromModule("RashinApp", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;
    return app.exec();
}
