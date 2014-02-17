import 'dart:html';
import 'dart:async';
import 'dart:convert' show JSON;

const REFRESH = const Duration(seconds: 3);

final uriRoot = 'garagedoor';

final stateUri = '${uriRoot}/state';
final stopUri = '${uriRoot}/stop';
final openUri = '${uriRoot}/open';
final closeUri = '${uriRoot}/close';

var errorCount = 0;
var refreshCount = 0;
final ERROR_MAX =  5;
final REFRESH_MAX = 20;

Geoposition pos = null;

void main() {
  post(stateUri);
  querySelector("#refresh").onClick.listen((e)=>post(stateUri));
  querySelector("#stop").onClick.listen( (e)=>post(stopUri));
  querySelector('#close').onClick.listen( (e)=>post(closeUri));
  querySelector('#open').onClick.listen( (e)=>post('$openUri?${posUriParams()}') );
  window.navigator.geolocation.watchPosition().listen((Geoposition position) {
    pos = position;
    print('Position = ${pos.coords.latitude},${pos.coords.longitude}');
    (querySelector("#open") as ButtonElement).disabled = false;
  }, onError: (e)=>print('PositionError: ${e.message}'));
}

String posUriParams() => 'lat=${pos.coords.latitude}&lng=${pos.coords.longitude}';

void post(String uri) {
  print('making request to: $uri');
  querySelector('#spinner').classes.remove('hidden');
  var httpRequest = new HttpRequest();
  httpRequest..open('POST', uri)
             ..onLoadEnd.listen((e) => doorStateResponse(httpRequest))
             ..send();
}

void doorStateResponse(HttpRequest request) {
  querySelector('#spinner').classes.add('hidden');
  if (request.status != 200) {
    print('Uh oh, there was an error of ${request.status} errorCount = ${errorCount}');
    querySelector('#status').classes.add('red');
    if(errorCount++ < ERROR_MAX) {
      new Timer(REFRESH, ()=>post(stateUri));
    } else {
      window.location.reload();
    }
  } else {
    errorCount = 0;
    querySelector('#status').classes.remove('red');
    processDoorState(request.responseText);
    print('Data has been posted refreshCount = ${refreshCount}');
  }
}

processDoorState(String responseText) {
  var response = JSON.decode(responseText);
  assert( response is Map );
  if( response['auth'] != 'OK' ) {
    querySelector('#status').classes.add('red');
    return;
  }
  querySelector("#status").text = response['state'];
  if( refreshCount++ < REFRESH_MAX && 
      !(response['state'] == 'closed' || response['state'] == 'opened') ) {   
    new Timer(REFRESH,()=>post(stateUri));
  } else {
    refreshCount = 0;
  }
}
