//
//  ApacheHTTP.swift
//  SwiftServerHttp
//
//  Created by Helge Hess on 01/06/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import CApache

fileprivate var modules = [ ApacheModule ]()

public class ApacheModule {
  
  public var module : CApache.module
  
  public init(loadCommand cmd: UnsafeMutablePointer<cmd_parms>, name: String) {
    module = CApache.module(name: name, register_hooks: register_hooks)
  }
  
  func handle(request: UnsafeMutablePointer<request_rec>) -> Int32 {
    return DECLINED
  }
}

public func apache(_ cmd: OpaquePointer, name: String? = nil) -> ApacheModule {
  let typedCmd = UnsafeMutablePointer<cmd_parms>(cmd)
  let app = ApacheModule(loadCommand: typedCmd, name: name ?? "mod_swift")
  modules.append(app)
  let rc = apz_register_swift_module(typedCmd, &app.module)
  assert(rc == APR_SUCCESS, "Could not add Swift module!")
  return app
}

fileprivate var didRegisterHooks = false
fileprivate func register_hooks(pool: OpaquePointer?) {
  guard !didRegisterHooks else { return }
  didRegisterHooks = true
  
  ap_hook_handler(handler, nil, nil, APR_HOOK_FIRST)
}

// The main entry point to generate ApacheExpress.http server callbacks
fileprivate func handler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  guard p != nil else { return DECLINED }
  for module in modules {
    let rc = module.handle(request: p!)
    if rc != DECLINED { return rc }
  }
  return DECLINED
}

// MARK: - Module

public extension CApache.module {
  
  public init(name: String,
              register_hooks: @escaping @convention(c) (OpaquePointer?) -> Void)
  {
    self.init()
    
    // Replica of STANDARD20_MODULE_STUFF (could also live as a C support fn)
    version       = MODULE_MAGIC_NUMBER_MAJOR
    minor_version = MODULE_MAGIC_NUMBER_MINOR
    module_index  = -1
    self.name     = UnsafePointer(strdup(name)) // leak
    dynamic_load_handle = nil
    next          = nil
    magic         = MODULE_MAGIC_COOKIE
    rewrite_args  = nil
    
    self.register_hooks = register_hooks
  }
  
}
