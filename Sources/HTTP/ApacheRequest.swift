//
//  ApacheRequest.swift
//  SwiftServerHttp
//
//  Created by Helge Hess on 01/06/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import CApache

/// Creates a HTTPRequest from a raw Apache request structure
func ApacheRequest(_ handle: UnsafeMutablePointer<request_rec>) -> HTTPRequest {
  
  // derive method
  
  let method : HTTPMethod
  switch handle.pointee.method_number {
    case M_GET    : method = .get
    case M_POST   : method = .post
    case M_PUT    : method = .put
    case M_DELETE : method = .delete
    
    default:
      if strcmp(handle.pointee.method, "HEAD") == 0 {
        method = .head // Hm?
      }
      else {
        method = HTTPMethod(String(cString: handle.pointee.method))
      }
  }
  
  let target = String(cString: handle.pointee.unparsed_uri)

  // Protocol version number of protocol; 1.1 = 1001
  
  let version = HTTPVersion(major: Int(handle.pointee.proto_num) / 1000,
                            minor: Int(handle.pointee.proto_num) % 1000 )
  
  // transfer headers
  
  var headers = HTTPHeaders()
  
  if let elements = apr_table_elts(handle.pointee.headers_in) {
    let count = Int(elements.pointee.nelts)

    if count > 0 {    
      let ptr = UnsafeRawPointer(elements.pointee.elts)!
      var tptr = ptr.assumingMemoryBound(to: apr_table_entry_t.self)
      
      var originals = [ ( HTTPHeaders.Name, String) ]()
      for _ in 0..<count {
        let key   = String(cString: tptr.pointee.key)
        let value = String(cString: tptr.pointee.val)
        originals.append( ( HTTPHeaders.Name(key), value ) )
        tptr = tptr.advanced(by: 1)
      }
      headers.original = originals
    }
  }
  
  
  // return result
  
  return HTTPRequest(method: method, target: target,
                     httpVersion: version,
                     headers: headers)
}
