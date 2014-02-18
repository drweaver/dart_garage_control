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

var timer = null;

void main() {
  post(stateUri);
  querySelector("#refresh").onClick.listen((e)=>post(stateUri));
  querySelector("#stop").onClick.listen( (e)=>post(stopUri));
  querySelector('#close').onClick.listen( (e)=>post(closeUri));
  querySelector('#open').onClick.listen( (e)=>post('$openUri?${posUriParams()}') );
  querySelector('#logout').onClick.listen( (e)=>window.location.assign('/oauth2/sign_in'));
  window.navigator.geolocation.watchPosition().listen((Geoposition position) {
    pos = position;
    print('Position = ${pos.coords.latitude},${pos.coords.longitude}');
    (querySelector("#open") as ButtonElement).disabled = false;
  }, onError: (e)=>print('PositionError: ${e.message}'));
}

String posUriParams() => 'lat=${pos.coords.latitude}&lng=${pos.coords.longitude}';

void post(String uri) {
  print('making request to: $uri');
  if( timer != null ) timer.cancel();
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
    if(errorCount++ > ERROR_MAX) window.location.reload();
    timer = new Timer(REFRESH, ()=>post(stateUri));
  } else {
    errorCount = 0;
    querySelector('#status').classes.remove('red');
      var response = JSON.decode(responseText);
  assert( response is Map );
  if( response['auth'] != 'OK' ) {
    querySelector('#status').classes.add('red');
    return;
  }
  querySelector("#status").text = response['state'];
  if( refreshCount++ < REFRESH_MAX && 
      !(response['state'] == 'closed' || response['state'] == 'opened') ) {   
    timer = new Timer(REFRESH,()=>post(stateUri));
  } else {
    refreshCount = 0;
  }
    print('Data has been posted refreshCount = ${refreshCount}');
  }
}

class DoorStateView {
  DoorStatePresenter presenter;
  var status =  querySelector('#status');
  var stop   =  querySelector("#stop");
  var refresh=  querySelector('#refresh');
  var open   =  querySelector('#open');
  var logout =  querySelector('#logout');
  var close  =  querySelector('#close');
  var spinner=  querySelector('#spinner');
  good =>  _status.classes.remove('red');
  bad  =>  _status.classes.add('red');
  set status(String status) => this.status.text = status;
  inProgress => spinner.classes.remove('hidden');
  finished => spinner.classes.add('hidden');
}

class DoorStatePresenter {
  DoorStateView view;
  Timer timer;
  Geoposition pos;
  var httpRequest = new HttpRequest();
  errorCount = 0;
  refreshCount = 0;
  DoorStatePresenter(this.view) {
    view.refresh.onClick.listen((e)=>post(stateUri));
    view.stop.onClick.listen( (e)=>post(stopUri));
    view.close.onClick.listen( (e)=>post(closeUri));
    view.open.onClick.listen( (e)=>post('$openUri?${posUriParams()}') );
    view.logout.onClick.listen( (e)=>window.location.assign('/oauth2/sign_in') );
  }
  String posUriParams() => 'lat=${pos.coords.latitude}&lng=${pos.coords.longitude}';
  void post(String uri) {
    print('making request to: $uri');
    if( timer != null ) timer.cancel();
    httpRequest.abort();
    view.inProgress();
    httpRequest..open('POST', uri)
               ..onLoadEnd.listen((e) => doorStateResponse())
               ..send();
  }
  doorStateResponse() {
    view.finished();
    view.good();
    if( request.status != 200) {
      print('Uh oh, there was an error of ${request.status} errorCount = ${errorCount}');
      view.bad();
      if(errorCount++ > ERROR_MAX) window.location.reload();
      timer = new Timer(REFRESH, ()=>post(stateUri));
      return;
    }
    errorCount = 0;
    var response = JSON.decode(responseText);
    if( response['auth'] != 'OK' ) {
      view.bad();
      return;
    }
    view.status = response['state'];
    if( refreshCount++ < REFRESH_MAX && 
      !(response['state'] == 'closed' || response['state'] == 'opened') ) {   
      timer = new Timer(REFRESH,()=>post(stateUri));
    } else {
      refreshCount = 0;
    }
  }
}
