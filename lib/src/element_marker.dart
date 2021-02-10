import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'html_elements.dart';

class ElementMarker extends SingleChildRenderObjectWidget {
  final StyledElement element;

  const ElementMarker({
    Key key,
    @required this.element,
    Widget child,
  })  : assert(element != null),
        super(key: key, child: child);

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _ElementMarker();
  }

  @override
  void updateRenderObject(BuildContext context, _ElementMarker renderObject) {}

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("Element", element.name));
  }
}

class _ElementMarker extends RenderProxyBox {
  _ElementMarker({
    RenderBox child,
  }) : super(child);

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = null;
    context.paintChild(child, offset);
  }
}
