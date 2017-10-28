# SwiftServerHttp

Sample prototype implementation of the Swift Server HTTP API Working Group API
[v0.1.0](https://github.com/swift-server/http/releases/tag/0.1.0).

This is a [mod_swift](http://mod-swift.org/) version of
the API.


## Description

This is an Apache implementation of the HTTP API 0.1.0 using mod_swift. It consists
of a library package (top-level Package.swift: HTTP) implementing the API
and of a sample module using the API.

Note: to run anything, you must install mod_swift.

## mod_swift

### Installation on macOS

```shell
brew tap homebrew/apache
brew tap modswift/mod_swift
brew reinstall httpd24 --with-mpm-event --with-http2
brew install mod_swift
```

### Installation on Linux

```
sudo apt-get install \
   curl pkg-config libapr1-dev libaprutil1-dev \
   libxml2 apache2 apache2-dev \
   libnghttp2-dev

curl -L -o mod_swift.tgz \
     https://github.com/modswift/mod_swift/archive/0.8.5.tar.gz
tar zxf mod_swift.tgz && cd mod_swift-0.8.5
sudo make install
```

## Build API & example module

Grab the repo:
```shell
git clone https://github.com/modswift/http.git
cd http
git checkout implementation/mod_swift
```

Build in Xcode: open `SwiftServerHttp.xcodeproj`, then just build&run.

Build using SPM:
```shell
cd Samples/mods_httpapi
swift apache build
swift apache serve
```

### Test

- hello world endpoint:
  - HTTP:           http://localhost:8042/
  - HTTPS / HTTP/2: http://localhost:8442/

- test echo handler via curl

```sh
curl -X PUT --data-binary $'Hello\n  Swift\n' http://localhost:8042/echo
```

### Sources

The implementation is split into two parts:
- a small framework implementing the API (the `SwiftServerHttp` package)
- a demo Apache module containing the demo applications

#### Module hooking up the demo applications

The demo apps are unchanged from the original repo. This is what the module
entry point looks like:

```swift
import SwiftServerHttp

@_cdecl("ApacheMain")
public func ApacheMain(cmd: OpaquePointer) {
  print("Configuring Apache 2x ...")
  
  let app = SwiftServerHttp.apache(cmd, name: "mods_httpapi")
  
  app.use("/echo", EchoWebApp())
  app.use("/",     HelloWorldWebApp())
}
```

### Notes

- the implementation does synchronous I/O
- a lot of `@escaping` could be dropped
- it is pretty hacky ;->
- doesn't implement all enum cases for method/status
- no abort/trailers
- ignores TE

### API Notes

- convenience doesn't belong into protocols, but in extensions
  - maybe DispatchData should be the default, and Data just a convenience 
- the `shouldStop` of HTTPBodyHandler belongs into `HTTPBodyChunk.chunk`
- no idea what `HTTPRequestHandling` is good for and where weak would be relevant
