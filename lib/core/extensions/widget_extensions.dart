import 'package:flutter/material.dart';

extension WidgetExtensions on Widget {
  /// Wraps the widget with Padding.
  /// Example: Text('Hello').paddingAll(8.0)
  Widget paddingAll(double value) => Padding(
        padding: EdgeInsets.all(value),
        child: this,
      );

  /// Wraps the widget with symmetrical Padding.
  Widget paddingSymmetric({double horizontal = 0.0, double vertical = 0.0}) => Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        child: this,
      );

  /// Wraps the widget with specific Padding.
  Widget paddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) =>
      Padding(
        padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
        child: this,
      );

  /// Centers the widget.
  /// Example: Text('Hello').center()
  Widget center() => Center(child: this);

  /// Wraps the widget in an Expanded.
  /// Example: Container().expanded()
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);

  /// Wraps the widget in a Flexible.
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) => Flexible(
        flex: flex,
        fit: fit,
        child: this,
      );
      
  /// Wraps the widget in a SliverToBoxAdapter.
  /// Useful for placing normal widgets inside a CustomScrollView.
  Widget sliver() => SliverToBoxAdapter(child: this);

  /// Hides the widget if [isVisible] is false.
  /// Example: Text('Hello').visible(false) // returns SizedBox.shrink()
  Widget visible(bool isVisible) => isVisible ? this : const SizedBox.shrink();
}
