import 'package:flutter_test/flutter_test.dart';
import 'test.dart';

void main() {
  // Test each HTML element
  group('golden tests', () {
    testHtml('complex_table', '''
      <table>
        <thead>
          <tr>
            <th rowspan="2">One</th>
            <th rowspan="2">Two</th>
            <th colspan="3" style="background-color: red;">Three</th>
            <th rowspan="2">Four</th>
          </tr>
          <tr>
            <th>3.1</th>
            <th>3.2</th>
            <th>3.3</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td rowspan='2' style="background-color: orange;">Rowspan\nRowspan\nRowspan\nRowspan\nRowspan\nRowspan\nRowspan\nRowspan\nRowspan\nRowspan</td>
            <td>Data</td>
            <td>Data</td>
            <td>Data</td>
            <td>Data</td>
            <td>Data</td>
          </tr>
          <tr>
            <td colspan="2">Data</td>
            <td>Data</td>
            <td>Data</td>
            <td>Data</td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td>fData</td>
            <td>fData</td>
            <td colspan="4">fData</td>
          </tr>
        </tfoot>
      </table>
      ''');
  });
}
