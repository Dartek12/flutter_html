import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/html_elements.dart';
import 'package:flutter_html/src/styled_element.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:bit_array/bit_array.dart';
import 'package:html/dom.dart' as dom;

/// A [LayoutElement] is an element that breaks the normal Inline flow of
/// an html document with a more complex layout. LayoutElements handle
abstract class LayoutElement extends StyledElement {
  LayoutElement({
    String name,
    List<StyledElement> children,
    Style style,
    dom.Element node,
  }) : super(name: name, children: children, style: style, node: node);

  Widget toWidget(RenderContext context);
}

class TableLayoutElement extends LayoutElement {
  TableLayoutElement({
    String name,
    Style style,
    @required List<StyledElement> children,
    dom.Element node,
  }) : super(name: name, style: style, children: children, node: node);

  @override
  Widget toWidget(RenderContext context) {
    final rows = _getRows();
    final int columns = rows
        .map((row) => row.children
            .whereType<TableCellElement>()
            .fold(0, (int value, child) => value + child.colspan))
        .fold(0, max);

    final rowSizes = _getRowSizes(rows);
    final columnSizes = _getColumnSizes(columns);
    final cells = <GridPlacement>[];
    final tableGrid = _TableLayout(rows: rows.length, columns: columns);

    final borderWidth = double.tryParse(attributes['border'] ?? '') ?? 1.0;
    final tableBorder = Border.all(color: Colors.black, width: borderWidth);

    for (int rowi = 0; rowi < rows.length; rowi++) {
      final row = rows[rowi];

      for (var child in row.children.whereType<TableCellElement>()) {
        final coli = tableGrid.put(
            row: rowi, rowspan: child.rowspan, colspan: child.colspan);
        final border = _getBorder(
            base: tableBorder,
            row: rowi,
            col: coli,
            rowspan: child.rowspan,
            colspan: child.colspan,
            rows: rows.length,
            columns: columns);
        final color = child.style.backgroundColor ?? row.style.backgroundColor;

        cells.add(GridPlacement(
          child: Container(
            width: double.infinity,
            padding: child.style.padding ?? row.style.padding,
            decoration: BoxDecoration(color: color, border: border),
            alignment: child.style.alignment ??
                style.alignment ??
                Alignment.centerLeft,
            child: StyledText(
              textSpan: context.parser.parseTree(context, child),
              style: child.style,
            ),
          ),
          columnStart: coli,
          columnSpan: child.colspan,
          rowStart: rowi,
          rowSpan: child.rowspan,
        ));
      }
    }

    return LayoutBuilder(builder: (context, size) {
      return Container(
          decoration: BoxDecoration(
            color: style.backgroundColor,
            border: tableBorder,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: LayoutGrid(
              gridFit: GridFit.loose,
              templateColumnSizes: columnSizes,
              templateRowSizes: rowSizes,
              children: cells,
            ),
          ));
    });
  }

  List<TrackSize> _getColumnSizes(int columns) {
    const defaultMinSize = 120.0;
    List<TrackSize> columnSizes;

    final tableStyleElement = children.firstWhere(
        (element) => element is TableStyleElement,
        orElse: () => null);

    if (tableStyleElement != null) {
      columnSizes =
          tableStyleElement.children.where((c) => c.name == "col").map((c) {
        final colWidth = c.attributes["width"];

        if (colWidth == null) {
          return FlexibleMinFallbackTrackSize(flex: 1, minSize: defaultMinSize);
        } else if (colWidth.endsWith("%")) {
          final percentageSize =
              double.tryParse(colWidth.substring(0, colWidth.length - 1)) ?? 1;
          return FlexibleMinFallbackTrackSize(
              flex: percentageSize, minSize: defaultMinSize);
        } else {
          final fixedPxSize = double.tryParse(colWidth);
          return fixedPxSize != null
              ? FixedTrackSize(fixedPxSize)
              : FlexibleMinFallbackTrackSize(flex: 1, minSize: defaultMinSize);
        }
      });
    }

    return columnSizes ??
        List.generate(
            columns,
            (_) =>
                FlexibleMinFallbackTrackSize(flex: 1, minSize: defaultMinSize));
  }

  List<TrackSize> _getRowSizes(List<TableRowLayoutElement> rows) {
    return List.generate(rows.length, (_) => IntrinsicContentTrackSize());
  }

  List<TableRowLayoutElement> _getRows() {
    final rows = <TableRowLayoutElement>[];
    for (var child in children) {
      if (child is TableSectionLayoutElement) {
        rows.addAll(child.children.whereType());
      } else if (child is TableRowLayoutElement) {
        rows.add(child);
      }
    }
    return rows;
  }

  BorderSide _getBorderSide(BorderSide side, {bool edge}) {
    const scaleFactor = 4.0;
    return edge
        ? BorderSide.none
        : side.copyWith(width: side.width / scaleFactor);
  }

  Border _getBorder(
      {Border base,
      int row,
      int col,
      int rowspan,
      int colspan,
      int rows,
      int columns}) {
    final top = _getBorderSide(base.top, edge: row == 0);
    final left = _getBorderSide(base.left, edge: col == 0);
    final right = _getBorderSide(base.right, edge: col + colspan == columns);
    final bottom = _getBorderSide(base.bottom, edge: row + rowspan == rows);

    return Border(top: top, left: left, right: right, bottom: bottom);
  }
}

class TableSectionLayoutElement extends LayoutElement {
  TableSectionLayoutElement({
    String name,
    @required List<StyledElement> children,
  }) : super(name: name, children: children);

  @override
  Widget toWidget(RenderContext context) {
    // Not rendered; TableLayoutElement will instead consume its children
    return Container(child: Text("TABLE SECTION"));
  }
}

class TableRowLayoutElement extends LayoutElement {
  TableRowLayoutElement({
    String name,
    @required List<StyledElement> children,
    dom.Element node,
  }) : super(name: name, children: children, node: node);

  @override
  Widget toWidget(RenderContext context) {
    // Not rendered; TableLayoutElement will instead consume its children
    return Container(child: Text("TABLE ROW"));
  }
}

class TableCellElement extends StyledElement {
  int colspan = 1;
  int rowspan = 1;

  TableCellElement({
    String name,
    String elementId,
    List<String> elementClasses,
    @required List<StyledElement> children,
    Style style,
    dom.Element node,
  }) : super(
            name: name,
            elementId: elementId,
            elementClasses: elementClasses,
            children: children,
            style: style,
            node: node) {
    colspan = _parseSpan(this, "colspan");
    rowspan = _parseSpan(this, "rowspan");
  }

  static int _parseSpan(StyledElement element, String attributeName) {
    final spanValue = element.attributes[attributeName];
    return spanValue == null ? 1 : int.tryParse(spanValue) ?? 1;
  }
}

TableCellElement parseTableCellElement(
  dom.Element element,
  List<StyledElement> children,
) {
  final cell = TableCellElement(
    name: element.localName,
    elementId: element.id,
    elementClasses: element.classes.toList(),
    children: children,
    node: element,
  );
  if (element.localName == "th") {
    cell.style = Style(
      fontWeight: FontWeight.bold,
    );
  }
  return cell;
}

class TableStyleElement extends StyledElement {
  TableStyleElement({
    String name,
    List<StyledElement> children,
    Style style,
    dom.Element node,
  }) : super(name: name, children: children, style: style, node: node);
}

TableStyleElement parseTableDefinitionElement(
  dom.Element element,
  List<StyledElement> children,
) {
  switch (element.localName) {
    case "colgroup":
    case "col":
      return TableStyleElement(
        name: element.localName,
        children: children,
        node: element,
      );
    default:
      return TableStyleElement();
  }
}

LayoutElement parseLayoutElement(
  dom.Element element,
  List<StyledElement> children,
) {
  switch (element.localName) {
    case "table":
      return TableLayoutElement(
        name: element.localName,
        children: children,
        node: element,
      );
      break;
    case "thead":
    case "tbody":
    case "tfoot":
      return TableSectionLayoutElement(
        name: element.localName,
        children: children,
      );
      break;
    case "tr":
      return TableRowLayoutElement(
        name: element.localName,
        children: children,
        node: element,
      );
      break;
    default:
      return TableLayoutElement(children: children);
  }
}

class _TableLayout {
  final int _rows;
  final int _columns;
  final BitArray _array;

  _TableLayout({@required int rows, @required int columns})
      : _rows = rows,
        _columns = columns,
        _array = BitArray(rows * columns);

  int put({@required int row, @required int rowspan, @required int colspan}) {
    rowspan = max(1, rowspan);
    colspan = max(1, colspan);

    final int start = row * _columns;
    final int end = (row + 1) * _columns;

    for (int i = start; i < end; i++) {
      if (!_array[i]) {
        final column = i - start;
        _reserve(row: row, column: column, rowspan: rowspan, colspan: colspan);
        return column;
      }
    }

    throw 'No place to put cell';
  }

  void _reserve(
      {@required int row,
      @required int column,
      @required int rowspan,
      @required int colspan}) {
    assert(column + colspan <= _columns);
    assert(row + rowspan <= _rows);

    for (int i = 0; i < rowspan; i++) {
      int index = (row + i) * _columns + column;
      for (int j = 0; j < colspan; j++, index++) {
        _array.setBit(index);
      }
    }
  }

  @override
  String toString() {
    final regexp = RegExp('(0|1){$_columns}');
    return _array
        .toBinaryString()
        .substring(0, _columns * _rows)
        .replaceAllMapped(regexp, (match) => '${match.group(0)}\n');
  }
}

class FlexibleMinFallbackTrackSize extends FlexibleTrackSize {
  final double minSize;

  FlexibleMinFallbackTrackSize({double flex, @required this.minSize})
      : super(flex);

  @override
  bool isFixedForConstraints(TrackType type, BoxConstraints gridConstraints) {
    return !gridConstraints.hasBoundedWidth;
  }

  @override
  double minIntrinsicSize(
      TrackType type, Iterable<RenderBox> items, double measurementAxisMaxSize,
      {double Function(RenderBox p1) crossAxisSizeForItem}) {
    return minSize;
  }
}
