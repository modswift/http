# SwiftServerHttp

Sample prototype implementation of @weissi's HTTP Sketch v2 from https://lists.swift.org/pipermail/swift-server-dev/Week-of-Mon-20170403/000422.html for discussion.

This is a [mod_swift](http://mod-swift.org/) version of
the API.


## Description

This is an Apache implementation of the HTTP Sketch v2 using mod_swift. It consists
of a library package (top-level Package.swift: SwiftServerHttp) implementing the API
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

## Build example module

Either in Xcode (open `SwiftServerHttp.xcodeproj`, then just build&run). Or in the shell:

```shell
cd Samples/mods_httpapi
swift apache build

swift apache serve
```

Test echo handler

```sh
curl -X PUT --data-binary $'Hello\n  Swift\n' http://localhost:8042/echo
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
- no idea what `WebAppContaining` is good for and where weak would be relevant
