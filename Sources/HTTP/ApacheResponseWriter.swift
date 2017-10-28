//
//  ApacheResponseWriter.swift
//  SwiftServerHttp
//
//  Created by Helge Hess on 01/06/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import CAPR
import CApache
import Dispatch
import Foundation

class ApacheResponseWriter : HTTPResponseWriter {
  
  enum Error : Swift.Error {
    case writeError
    case trailerUnsupported
  }
  
  var handle : OpaquePointer
  
  init(_ handle: UnsafeMutablePointer<request_rec>) {
    // yes, this is awkward, but we cannot store request_rec or ZzApache in an
    // instance variable, crashes swiftc
    self.handle = OpaquePointer(handle)
  }
  var typedHandle : UnsafeMutablePointer<request_rec> {
    return UnsafeMutablePointer<request_rec>(handle)
  }
  
  
  // MARK: - Proposal Implementation
  
  func abort() {
    //fatalError("doesNotRecognize(#selector(\(#function)))")
    // TBD?
    print("TODO: called abort")
  }
  
  func writeTrailer(_ trailers: HTTPHeaders,
                    completion: @escaping (Result) -> Void)
  {
    completion(.error(Error.trailerUnsupported))
  }
  
  func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders,
                   completion: @escaping (Result) -> Void)
  {
    switch status {
      case .ok:       typedHandle.pointee.status = HTTP_OK
      case .created:  typedHandle.pointee.status = HTTP_CREATED
      case .accepted: typedHandle.pointee.status = HTTP_ACCEPTED
      case .gone:     typedHandle.pointee.status = HTTP_GONE
      case .internalServerError:
                      typedHandle.pointee.status = HTTP_INTERNAL_SERVER_ERROR
      case .httpVersionNotSupported:
                      typedHandle.pointee.status = HTTP_VERSION_NOT_SUPPORTED
      
      default:
        // too lazy to do all of them
        typedHandle.pointee.status = HTTP_INTERNAL_SERVER_ERROR
    }

    for ( name, value ) in headers.makeIterator() {
      switch name.lowercased {
        case "content-type":
          ap_set_content_type(typedHandle, apr_pstrdup(typedHandle.pointee.pool, "\(value)"))
        case "content-encoding":
          typedHandle.pointee.content_encoding =
            UnsafePointer(apr_pstrdup(typedHandle.pointee.pool, "\(value)"))
        case "content-language":
          fatalError("no support for content-language yet ...")
        default:
          apr_table_set(typedHandle.pointee.headers_out, name.original, value)
      }
    }
  }

  func writeBody(_ data: UnsafeHTTPResponseBody,
                 completion: @escaping (Result) -> Void)
  {
    data.withUnsafeBytes { data in
      guard !data.isEmpty else { completion(.ok); return }
      
      let th      = typedHandle
      let brigade = apr_brigade_create(th.pointee.pool,
                                       th.pointee.connection.pointee.bucket_alloc)

      let rc = apz_fwrite(th.pointee.output_filters, brigade,
                          data.baseAddress, apr_size_t(data.count))
      guard rc == OK else {
        return completion(.error(Error.writeError))
      }
      
      let rv = ap_pass_brigade(th.pointee.output_filters, brigade)
      if rv != APR_SUCCESS {
        return completion(.error(Error.writeError))
      }
      else {
        completion(.ok)
      }
    }
  }

  func writeBody(data: DispatchData,
                 completion: @escaping (Result) -> Void)
  {
    guard !data.isEmpty else { completion(.ok); return }
    
    let th      = typedHandle
    let brigade = apr_brigade_create(th.pointee.pool,
                                     th.pointee.connection.pointee.bucket_alloc)
    
    // move stuff to brigade
    var didFail = false
    data.enumerateBytes { bp, _, stop in
      // This flushes to the filter if the internal write buffer becomes
      // too large.
      let rc = apz_fwrite(th.pointee.output_filters, brigade,
                          bp.baseAddress, apr_size_t(bp.count))
      if rc != OK {
        didFail = true
        stop    = true
      }
    }
    
    guard !didFail else {
      return completion(.error(Error.writeError))
    }
    
    let rv = ap_pass_brigade(th.pointee.output_filters, brigade)
    if rv != APR_SUCCESS {
      return completion(.error(Error.writeError))
    }
    else {
      completion(.ok)
    }
  }
  
  func writeBody(data: Data, completion: @escaping (Result) -> Void) {
    guard !data.isEmpty else { completion(.ok); return }
    
    data.withUnsafeBytes { ( ptr : UnsafePointer<UInt8> ) in
      let bp    = UnsafeRawBufferPointer(start: ptr, count: data.count)
      let ddata = DispatchData(bytesNoCopy: bp,
                               deallocator: .custom(DispatchQueue.main, {}))
      writeBody(data: ddata, completion: completion)
    }
  }
  
  func done(completion: @escaping (Result) -> Void) {
    let th      = typedHandle
    let brigade = apr_brigade_create(th.pointee.pool,
                                     th.pointee.connection.pointee.bucket_alloc)
    
    let eof = apr_bucket_eos_create(brigade?.pointee.bucket_alloc)
    apz_brigade_insert_tail(brigade, eof)
    let rv = ap_pass_brigade(th.pointee.output_filters, brigade)
    
    if rv != APR_SUCCESS {
      return completion(.error(Error.writeError))
    }
    else {
      completion(.ok)
    }
  }
  
  
  // MARK: - Convenience which should not be part of the protocol itself, but
  //         in an extension
  
  func done() {
    done { _ in }
  }
  
  func writeBody(data: DispatchData) {
    writeBody(data: data) { result in }
  }
  
  func writeBody(data: Data) {
    writeBody(data: data) { _ in }
  }
}
