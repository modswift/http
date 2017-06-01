// mod_swift on the ZeeZide

import SwiftServerHttp

@_cdecl("ApacheMain")
public func ApacheMain(cmd: OpaquePointer) {
  _ = SwiftServerHttp.apache(cmd, name: "mods_httpapi")
}
