/*
 * Copyright 2013-2014 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Window 2.1
import Ubuntu.Components 1.1
import Ubuntu.Components.Extras.Browser 0.2
import webcontainer.private 0.1

import com.canonical.Oxide 1.0 as Oxide

Window {
    id: root
    objectName: "webappContainer"

    property bool developerExtrasEnabled: false
    property bool restoreSession: true

    property bool backForwardButtonsVisible: true
    property bool chromeVisible: true

    property string localCookieStoreDbPath: ""

    property string url: ""
    property string webappName: ""
    property string webappModelSearchPath: ""
    property var webappUrlPatterns
    property bool oxide: false
    property string accountProvider: ""
    property string popupRedirectionUrlPrefix: ""
    property var __webappCookieStore: null

    contentOrientation: Screen.orientation

    width: 800
    height: 600

    title: getWindowTitle()

    function getWindowTitle() {
        var webappViewTitle = webappViewLoader.item ? webappViewLoader.item.title : ""
        if (typeof(webappName) === 'string' && webappName.length !== 0) {
            return webappName
        } else if (webappViewTitle) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Ubuntu Web Browser").arg(webappViewTitle)
        } else {
            return i18n.tr("Ubuntu Web Browser")
        }
    }

    Loader {
        id: webappViewLoader
    }

    Component {
        id: webappViewComponent

        WebApp {
            id: browser

            // Initially set as non visible to leave a chance
            // for the OA dialog to appear
            visible: false

            url: root.url

            chromeVisible: root.chromeVisible
            backForwardButtonsVisible: root.backForwardButtonsVisible
            developerExtrasEnabled: root.developerExtrasEnabled
            restoreSession: root.restoreSession
            oxide: root.oxide
            webappModelSearchPath: root.webappModelSearchPath
            webappName: root.webappName
            webappUrlPatterns: root.webappUrlPatterns

            popupRedirectionUrlPrefix: root.popupRedirectionUrlPrefix

            anchors.fill: parent

            webbrowserWindow: webbrowserWindowProxy

            onWebappNameChanged: {
                if (root.webappName !== browser.webappName) {
                    root.webappName = browser.webappName;
                    root.title = getWindowTitle();
                }
            }

            onCurrentWebviewChanged: {
                if (currentWebview)
                    root.updateCurrentView()
            }

            Component.onCompleted: i18n.domain = "webbrowser-app"
        }
    }

    // XXX: work around https://bugs.launchpad.net/unity8/+bug/1328839
    // by toggling fullscreen on the window only on desktop.
    visibility: webappViewLoader.item &&
                webappViewLoader.item.currentWebview &&
                webappViewLoader.item.currentWebview.fullscreen &&
                (formFactor === "desktop") ? Window.FullScreen : Window.AutomaticVisibility

    Loader {
        id: accountsPageComponentLoader
        anchors.fill: parent
        onStatusChanged: {
            if (status == Loader.Error) {
                // Happens on the desktop, if Ubuntu.OnlineAccounts.Client
                // can't be imported
                loadWebAppView()
            } else if (status == Loader.Ready) {
                item.visible = true
            }
        }
    }

    Connections {
        target: accountsPageComponentLoader.item
        onDone: loadWebAppView()
    }

    Component {
        id: oxideCookieStoreComponent
        ChromeCookieStore {
            dbPath: dataLocation + "/cookies.sqlite"
            homepage: root.url
            oxideStoreBackend: context.cookieManager
        }
    }

    Oxide.WebContext {
        id: context
        dataPath: dataLocation
    }

    Component {
        id: localCookieStoreComponent
        LocalCookieStore {
            dbPath: localCookieStoreDbPath
        }
    }

    Component.onCompleted: {
        updateCurrentView()
    }

    Component {
        id: onlineAccountStoreComponent
        OnlineAccountsCookieStore { }
    }

    function updateCurrentView() {
        // check if we are to display the login view
        // or directly switch to the webapp view
        if (accountProvider.length !== 0 && !__webappCookieStore && oxide) {
            loadLoginView();
        } else {
            loadWebAppView();
        }
    }

    function loadLoginView() {
        if (!__webappCookieStore) {
            __webappCookieStore = oxideCookieStoreComponent.createObject(this)
        }
        console.log('localCookieStoreDbPath ' + localCookieStoreDbPath)
        accountsPageComponentLoader.setSource("AccountsPage.qml", {
            "accountProvider": accountProvider,
            "applicationName": Qt.application.name,
            "webappCookieStore": __webappCookieStore,
            "onlineAccountStoreComponent": localCookieStoreDbPath.length !== 0 ?
                                               localCookieStoreComponent : onlineAccountStoreComponent
        })
    }

    function loadWebAppView() {
        if (accountsPageComponentLoader.item)
            accountsPageComponentLoader.item.visible = false
        webappViewLoader.sourceComponent = webappViewComponent
    }

    // Handle runtime requests to open urls as defined
    // by the freedesktop application dbus interface's open
    // method for DBUS application activation:
    // http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#dbus
    // The dispatch on the org.freedesktop.Application if is done per appId at the
    // url-dispatcher/upstart level.
    Connections {
        target: UriHandler
        onOpened: {
            // only consider the first one (if multiple)
            if (uris.length !== 0
                    && webappPageComponentLoader.item
                    && webappPageComponentLoader.item.currentWebview) {
                webappPageComponentLoader.item.currentWebview.url = uris[0];
            }
        }
    }
}

