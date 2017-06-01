// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/*
import Foundation

/// Class that wraps the HTTPParser and calls the `WebApp` to get the response
public class StreamingParser: HTTPResponseWriter {

    let webapp : WebApp

    /// Is the currently parsed request an upgrade request?
    public private(set) var upgradeRequested = false
    
    /// Class that wraps the CHTTPParser and calls the `WebApp` to get the response
    ///
    /// - Parameter webapp: function that is used to create the response
    public init(webapp: @escaping WebApp, connectionCounter: CurrentConnectionCounting? = nil) {
        self.webapp = webapp
        
    }
    /// Process change of state as we get more and more parser callbacks
    ///
    /// - Parameter currentCallBack: state we are entering, as specified by the CHTTPParser
    /// - Returns: Whether or not the state actually changed
    @discardableResult
    func processCurrentCallback(_ currentCallBack:CallbackRecord) -> Bool {
        if lastCallBack == currentCallBack {
            return false
        }
        switch lastCallBack {
        case .headersCompleted:
            let methodId = self.httpParser.method
            if let methodName = http_method_str(http_method(rawValue: methodId)) {
                self.parsedHTTPMethod = HTTPMethod(rawValue: String(validatingUTF8: methodName) ?? "GET")
            }
            self.parsedHTTPVersion = (Int(self.httpParser.http_major), Int(self.httpParser.http_minor))
            
            self.parserBuffer=nil
            
            if !upgradeRequested {
                self.httpBodyProcessingCallback = self.webapp(self.createRequest(), self)
            }
    }
    
    func messageCompleted() -> Int32 {
        let didChangeState = processCurrentCallback(.messageCompleted)
        if let chunkHandler = self.httpBodyProcessingCallback, didChangeState {
            var stop=false
            switch chunkHandler {
            case .processBody(let handler):
                handler(.end, &stop)
            case .discardBody:
                break
            }
        }
        return 0
    }
    
    func bodyReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.bodyReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            let buff = UnsafeBufferPointer<UInt8>(start: ptr, count: length)
            let chunk = DispatchData(bytes:buff)
            if let chunkHandler = self.httpBodyProcessingCallback {
                var stop=false
                var finished=false
                while !stop && !finished {
                    switch chunkHandler {
                    case .processBody(let handler):
                        handler(.chunk(data: chunk, finishedProcessing: {
                            finished=true
                        }), &stop)
                    case .discardBody:
                        finished=true
                    }
                }
            }
        }
        return 0
    }
    
    
    /// Create a `HTTPRequest` struct from the parsed information 
    public func createRequest() -> HTTPRequest {
        return HTTPRequest(method: parsedHTTPMethod!, target: parsedURL!, httpVersion: parsedHTTPVersion!, headers: parsedHeaders)
    }
    
    public func writeContinue(headers: HTTPHeaders?) /* to send an HTTP `100 Continue` */ {
        var status = "HTTP/1.1 \(HTTPResponseStatus.continue.code) \(HTTPResponseStatus.continue.reasonPhrase)\r\n"
        if let headers = headers {
            for (key, value) in headers.makeIterator() {
                status += "\(key): \(value)\r\n"
            }
        }
        status += "\r\n"
        
        // TODO use requested encoding if specified
        if let data = status.data(using: .utf8) {
            self.parserConnector?.queueSocketWrite(data)
        } else {
            //TODO handle encoding error
        }
    }
    
    public func writeResponse(_ response: HTTPResponse) {
        guard !headersWritten else {
            return
        }
        
        var headers = "HTTP/1.1 \(response.status.code) \(response.status.reasonPhrase)\r\n"
        
        switch(response.transferEncoding) {
        case .chunked:
            headers += "Transfer-Encoding: chunked\r\n"
            isChunked = true
        case .identity(let contentLength):
            headers += "Content-Length: \(contentLength)\r\n"
        }
        
        for (key, value) in response.headers.makeIterator() {
            headers += "\(key): \(value)\r\n"
        }
        
        let availableConnections = maxRequests - (self.connectionCounter?.connectionCount ?? 0)
        
        if  clientRequestedKeepAlive && (availableConnections > 0) {
            headers.append("Connection: Keep-Alive\r\n")
            headers.append("Keep-Alive: timeout=\(Int(StreamingParser.keepAliveTimeout)), max=\(availableConnections)\r\n")
        }
        else {
            headers.append("Connection: Close\r\n")
        }
        headers.append("\r\n")
        
        // TODO use requested encoding if specified
        if let data = headers.data(using: .utf8) {
            self.parserConnector?.queueSocketWrite(data)
            headersWritten = true
        } else {
            //TODO handle encoding error
        }
    }
    
    public func writeTrailer(key: String, value: String) {
        fatalError("Not implemented")
    }
    
    public func writeBody(data: DispatchData, completion: @escaping (Result<POSIXError, ()>) -> Void) {
        writeBody(data: Data(data), completion: completion)
    }
    
    
    public func writeBody(data: DispatchData) /* convenience */ {
        writeBody(data: data) { _ in
        }
    }
    
    public func writeBody(data: Data, completion: @escaping (Result<POSIXError, ()>) -> Void) {
        guard headersWritten else {
            //TODO error or default headers?
            return
        }
        
        guard data.count > 0 else {
            // TODO fix Result
            completion(Result(completion: ()))
            return
        }
        
        var dataToWrite: Data!
        if isChunked {
            let chunkStart = (String(data.count, radix: 16) + "\r\n").data(using: .utf8)!
            dataToWrite = Data(chunkStart)
            dataToWrite.append(data)
            let chunkEnd = "\r\n".data(using: .utf8)!
            dataToWrite.append(chunkEnd)
        } else {
            dataToWrite = data
        }
        
        self.parserConnector?.queueSocketWrite(dataToWrite)
        
        completion(Result(completion: ()))
    }
    
    public func writeBody(data: Data) /* convenience */ {
        writeBody(data: data) { _ in
        }
    }
    
    public func done(completion: @escaping (Result<POSIXError, ()>) -> Void) {
        
        completion(Result(completion: closeAfter()))
    }

}

*/

