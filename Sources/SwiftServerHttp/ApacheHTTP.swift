//
//  ApacheHTTP.swift
//  SwiftServerHttp
//
//  Created by Helge Hess on 01/06/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import CApache
import Dispatch

fileprivate var modules = [ ApacheModule ]()

public class ApacheModule {
  
  public var module : CApache.module
  
  enum SomeError : Error {
    case noIdeaWhat
  }
  
  var handlers = [ ( String, WebApp ) ]()
  
  init(loadCommand cmd: UnsafeMutablePointer<cmd_parms>, name: String) {
    module = CApache.module(name: name, register_hooks: register_hooks)
  }
  
  public func use(_ prefix: String, _ app: @escaping WebApp) {
    handlers.append( (prefix, app) )
  }
  public func use(_ prefix: String, _ app: WebAppContaining) {
    use(prefix) { req, res in
      return app.serve(req: req, res: res)
    }
  }
    
  func handle(request raw: UnsafeMutablePointer<request_rec>) -> Int32 {
    let uri = String(cString: raw.pointee.uri)
    
    let handler : WebApp? = {
      for ( prefix, handler ) in handlers {
        guard uri.hasPrefix(prefix) else { continue }
        return handler
      }
      return nil
    }()

    guard let app = handler else { return DECLINED }
    
    let request        = ApacheRequest(raw)
    let responseWriter = ApacheResponseWriter(raw)
    
    let bodyHandler = app(request, responseWriter)
    
    switch bodyHandler {
      case .discardBody:
        let rc = ap_discard_request_body(raw)
        return OK // we are done
      
      case .processBody(let handler):
        let rc = ap_setup_client_block(raw, REQUEST_CHUNKED_DECHUNK)
        var shouldStop = false
        guard rc == OK else {
          handler(HTTPBodyChunk.end, &shouldStop)
          return OK
        }
        
        guard ap_should_client_block(raw) != 0 else {
          // There is no message to read, this is *fine*. Not an error.
          handler(HTTPBodyChunk.end, &shouldStop)
          return OK // we are done
        }
        
        let bufsize = 8092
        let buffer  = UnsafeMutablePointer<Int8>.allocate(capacity: bufsize)
        defer { buffer.deallocate(capacity: bufsize) }
        
        while !shouldStop {
          let rc = ap_get_client_block(raw, buffer, bufsize)
          guard rc != 0 else { break } // EOF
          
          guard rc >  0 else {
            handler(HTTPBodyChunk.failed(error: SomeError.noIdeaWhat),
                    &shouldStop)
            return HTTP_BAD_REQUEST // no idea :-)
          }
          
          // hm
          buffer.withMemoryRebound(to: UInt8.self, capacity: rc) { buffer in
            let bp    = UnsafeBufferPointer(start: buffer, count: rc)
            let ddata = DispatchData(bytesNoCopy: bp,
                                     deallocator: .custom(DispatchQueue.main, {}))
            handler(HTTPBodyChunk.chunk(data: ddata, finishedProcessing: {}),
                    &shouldStop)
          }
        }
        
        handler(HTTPBodyChunk.end, &shouldStop)
        return OK // we are done
    }
  }
  
}

/// Entry point function, call this in your module
public func apache(_ cmd: OpaquePointer, name: String? = nil) -> ApacheModule {
  let typedCmd = UnsafeMutablePointer<cmd_parms>(cmd)
  let app = ApacheModule(loadCommand: typedCmd, name: name ?? "mod_swift")
  modules.append(app)
  
  let rc = apz_register_swift_module(typedCmd, &app.module)
  assert(rc == APR_SUCCESS, "Could not add Swift module!")
  return app
}


// MARK: - Apache Module Structure

fileprivate func register_hooks(pool: OpaquePointer?) {
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
