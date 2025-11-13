import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// A utility class for parsing SVG content and extracting elements with transforms
class SVGParser {
  /// Extract all SVG elements with their transforms from SVG content
  static Future<List<Map<String, dynamic>>> extractSVGElements(String svgContent) async {
    final List<Map<String, dynamic>> allElements = [];
    
    // Extract path elements with transforms
    allElements.addAll(extractPathElementsWithTransforms(svgContent));
    
    // Extract ellipse elements with transforms
    allElements.addAll(extractEllipsePathsWithTransforms(svgContent));
    
    // Extract circle elements with transforms
    allElements.addAll(extractCirclePathsWithTransforms(svgContent));
    
    // Extract rectangle elements with transforms
    allElements.addAll(extractRectPathsWithTransforms(svgContent));
    
    // Extract line elements with transforms
    allElements.addAll(extractLinePathsWithTransforms(svgContent));
    
    // Extract polygon elements with transforms
    allElements.addAll(extractPolygonPathsWithTransforms(svgContent));
    
    // Extract polyline elements with transforms
    allElements.addAll(extractPolylinePathsWithTransforms(svgContent));
    
    return allElements;
  }

  /// Extract SVG dimensions from content
  static Map<String, double> extractSVGDimensions(String svgContent) {
    final viewBoxMatch = RegExp(r'viewBox="([^"]*)"').firstMatch(svgContent) ?? 
                       RegExp(r"viewBox='([^']*)'").firstMatch(svgContent);
    final widthMatch = RegExp(r'width="?([0-9.]+)"?').firstMatch(svgContent);
    final heightMatch = RegExp(r'height="?([0-9.]+)"?').firstMatch(svgContent);

    double width = 800; // default width
    double height = 600; // default height

    if (viewBoxMatch != null) {
      final viewBoxValue = viewBoxMatch.group(1);
      if (viewBoxValue != null) {
        final viewBoxValues = viewBoxValue.split(RegExp(r'\s+'));
        if (viewBoxValues.length >= 4) {
          width = double.tryParse(viewBoxValues[2]) ?? 800;
          height = double.tryParse(viewBoxValues[3]) ?? 600;
        }
      }
    } else {
      // Try to get width and height attributes
      if (widthMatch != null) {
        final widthValue = widthMatch.group(1);
        if (widthValue != null) {
          width = double.tryParse(widthValue) ?? 800;
        }
      }
      if (heightMatch != null) {
        final heightValue = heightMatch.group(1);
        if (heightValue != null) {
          height = double.tryParse(heightValue) ?? 600;
        }
      }
    }

    return {
      'width': width,
      'height': height,
    };
  }

  /// Download and parse SVG from URL
  static Future<Map<String, dynamic>> downloadAndParseSVG(String svgUrl) async {
    try {
      final response = await Dio().get(svgUrl);
      if (response.statusCode != 200) {
        throw Exception('Failed to load SVG: ${response.statusCode}');
      }

      final svgContent = response.data;
      final elements = await extractSVGElements(svgContent);
      final dimensions = extractSVGDimensions(svgContent);

      return {
        'elements': elements,
        'width': dimensions['width'],
        'height': dimensions['height'],
      };
    } catch (e) {
      debugPrint('Failed to download and parse SVG: $e');
      rethrow;
    }
  }

  /// Create a fallback UI image with specified dimensions
  static Future<ui.Image> createFallbackImage({int width = 800, int height = 600}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = const Color(0x00000000); // Transparent
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  /// Extract path elements with transform information
  static List<Map<String, dynamic>> extractPathElementsWithTransforms(String svgContent) {
    final List<Map<String, dynamic>> pathElements = [];
    
    final pathRegex = RegExp(r'<path[^>]*>');
    final matches = pathRegex.allMatches(svgContent);
    
    for (final match in matches) {
      final pathElement = match.group(0) ?? '';
      
      // Extract path data
      final dMatch = RegExp(r'd="([^"]+)"').firstMatch(pathElement);
      if (dMatch != null) {
        final pathData = dMatch.group(1) ?? '';
        
        // Extract transform if present
        final transformMatch = RegExp(r'transform="([^"]+)"').firstMatch(pathElement);
        final transform = transformMatch?.group(1);
        
        pathElements.add({
          'pathData': pathData,
          'transform': transform,
          'type': 'path',
        });
      }
    }
    
    return pathElements;
  }

  /// Extract ellipse elements with transform information
  static List<Map<String, dynamic>> extractEllipsePathsWithTransforms(String svgContent) {
    final List<Map<String, dynamic>> ellipsePaths = [];
    
    final ellipseRegex = RegExp(r'<ellipse[^>]*>');
    final matches = ellipseRegex.allMatches(svgContent);
    
    for (final match in matches) {
      final ellipseElement = match.group(0) ?? '';
      
      // Extract ellipse attributes
      final cxMatch = RegExp(r'cx="([^"]*)"').firstMatch(ellipseElement);
      final cyMatch = RegExp(r'cy="([^"]*)"').firstMatch(ellipseElement);
      final rxMatch = RegExp(r'rx="([^"]*)"').firstMatch(ellipseElement);
      final ryMatch = RegExp(r'ry="([^"]*)"').firstMatch(ellipseElement);
      
      if (cxMatch != null && cyMatch != null && rxMatch != null && ryMatch != null) {
        final double cx = double.tryParse(cxMatch.group(1) ?? '0') ?? 0;
        final double cy = double.tryParse(cyMatch.group(1) ?? '0') ?? 0;
        final double rx = double.tryParse(rxMatch.group(1) ?? '0') ?? 0;
        final double ry = double.tryParse(ryMatch.group(1) ?? '0') ?? 0;
        
        // Convert ellipse to path data using arc commands
        final pathData = ellipseToPath(cx, cy, rx, ry);
        
        // Extract transform if present
        final transformMatch = RegExp(r'transform="([^"]+)"').firstMatch(ellipseElement);
        final transform = transformMatch?.group(1);
        
        ellipsePaths.add({
          'pathData': pathData,
          'transform': transform,
          'type': 'ellipse',
        });
      }
    }
    
    return ellipsePaths;
  }

  /// Extract circle elements with transform information
  static List<Map<String, dynamic>> extractCirclePathsWithTransforms(String svgContent) {
    final List<Map<String, dynamic>> circlePaths = [];
    
    final circleRegex = RegExp(r'<circle[^>]*>');
    final matches = circleRegex.allMatches(svgContent);
    
    for (final match in matches) {
      final circleElement = match.group(0) ?? '';
      
      // Extract circle attributes
      final cxMatch = RegExp(r'cx="([^"]*)"').firstMatch(circleElement);
      final cyMatch = RegExp(r'cy="([^"]*)"').firstMatch(circleElement);
      final rMatch = RegExp(r'r="([^"]*)"').firstMatch(circleElement);
      
      if (cxMatch != null && cyMatch != null && rMatch != null) {
        final double cx = double.tryParse(cxMatch.group(1) ?? '0') ?? 0;
        final double cy = double.tryParse(cyMatch.group(1) ?? '0') ?? 0;
        final double r = double.tryParse(rMatch.group(1) ?? '0') ?? 0;
        
        // Convert circle to path data (circle is an ellipse with rx = ry = r)
        final pathData = ellipseToPath(cx, cy, r, r);
        
        // Extract transform if present
        final transformMatch = RegExp(r'transform="([^"]+)"').firstMatch(circleElement);
        final transform = transformMatch?.group(1);
        
        circlePaths.add({
          'pathData': pathData,
          'transform': transform,
          'type': 'circle',
        });
      }
    }
    
    return circlePaths;
  }

  /// Extract rectangle elements with transform information
  static List<Map<String, dynamic>> extractRectPathsWithTransforms(String svgContent) {
    final List<Map<String, dynamic>> rectPaths = [];
    
    final rectRegex = RegExp(r'<rect[^>]*>');
    final matches = rectRegex.allMatches(svgContent);
    
    for (final match in matches) {
      final rectElement = match.group(0) ?? '';
      
      // Extract rect attributes
      final xMatch = RegExp(r'x="([^"]*)"').firstMatch(rectElement);
      final yMatch = RegExp(r'y="([^"]*)"').firstMatch(rectElement);
      final widthMatch = RegExp(r'width="([^"]*)"').firstMatch(rectElement);
      final heightMatch = RegExp(r'height="([^"]*)"').firstMatch(rectElement);
      final rxMatch = RegExp(r'rx="([^"]*)"').firstMatch(rectElement);
      final ryMatch = RegExp(r'ry="([^"]*)"').firstMatch(rectElement);
      
      if (widthMatch != null && heightMatch != null) {
        final double x = double.tryParse(xMatch?.group(1) ?? '0') ?? 0;
        final double y = double.tryParse(yMatch?.group(1) ?? '0') ?? 0;
        final double width = double.tryParse(widthMatch.group(1) ?? '0') ?? 0;
        final double height = double.tryParse(heightMatch.group(1) ?? '0') ?? 0;
        final double rx = double.tryParse(rxMatch?.group(1) ?? '0') ?? 0;
        final double ry = double.tryParse(ryMatch?.group(1) ?? '0') ?? 0;
        
        // Convert rectangle to path data
        final pathData = rectToPath(x, y, width, height, rx, ry);
        
        // Extract transform if present
        final transformMatch = RegExp(r'transform="([^"]+)"').firstMatch(rectElement);
        final transform = transformMatch?.group(1);
        
        rectPaths.add({
          'pathData': pathData,
          'transform': transform,
          'type': 'rect',
        });
      }
    }
    
    return rectPaths;
  }

  /// Extract line elements with transform information
  static List<Map<String, dynamic>> extractLinePathsWithTransforms(String svgContent) {
    final List<Map<String, dynamic>> linePaths = [];
    
    final lineRegex = RegExp(r'<line[^>]*>');
    final matches = lineRegex.allMatches(svgContent);
    
    for (final match in matches) {
      final lineElement = match.group(0) ?? '';
      
      // Extract line attributes
      final x1Match = RegExp(r'x1="([^"]*)"').firstMatch(lineElement);
      final y1Match = RegExp(r'y1="([^"]*)"').firstMatch(lineElement);
      final x2Match = RegExp(r'x2="([^"]*)"').firstMatch(lineElement);
      final y2Match = RegExp(r'y2="([^"]*)"').firstMatch(lineElement);
      
      if (x1Match != null && y1Match != null && x2Match != null && y2Match != null) {
        final double x1 = double.tryParse(x1Match.group(1) ?? '0') ?? 0;
        final double y1 = double.tryParse(y1Match.group(1) ?? '0') ?? 0;
        final double x2 = double.tryParse(x2Match.group(1) ?? '0') ?? 0;
        final double y2 = double.tryParse(y2Match.group(1) ?? '0') ?? 0;
        
        // Convert line to path data
        final pathData = 'M $x1 $y1 L $x2 $y2';
        
        // Extract transform if present
        final transformMatch = RegExp(r'transform="([^"]+)"').firstMatch(lineElement);
        final transform = transformMatch?.group(1);
        
        linePaths.add({
          'pathData': pathData,
          'transform': transform,
          'type': 'line',
        });
      }
    }
    
    return linePaths;
  }

  /// Extract polygon elements with transform information
  static List<Map<String, dynamic>> extractPolygonPathsWithTransforms(String svgContent) {
    final List<Map<String, dynamic>> polygonPaths = [];
    
    final polygonRegex = RegExp(r'<polygon[^>]*points="([^"]+)"[^>]*>');
    final matches = polygonRegex.allMatches(svgContent);
    
    for (final match in matches) {
      final polygonElement = match.group(0) ?? '';
      final pointsString = match.group(1) ?? '';
      
      if (pointsString.isNotEmpty) {
        // Convert polygon points to path data
        final pathData = polygonPointsToPath(pointsString, true); // true for closing path
        if (pathData.isNotEmpty) {
          // Extract transform if present
          final transformMatch = RegExp(r'transform="([^"]+)"').firstMatch(polygonElement);
          final transform = transformMatch?.group(1);
          
          polygonPaths.add({
            'pathData': pathData,
            'transform': transform,
            'type': 'polygon',
          });
        }
      }
    }
    
    return polygonPaths;
  }

  /// Extract polyline elements with transform information
  static List<Map<String, dynamic>> extractPolylinePathsWithTransforms(String svgContent) {
    final List<Map<String, dynamic>> polylinePaths = [];
    
    final polylineRegex = RegExp(r'<polyline[^>]*points="([^"]+)"[^>]*>');
    final matches = polylineRegex.allMatches(svgContent);
    
    for (final match in matches) {
      final polylineElement = match.group(0) ?? '';
      final pointsString = match.group(1) ?? '';
      
      if (pointsString.isNotEmpty) {
        // Convert polyline points to path data
        final pathData = polygonPointsToPath(pointsString, false); // false for not closing path
        if (pathData.isNotEmpty) {
          // Extract transform if present
          final transformMatch = RegExp(r'transform="([^"]+)"').firstMatch(polylineElement);
          final transform = transformMatch?.group(1);
          
          polylinePaths.add({
            'pathData': pathData,
            'transform': transform,
            'type': 'polyline',
          });
        }
      }
    }
    
    return polylinePaths;
  }

  /// Convert ellipse parameters to SVG path data
  static String ellipseToPath(double cx, double cy, double rx, double ry) {
    // Create ellipse using arc commands
    // Move to start point (rightmost point of ellipse)
    final double startX = cx + rx;
    
    // Use two arc commands to create a complete ellipse
    final pathData = 'M $startX $cy '
        'A $rx $ry 0 0 1 ${cx - rx} $cy '
        'A $rx $ry 0 0 1 $startX $cy Z';
    
    return pathData;
  }

  /// Convert rectangle parameters to SVG path data
  static String rectToPath(double x, double y, double width, double height, double rx, double ry) {
    if (rx <= 0 && ry <= 0) {
      // Simple rectangle without rounded corners
      return 'M $x $y L ${x + width} $y L ${x + width} ${y + height} L $x ${y + height} Z';
    } else {
      // Rectangle with rounded corners
      final double actualRx = rx > 0 ? rx : ry;
      final double actualRy = ry > 0 ? ry : rx;
      
      return 'M ${x + actualRx} $y '
          'L ${x + width - actualRx} $y '
          'A $actualRx $actualRy 0 0 1 ${x + width} ${y + actualRy} '
          'L ${x + width} ${y + height - actualRy} '
          'A $actualRx $actualRy 0 0 1 ${x + width - actualRx} ${y + height} '
          'L ${x + actualRx} ${y + height} '
          'A $actualRx $actualRy 0 0 1 $x ${y + height - actualRy} '
          'L $x ${y + actualRy} '
          'A $actualRx $actualRy 0 0 1 ${x + actualRx} $y Z';
    }
  }

  /// Convert polygon/polyline points string to SVG path data
  static String polygonPointsToPath(String pointsString, bool closePath) {
    // Parse points string (can be space or comma separated)
    final points = pointsString
        .replaceAll(RegExp(r'[,\s]+'), ' ')
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    
    if (points.length < 4) return ''; // Need at least 2 points (x,y pairs)
    
    final List<String> pathCommands = [];
    
    // Move to first point
    if (points.length >= 2) {
      final x = double.tryParse(points[0]) ?? 0;
      final y = double.tryParse(points[1]) ?? 0;
      pathCommands.add('M $x $y');
    }
    
    // Line to subsequent points
    for (int i = 2; i < points.length; i += 2) {
      if (i + 1 < points.length) {
        final x = double.tryParse(points[i]) ?? 0;
        final y = double.tryParse(points[i + 1]) ?? 0;
        pathCommands.add('L $x $y');
      }
    }
    
    // Close path if it's a polygon
    if (closePath && pathCommands.isNotEmpty) {
      pathCommands.add('Z');
    }
    
    return pathCommands.join(' ');
  }
}