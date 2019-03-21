part of xo;

class BaseContext{
  Element el;
  String tagName;
  bool isText = false;
  Map props;
  List childrens;
  BaseContext({this.tagName, this.props, this.childrens});
}


class Component{
  bool isPure = false;
  BaseContext context = BaseContext(tagName: null, props: null, childrens: null); 
  Component();
  Component build() {
    return null;
  }

  Component.replaceContext(this.context) {
    this.context = context;
    isPure = true;
  }

  setState(Function fn) {
    fn();
    rerender();
  }
}

Element app;
Component root;

void mount([Component _root, String id]) {
  root = _root;
  root.context.el = app;
  if (app == null) {
    app = querySelector(id);
  }
  if (app == null) {
    throw Exception("not found $id");
  }
  resolveBuild(root);
  var dom = render(root.context);
  app.children.add(dom);
}


BaseContext resolveBuild(dynamic root)
{

  if (root is BaseContext) {
    return root;
  }

  if (root is Component) {
    if (root.isPure) {
      // 处理子节点的 Component
      root.context.childrens = root.context.childrens.map(resolveBuild).toList();
      return root.context;
    } 

    root.context = resolveBuild(root.build());
    return root.context;
  }

  if (root is String) {
    var textWrap = new BaseContext(tagName: null, props: null, childrens: [root]);
    textWrap.isText = true;
    return textWrap;
  }
  return root;
}

Element render(BaseContext context)
{
  var dom = document.createElement(context.tagName);

  if (context.props.isNotEmpty) {
    context.props.forEach((key, value){
      if (key == 'on') {
        value.forEach((k,v) => dom.addEventListener(k, v));
        return;
      }
      dom.setAttribute(key, value);
    });
  }

  if (context.childrens!= null && context.childrens.isNotEmpty) {
    var doms = context.childrens.map((ctx) {
      if (ctx is BaseContext) {
        if (!ctx.isText) {
          ctx.el = render(ctx);
        }else {
          ctx.el = createTextNode(ctx.childrens.first);
        }
        return ctx.el;
      }
    });
    dom.children.addAll(doms);
  }
  context.el = dom;
  return dom;
}


Component h([String tagName, dynamic props, List childrens]) {
  if (props is List) {
    childrens = props;
    props = {};
  }
  var context = BaseContext(tagName: tagName, props: props, childrens: childrens);
  return  Component.replaceContext(context);
}
var hasRenderNextTick = false;

void rerender(){
  if (hasRenderNextTick) {
    return;
  }
  hasRenderNextTick = true;
  Future.microtask((){
    var ctx = resolveBuild(root);
    var dom =render(ctx);
    app.firstChild.replaceWith(dom);
  }).then((_){
    hasRenderNextTick = false;
  });
}
