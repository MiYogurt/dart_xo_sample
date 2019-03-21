part of xo;

abstract class StoreState {
  StoreState copy();
  bool noEqual(newState){
    return this != newState;
  }
}

abstract class Action {}

typedef S Reducer<S extends StoreState>(S state, Action action);


class Store<S extends StoreState> {
  Reducer<S> reducer;
  List<Function> listener = [];
  S state;

  S getState(){
    return state;
  }

  void regiter(Reducer<S> reducer, { S initState }){
    this.reducer = reducer;
    state = initState;
  }

  void invoke(){
    listener.forEach((f) => Function.apply(f, []));
  }

  void subscribe(Function f){
    listener.add(f);
  }

  dispatch<A extends Action>(A action){
    var old = state.copy();
    this.state = reducer(old, action);
    if (old.noEqual(this)) {
      this.invoke();
    }
  }

}

Store store;

Store<S> createStore<S extends StoreState>(){
  if (store == null) {
    store = Store<S>();
  }
  return store;
}

typedef Component MapTo<S extends Store>(S s);

class Connect<S extends Store> extends Component {
  MapTo<S> _build;
  Connect(MapTo<S> build) {
    _build = build;
    store.subscribe((){
      this.setState((){});
    });
  }
  Component build() {
    return _build(store);
  }
}

