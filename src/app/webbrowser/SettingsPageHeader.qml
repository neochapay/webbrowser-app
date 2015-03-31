 /*
 * Copyright 2015 Canonical Ltd.
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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

/*
 * Component to use as page header in settings page and subpages
 *
 * It has a trigger() signal fired when back button is pressed and a text
 * property to set the page title
 *
 * Place it as last component of the page to have on top of flickable when it
 * scrolls
 */

Item {
    id: root
    signal trigger()
    property var text

    height: title.height + divider.height

    anchors {
        left: parent.left
        right: parent.right
    }

    ListItem.Empty {
        id: title
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Rectangle {
            anchors.fill: parent
            color: "#f6f6f6"
        }

        showDivider: false
        highlightWhenPressed: false

        AbstractButton {
            id: backButton
            width: height

            onTriggered: root.trigger()
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                color: "#E6E6E6"
                visible: parent.pressed
            }

            Icon {
                name: "back"
                anchors {
                    fill: parent
                    topMargin: units.gu(2)
                    bottomMargin: units.gu(2)
                }
            }
        }

        Label {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: backButton.right
                topMargin: units.gu(2)
                bottomMargin: units.gu(2)
            }
            text: root.text
        }
    }

    ListItem.Divider {
        id: divider
        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
        }
        Rectangle {
            anchors.fill: parent
            color: "#E6E6E6"
        }
    }
}
