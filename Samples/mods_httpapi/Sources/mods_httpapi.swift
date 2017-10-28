// mod_swift on the ZeeZide

import HTTP

@_cdecl("ApacheMain")
public func ApacheMain(cmd: OpaquePointer) {
  print("Configuring Apache 2x ...")
  
  let app = HTTP.apache(cmd, name: "mods_httpapi")
  
  app.use("/echo", EchoWebApp())
  app.use("/",     HelloWorldWebApp())
}
