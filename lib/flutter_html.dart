library flutter_html;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/element_marker.dart';
import 'package:flutter_html/style.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Html extends StatefulWidget {
  /// The `Html` widget takes HTML as input and displays a RichText
  /// tree of the parsed HTML content.
  ///
  /// **Attributes**
  /// **data** *required* takes in a String of HTML data.
  ///
  ///
  /// **onLinkTap** This function is called whenever a link (`<a href>`)
  /// is tapped.
  /// **customRender** This function allows you to return your own widgets
  /// for existing or custom HTML tags.
  /// See [its wiki page](https://github.com/Sub6Resources/flutter_html/wiki/All-About-customRender) for more info.
  ///
  /// **onImageError** This is called whenever an image fails to load or
  /// display on the page.
  ///
  /// **shrinkWrap** This makes the Html widget take up only the width it
  /// needs and no more.
  ///
  /// **onImageTap** This is called whenever an image is tapped.
  ///
  /// **blacklistedElements** Tag names in this array are ignored during parsing and rendering.
  ///
  /// **style** Pass in the style information for the Html here.
  /// See [its wiki page](https://github.com/Sub6Resources/flutter_html/wiki/Style) for more info.
  Html({
    Key key,
    @required this.data,
    this.onLinkTap,
    this.customRender,
    this.onImageError,
    this.shrinkWrap = false,
    this.onImageTap,
    this.controller,
    this.blacklistedElements = const [],
    this.style,
    this.navigationDelegateForIframe,
  }) : super(key: key);

  final String data;
  final OnTap onLinkTap;
  final ImageErrorListener onImageError;
  final bool shrinkWrap;

  /// Controller for manipulating content.
  final HtmlController controller;

  /// Properties for the Image widget that gets rendered by the rich text parser
  final OnTap onImageTap;

  /// List of blacklisted elements
  final List<String> blacklistedElements;

  /// Either return a custom widget for specific node types or return null to
  /// fallback to the default rendering.
  final Map<String, CustomRender> customRender;

  /// Fancy New Parser parameters
  final Map<String, Style> style;

  /// Decides how to handle a specific navigation request in the WebView of an
  /// Iframe. It's necessary to use the webview_flutter package inside the app
  /// to use NavigationDelegate.
  final NavigationDelegate navigationDelegateForIframe;

  @override
  _HtmlState createState() => _HtmlState();
}

class _HtmlState extends State<Html> {
  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant Html oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller?._state = null;
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width =
        widget.shrinkWrap ? null : MediaQuery.of(context).size.width;

    return Container(
      width: width,
      child: HtmlParser(
        htmlData: widget.data,
        onLinkTap: widget.onLinkTap,
        onImageTap: widget.onImageTap,
        onImageError: widget.onImageError,
        shrinkWrap: widget.shrinkWrap,
        style: widget.style,
        customRender: widget.customRender,
        blacklistedElements: widget.blacklistedElements,
        navigationDelegateForIframe: widget.navigationDelegateForIframe,
      ),
    );
  }
}

class HtmlController {
  _HtmlState _state;

  void scrollTo(String id,
      {Duration duration = Duration.zero,
      double alignment = 0.0,
      Curve curve = Curves.ease,
      ScrollPositionAlignmentPolicy alignmentPolicy =
          ScrollPositionAlignmentPolicy.explicit}) {
    final context = _state?.context;
    if (context == null) {
      return;
    }

    bool found = false;

    void visitor(Element element) {
      final markerWidget = cast<ElementMarker>(element.widget);

      if (markerWidget != null) {
        if (markerWidget.element.elementId == id) {
          found = true;
          Scrollable.ensureVisible(element,
              duration: duration,
              curve: curve,
              alignment: alignment,
              alignmentPolicy: alignmentPolicy);
          return;
        }
      }

      if (found) {
        return;
      }

      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
  }

  void dispose() {
    _state = null;
  }
}

T cast<T>(x) => x is T ? x : null;
