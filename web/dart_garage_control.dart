import 'dart:html';
import 'dart:async';
import 'dart:convert' show JSON;

const REFRESH = const Duration(seconds: 3);

final uriRoot = 'http://192.168.0.20:5110/gc/garagedoor';

final stateUri = '${uriRoot}/state';
final stopUri = '${uriRoot}/stop';
final openUri = '${uriRoot}/open';
final closeUri = '${uriRoot}/close';

var errorCount = 0;
var refreshCount = 0;
final ERROR_MAX =  5;
final REFRESH_MAX = 20;

void main() {
  querySelector("#refresh").onClick.listen((e)=>post(stateUri));
  querySelector("#stop").onClick.listen( (e)=>post(stopUri));
  querySelector('#close').onClick.listen( (e)=>post(closeUri));
  post(stateUri);
}

void post(String uri) {
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
  assert( response['auth'] == 'OK' );
  querySelector("#status").text = response['state'];
  if( refreshCount++ < REFRESH_MAX && !(response['state'] == 'closed' || response['state'] == 'opened') ) {   
    new Timer(REFRESH,()=>post(stateUri));
  } else {
    refreshCount = 0;
  }
}
