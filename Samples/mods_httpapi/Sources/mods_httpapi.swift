// mod_swift on the ZeeZide

import SwiftServerHttp

@_cdecl("ApacheMain")
public func ApacheMain(cmd: OpaquePointer) {
  print("Configuring Apache 2x ...")
  
  let app = SwiftServerHttp.apache(cmd, name: "mods_httpapi")
  
  app.use("/echo", EchoWebApp())
  app.use("/",     HelloWorldWebApp())
}
