import 'package:dart_xo/xo.dart';

class Base extends StoreState {
  String name;
  Base(this.name);
  Base copy() {
    return Base(this.name);
  }
}


class ChangeName extends Action {
  String name;
  ChangeName(this.name);
}

Base reducer(Base state, Action a) {
  if (a is ChangeName) {
    return state.copy()..name = a.name;
  }
  return state;
}

var store = createStore<Base>();


var route = RouterContainer({
  '/': (m) => h('div', ['a', Link('/b/2')]),
  '/b/:id': (m) => h('div', ['b', m.params['id'] ?? "", Link('/')])
}, defaultPath: '/');

class App2 extends Component {
  Component build() {
    return route;
  }
}

// class App extends Component {
//   String name;
//   App(this.name){
//     Future.delayed(Duration(milliseconds: 2000)).then((_){
//       this.setState((){
//         name = "2";
//       });
//       store.dispatch(new ChangeName("2"));
//     });
//   }
//   Component build() {
//     return h('div',[this.name, App2()]);
//   }
// }

void main() {
  store.regiter(reducer, initState: Base('init'));
  mount(App2(), "#output");
}
