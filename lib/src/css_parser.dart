import 'dart:ui';

import 'package:csslib/visitor.dart' as css;
import 'package:csslib/parser.dart' as cssparser;
import 'package:flutter_html/style.dart';

Style declarationsToStyle(Map<String, List<css.Expression>> declarations) {
  Style style = new Style();
  declarations.forEach((property, value) {
    switch (property) {
      case 'background-color':
        style.backgroundColor =
            ExpressionMapping.expressionToColor(value.first);
        break;
      case 'color':
        style.color = ExpressionMapping.expressionToColor(value.first);
        break;
      case 'text-align':
        style.textAlign = ExpressionMapping.expressionToTextAlign(value.first);
        break;
      case 'text-decoration':
        style.textDecoration =
            ExpressionMapping.expressionToTextDecoration(value.first);
        break;
      case 'font-size':
        style.fontSize = ExpressionMapping.expressionToFontSize(value.first);
        break;
      case 'list-style-type':
        style.listStyleType =
            ExpressionMapping.expressionToListStyleType(value.first);
        break;
    }
  });
  return style;
}

Style inlineCSSToStyle(String inlineStyle) {
  final sheet = cssparser.parse("*{$inlineStyle}");
  final declarations = DeclarationVisitor().getDeclarations(sheet);
  return declarationsToStyle(declarations);
}

class DeclarationVisitor extends css.Visitor {
  Map<String, List<css.Expression>> _result;
  String _currentProperty;

  Map<String, List<css.Expression>> getDeclarations(css.StyleSheet sheet) {
    _result = new Map<String, List<css.Expression>>();
    sheet.visit(this);
    return _result;
  }

  @override
  void visitDeclaration(css.Declaration node) {
    _currentProperty = node.property;
    _result[_currentProperty] = new List<css.Expression>();
    node.expression.visit(this);
  }

  @override
  void visitExpressions(css.Expressions node) {
    node.expressions.forEach((expression) {
      _result[_currentProperty].add(expression);
    });
  }
}

//Mapping functions
class ExpressionMapping {
  static Color expressionToColor(css.Expression value) {
    if (value is css.HexColorTerm) {
      return stringToColor(value.text);
    } else if (value is css.FunctionTerm) {
      if (value.text == 'rgba') {
        return rgbOrRgbaToColor(value.span.text);
      } else if (value.text == 'rgb') {
        return rgbOrRgbaToColor(value.span.text);
      }
    }
    return null;
  }

  static Color stringToColor(String _text) {
    var text = _text.replaceFirst('#', '');
    if (text.length == 3)
      text = text.replaceAllMapped(
          RegExp(r"[a-f]|\d"), (match) => '${match.group(0)}${match.group(0)}');
    int color = int.parse(text, radix: 16);

    if (color <= 0xffffff) {
      return new Color(color).withAlpha(255);
    } else {
      return new Color(color);
    }
  }

  static Color rgbOrRgbaToColor(String text) {
    final rgbaText = text.replaceAll(')', '').replaceAll(' ', '');
    try {
      final rgbaValues =
          rgbaText.split(',').map((value) => double.parse(value)).toList();
      if (rgbaValues.length == 4) {
        return Color.fromRGBO(
          rgbaValues[0].toInt(),
          rgbaValues[1].toInt(),
          rgbaValues[2].toInt(),
          rgbaValues[3],
        );
      } else if (rgbaValues.length == 3) {
        return Color.fromRGBO(
          rgbaValues[0].toInt(),
          rgbaValues[1].toInt(),
          rgbaValues[2].toInt(),
          1.0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static TextAlign expressionToTextAlign(css.Expression value) {
    if (value is css.LiteralTerm) {
      switch (value.text) {
        case "center":
          return TextAlign.center;
        case "left":
          return TextAlign.left;
        case "right":
          return TextAlign.right;
        case "justify":
          return TextAlign.justify;
        case "end":
          return TextAlign.end;
        case "start":
          return TextAlign.start;
      }
    }
    return TextAlign.start;
  }

  static TextDecoration expressionToTextDecoration(css.Expression value) {
    if (value is css.LiteralTerm) {
      switch (value.text) {
        case "underline":
          return TextDecoration.underline;
        case "overline":
          return TextDecoration.overline;
        case "line-through":
          return TextDecoration.lineThrough;
      }
    }
    return TextDecoration.none;
  }

  static FontSize expressionToFontSize(css.Expression value) {
    if (value is css.LengthTerm) {
      final num size = value.value;
      return FontSize(size.toDouble());
    }
    return FontSize.medium;
  }

  static ListStyleType expressionToListStyleType(css.Expression value) {
    if (value is css.LiteralTerm) {
      switch (value.text) {
        case "decimal":
          return ListStyleTypes.decimal;
        case "upper-roman":
          return ListStyleTypes.upperRoman;
        case "upper-roman":
          return ListStyleTypes.upperRoman;
      }
    }
    return ListStyleTypes.disc;
  }
}
