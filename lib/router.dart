part of xo;

class RouteMatch {
  Map<String, String> params;
  String path;
  Route route;
  Map meta;

  empty() {
    params = {};
    path = '';
    route = null;
    meta =  {};
  }
}

typedef void RouterCallback(RouteMatch route);

class Route {
  String path; // /user/:id
  List<String> params = []; // ['id']
  RegExp matcher; // /user/(\w*)
  RouterCallback callback;
  Route({this.path, this.callback}) {
    pathToRegExp(path);
  }

  pathToRegExp(String path) {
    var regular = path.replaceAllMapped(RegExp(r"\:(\w*)"), (m) {
      // replace (:param)
      this.params.add(m.group(1));
      return "(\\w*)";
    })
      ..replaceAllMapped(RegExp(r"\/$"), (m) {
        // replace end / is option
        return "\/?\$";
      });

    matcher = RegExp("${regular}");
  }

  RouteMatch exec(String uri, RouteMatch match, [Map meta]) {
    List<String> lists;
    matcher.allMatches(uri).forEach((m) {
      var iter = List.generate(m.groupCount, (i) => (i + 1));
      lists = m.groups(iter);
    });
    if (lists != null && lists.length == params.length) {
      match.empty();
      match.params = Map.fromIterables(params, lists);
      match.path = uri;
      match.route = this;
      match.meta = meta;
      return match;
    }
    return null;
  }
}

class Router {
  RouteMatch matcher = RouteMatch();
  List<Route> config = [];

  Router({Map<String, RouterCallback> config}) {
    if (config != null) {
      this.config = config
          .map((k, v) => MapEntry(k, Route(path: k, callback: v)))
          .values
          .toList();
    }
  }

  add(String path, RouterCallback callback) {
    var meta = Route(path: path, callback: callback);
    config.add(meta);
    return this;
  }

  off(String path) {
    config.removeWhere((c) => c.path == path);
    return this;
  }

  void exec(String path, [Map meta]) {
    for (var item in config) {

      var matcher = item.exec(path, this.matcher, meta);
      if (matcher != null) {
        item.callback(matcher);
      }
    }
  }
}

Map<String, Router> routers = {};

var initd = false;

typedef Component BuildComponent(RouteMatch m);

class RouterContainer extends Component {
  Map<String, BuildComponent> routeMap;
  Router r;
  String name;
  String defaultPath;
  Component active;
  RouteMatch match;
  RouterContainer(this.routeMap,
      {this.defaultPath,
      this.name = "default"}) {
    r = Router();
    routers.addAll({name: r});
    this.routeMap.forEach((key, callback) {
      r.add(key, (_match) {
        var meta = _match.meta;
        if (meta == null || meta['replace'] == false) {
          window.history.pushState({"path": _match.path}, null, _match.path);
        } else {
          window.history.replaceState({"path": _match.path}, null, _match.path);
        }
        var comp = callback(_match);
        if (comp != null) {
          active = comp;
        }
        match = _match;
        update();
      });
    });

    r.exec(defaultPath);
    r.exec(window.location.pathname, {"replace": true});

    if (!initd) {
      window.addEventListener('popstate', (_) {
        routers.forEach((path, router) {
          router.exec(window.location.pathname);
        });
      }, false);
      initd = true;
    }
  }

  update() {
    setState(() {});
  }

  Component build() {
    return active;
  }
}

void linkTo(String path, {String routeName, bool replace = false}) {
  if (routeName.isEmpty) {
    routers['default'].exec(path, {"replace": replace});
  } else {
    var router = routers[routeName];
    if (router == null) {
      print('not founed $routeName');
    }
    router.exec(path, {"replace": replace});
  }
}

class Link extends Component {
  String to;
  String tagName;
  String routeName;
  dynamic child;
  Map<String, dynamic> props = {};
  Link(this.to,
      {this.tagName = "a",
      this.routeName = "default",
      Map<String, dynamic> props,
      dynamic child}) {
    if (props != null && props.isNotEmpty) {
      this.props = props;
    }
    this.props['href'] = to;
    Map events = this.props['no'];
    if (events != null) {
      if (events['click'] == null) {
        events['click'] = _linkTo;
      } else {
        var _userClick = events['click'];
        events['click'] = (Event e) {
          _userClick(e);
          _linkTo(e);
        };
      }
    } else {
      this.props['on'] = {"click": _linkTo};
      ;
    }

    if (child != null) {
      this.child = child;
    } else {
      this.child = to;
    }
  }

  _linkTo(Event e) {
    e.preventDefault();
    e.stopPropagation();
    linkTo(to, routeName: routeName);
  }

  @override
  Component build() {
    return h(
         this.tagName, this.props, [this.child]);
  }
}