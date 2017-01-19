/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import GCDWebServers
import Shared
import Storage

struct TestPageHelper {
    static func register(webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "testing", resource: "regional-adblock") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            let path = NSBundle.mainBundle().pathForResource("test-russian-adblock", ofType: "html")
            do {
                let html = try NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding) as String
                return GCDWebServerDataResponse(HTML: html)
            } catch {
                print("Unable to register webserver \(error)")
            }
            return GCDWebServerResponse(statusCode: 200)
        }
    }
}
