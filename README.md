Dart Garage Control
===================

Garage Control web client for [py_garage_server](https://github.com/drweaver/py_garage_server) 
written using [Dart](https://www.dartlang.org/)

Pre-compiled files: [garagecontrol-client.zip](https://github.com/drweaver/dart_garage_control/releases/latest)

##Features
* Auto-refresh on opening/closing/error
* Location subscription and enable/disable open button based on auth response
* Full page refresh after repeatd error in case session expiration

Support for mobile view only, sample screenshot taken from a mobile browser:

![Alt screenshot](https://raw.github.com/drweaver/dart_garage_control/master/screenshot.png)

##Building

In DartEditor: Highlight dart_garage_control.dart then Tools -> Generate JavaScript

or:
```bash
cd web
$DARTSDK/bin/dart2js --out=dart_garage_control.dart.js dart_garage_control.dart
```

##Packaging

Command below will create web/garagecontrol-client.zip which can be unzipped into the www folder of [py_garage_server](https://github.com/drweaver/py_garage_server)

```bash
cd web
./dist.sh
```


