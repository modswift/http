// mod_swift on the ZeeZide

import CApache
import Apache

var module = CApache.module(name: "mods_httpapi")

func mods_httpapiHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  // example content handler, modify to your liking
  var req = ApacheRequest(raw: p!)
  
  req.contentType = "text/html; charset=ascii"
  req.puts("<html><head><title>Hello mod_swift</title>\(semanticUI)</head>")
  req.puts("<body><div class='ui main container' style='margin-top: 1em;'>")
  req.puts("<h3>Welcome to mods_httpapi</h3>")
  defer { req.puts("</div></body></html>") }
  
  req.puts("<h4>Links of Interest</h4>")
  req.puts("<ul>")
  req.puts("  <li><a href='http://mod-swift.org/'>mod-swift.org</a></li>")
  req.puts("  <li><a href='http://apacheexpress.io/'>ApacheExpress</a></li>")
  req.puts("  <li><a href='https://httpd.apache.org/'>Apache</a></li>")
  
  req.puts("</ul>")
  return OK
}

fileprivate func register_hooks(pool: OpaquePointer?) {
  // hookup the handlers you want
  ap_hook_handler(mods_httpapiHandler, nil, nil, APR_HOOK_MIDDLE)
}

@_cdecl("ApacheMain")
public func ApacheMain(cmd: UnsafeMutablePointer<cmd_parms>) {
  module.register_hooks = register_hooks
  
  let rc = apz_register_swift_module(cmd, &module)
  assert(rc == APR_SUCCESS, "Could not add Swift module!")
}
