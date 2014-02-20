import 'dart:html';
import 'dart:async';
import 'dart:convert' show JSON;

void main() {
  
  var view = new DoorStateView();
  
  var statePresenter = new DoorStatePresenter.attachToView( view );
  statePresenter.refresh();
  
  var authLocationPresenter = new AuthLocationPresenter.attachToView( view );
  statePresenter.position = authLocationPresenter;
  authLocationPresenter.startLocationListener();

}

class DoorStateView {
  var state =  querySelector('#status');
  ButtonElement stop   =  querySelector("#stop");
  ButtonElement refresh=  querySelector('#refresh');
  ButtonElement open   =  querySelector('#open');
  ButtonElement logout =  querySelector('#logout');
  ButtonElement close  =  querySelector('#close');
  var spinner=  querySelector('#spinner');
  good() =>  state.classes.remove('red');
  bad()  =>  state.classes.add('red');
  inProgress() => spinner.classes.remove('hidden');
  finished() => spinner.classes.add('hidden');
  canOpen() {
    open.disabled = false;
    open.classes.remove('red');
  }
  cannotOpen() {
    open.disabled = true;
    open.classes.add('red');
  }
}

class HasPosition {
  Geoposition position;
  get coords => position.coords;
}

String posUrlParams(HasPosition position) {
  if( position == null ) return '';
  return 'lat=${position.coords.latitude}&lng=${position.coords.longitude}';
}

class AuthLocationPresenter implements HasPosition {
  DoorStateView _view;
  
  Geoposition position;
  get coords => position.coords;
  
  AuthLocationPresenter.attachToView(this._view);
  
  startLocationListener() {
    _view.cannotOpen();
    window.navigator.geolocation.watchPosition().listen((Geoposition position) {
      //TODO: Probably only worth doing this if moving more than 1/2 mile?
      this.position = position;
      print('Position = ${position.coords.latitude},${position.coords.longitude}');
      _authLocation(position);
    }, onError: (e)=>print('PositionError: ${e.message}'));
  }
  
  _authLocation(position) => _post('garagedoor/authlocation?${posUrlParams(this)}');

  void _post(String uri) {
    print('making request to: $uri');
    var _httpRequest = new HttpRequest();
    _httpRequest..open('POST', uri)
                ..onLoadEnd.listen((e)=>_authLocationResponse(_httpRequest))
                ..send();
  }
  
  _authLocationResponse(HttpRequest httpRequest) {
    if( httpRequest.status != 200 ) {
      print('Server Error: ${httpRequest.status}');
      return;
    }
    var response = JSON.decode(httpRequest.responseText);
    if( response is! Map || !response.containsKey('auth') ) {
      print('Unexpected data returned from server: ${httpRequest.responseText}');
      return;
    }
    if( response['auth'] != 'OK' ) {
      _view.cannotOpen();
    } else {
      _view.canOpen();
    }
  }
  
}



class DoorStatePresenter {
  DoorStateView _view;
  Timer _timer;
  HasPosition position;

  var _errorCount = 0;
  var _refreshCount = 0;
  
  final ERROR_MAX =  3;
  final REFRESH_MAX = 10;
  
  DoorStatePresenter.attachToView(this._view) {
    _view.refresh.onClick.listen( (e)=>refresh() );
    _view.stop.onClick.listen( (e)=>_stop() );
    _view.close.onClick.listen( (e)=>_close() );
    _view.open.onClick.listen( (e)=>_open() );
    _view.logout.onClick.listen( (e)=>window.location.assign('/oauth2/sign_in') );
  }
  
  refresh() => _post('garagedoor/state');
  _stop() => _post('garagedoor/stop');
  _close() => _post('garagedoor/close');
  _open() => _post('garagedoor/open?${posUrlParams(position)}');
  
  Timer _refreshDelayed({seconds: 3}) => new Timer(new Duration(seconds: seconds), refresh);
    
  void _post(String uri) {
    _view.inProgress();
    print('making request to: $uri');
    if( _timer != null ) _timer.cancel();
    var _httpRequest = new HttpRequest();
    _httpRequest..open('POST', uri)
                ..onLoadEnd.listen((e)=>_doorStateResponse(_httpRequest))
                ..send();
  }
  
  bool _doorMoving(String state)=>['opening','closing'].contains(state);

  _serverError(error) {
    print('Server Error: ${error}, errorCount = ${_errorCount}');
    _view.bad();
    if(_errorCount++ >= ERROR_MAX) window.location.reload();
    if( _timer == null || !_timer.isActive ) _timer = _refreshDelayed();
  }
  
  _doorStateResponse(HttpRequest _httpRequest) {
    _view.finished();
    _view.good();
    if( _httpRequest.status != 200) {
      _serverError(_httpRequest.status);
      return;
    }
    var response = JSON.decode(_httpRequest.responseText);
    if( response is! Map || !response.containsKey('auth') ) {
      _serverError('Unexpected data returned from server: ${_httpRequest.responseText}');
      return;
    }
    if( response['auth'] != 'OK' ) {
      _view.cannotOpen();
      return;
    }
    if( !response.containsKey('state') ) {
      _serverError('Unexpected data returned from server: ${_httpRequest.responseText}');
      return;
    }
    _errorCount = 0;
    var state = _view.state.text = response['state'];
    if( _doorMoving(state) ) {   
      if( _refreshCount++ >= REFRESH_MAX ) return; 
      if( _timer == null || !_timer.isActive) _timer = _refreshDelayed();
    } 
    _refreshCount = 0;
  }
}
