import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wheel_slider/wheel_slider.dart';

import '../../models/validation_data.dart';

class FLGraphWidget extends StatefulWidget {
  final String title;
  final List<FlSpot> param;
  final DateTime date;
  final bool showAsInteger;
  final double? thresholdMax;
  final double? thresholdMin;
  final bool isThresholdActive;
  final double maxY;
  final double minY;
  final double section;
  final String unit;
  final double maxScale;
  final double minScale;

  const FLGraphWidget({
    super.key,
    required this.title,
    required this.param,
    required this.showAsInteger,
    this.thresholdMax,
    this.thresholdMin,
    required this.isThresholdActive,
    required this.maxY,
    required this.minY,
    required this.section,
    required this.unit,
    required this.maxScale,
    required this.minScale,
    required this.date,
  });

  @override
  _FLGraphWidgetState createState() => _FLGraphWidgetState();
}

class _FLGraphWidgetState extends State<FLGraphWidget> {
  late double currentMaxY;
  late double currentMinY;
  late DateTime date;
  late double initialMinX;
  late double initialMaxX;
  late double xMult;
  late double interval;
  late double maxX;
  late double minX;
  late double maxCount;
  late double minCount;
  late double oldVal;
  late double wheelInterval;
  double initVal = 0;
  double scaleFactor = 1.0;
  bool showSpot = true;
  final int constant = 10000;

  @override
  void initState() {
    super.initState();
    _initializeGraph();
  }

  @override
  void didUpdateWidget(covariant FLGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      _initializeGraph();
    }
    if (oldWidget.param != widget.param) {
      setState(() {});
    }
  }

  void _initializeGraph() {
    currentMaxY = widget.maxY;
    currentMinY = widget.minY;

    DateTime todayStart = DateTime(widget.date.year, widget.date.month, widget.date.day);
    DateTime todayEnd = todayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    initialMinX = todayStart.millisecondsSinceEpoch.toDouble();
    initialMaxX = todayEnd.millisecondsSinceEpoch.toDouble();
    maxX = initialMaxX;
    minX = initialMinX;
    maxCount = maxX;
    minCount = minX;
    interval = (initialMaxX - initialMinX) / 6;
    oldVal = 0;
    wheelInterval = (initialMaxX - initialMinX) /
        ((((initialMaxX - initialMinX) / (maxCount - minCount)).toInt()) *
            constant);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> dataPoints = widget.param;

    bool shouldHighlightBackground = widget.isThresholdActive &&
        dataPoints.any((spot) =>
        (widget.thresholdMax != null && spot.y > widget.thresholdMax!) ||
            (widget.thresholdMin != null && spot.y < widget.thresholdMin!)) &&
        !validationNotifier.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.all(8.0),
      height: 410,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center-aligned text
                Center(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //     IconButton(
                //       icon: const Icon(
                //         Icons.restart_alt,
                //         color: Colors.black87,
                //         size: 18,
                //       ),
                //       onPressed: () {
                //         setState(() {
                //           currentMaxY = widget.maxY;
                //           currentMinY = widget.minY;
                //           DateTime todayStart =
                //           DateTime(date.year, date.month, date.day);
                //           DateTime todayEnd = todayStart
                //               .add(const Duration(hours: 23, minutes: 59));
                //           initialMinX =
                //               todayStart.millisecondsSinceEpoch.toDouble();
                //           initialMaxX =
                //               todayEnd.millisecondsSinceEpoch.toDouble();
                //           maxX = initialMaxX;
                //           minX = initialMinX;
                //           xMult = 0;
                //           interval = (initialMaxX - initialMinX) / 6;
                //           oldVal = 0;
                //         });
                //       },
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  'Data: ${widget.unit}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                if (widget.isThresholdActive && widget.thresholdMax != null)
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Max: ${widget.thresholdMax!.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                if (widget.isThresholdActive && widget.thresholdMin != null)
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Min: ${widget.thresholdMin!.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 18, 4),
              child: GestureDetector(
                // onScaleUpdate: _onScaleUpdate,
                // onVerticalDragUpdate: _onYDragUpdate,
                // onHorizontalDragUpdate: _onYDragUpdate,
                child: Stack(
                  children: [
                    LineChart(
                      LineChartData(
                        minY: currentMinY,
                        maxY: currentMaxY,
                        minX: minX,
                        maxX: maxX,
                        backgroundColor: shouldHighlightBackground ? Colors
                            .yellow : Colors.white,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                String formattedValue = widget.showAsInteger
                                    ? value.toInt().toString()
                                    : value.toStringAsFixed(1);
                                return Text(
                                  ' $formattedValue',
                                  style: const TextStyle(fontSize: 13),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              interval: interval,
                              minIncluded: true,
                              maxIncluded: true,
                              getTitlesWidget: (value, meta) {
                                if (value != meta.min) {
                                  if (value < minX + (interval / 1.5)) {
                                    return const SizedBox.shrink();
                                  }
                                }

                                if (value != meta.max) {
                                  if (value > maxX - (interval / 1.5)) {
                                    return const SizedBox.shrink();
                                  }
                                }

                                DateTime timePoint =
                                DateTime.fromMillisecondsSinceEpoch(
                                    value.toInt());
                                String hour =
                                    '${timePoint.hour}:${timePoint.minute
                                    .toString().padLeft(2, '0')}';
                                return Column(
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      hour,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: false, reservedSize: 32),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineTouchData: LineTouchData(
                          touchTooltipData: const LineTouchTooltipData(),
                          handleBuiltInTouches: showSpot,
                        ),
                        showingTooltipIndicators: [],
                        clipData: const FlClipData.all(),
                        gridData: const FlGridData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dataPoints,
                            isCurved: false,
                            barWidth: 3,
                            color: Colors.green,
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            if (widget.thresholdMax != null &&
                                widget.isThresholdActive)
                              HorizontalLine(
                                y: widget.thresholdMax!,
                                color: Colors.red,
                                strokeWidth: 2,
                                dashArray: [8, 4],
                              ),
                            if (widget.thresholdMin != null &&
                                widget.isThresholdActive)
                              HorizontalLine(
                                y: widget.thresholdMin!,
                                color: Colors.blueAccent,
                                strokeWidth: 2,
                                dashArray: [8, 4],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.zoom_out,
                    color: Colors.black87,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      xMult = (maxX - minX) * 0.5;
                      if (xMult % 1000 * 60 * 60 != 0) {
                        xMult = 1000 * 60 * 60;
                      }
                      double newMaxX = maxX + xMult;
                      double newMinX = minX - xMult;

                      if (newMaxX <= initialMaxX) {
                        maxX = newMaxX;
                        maxCount = maxX;
                      } else {
                        maxX = initialMaxX;
                        newMaxX = maxX;
                        maxCount = maxX;
                      }

                      if (newMinX >= initialMinX) {
                        minX = newMinX;
                        minCount = minX;
                      } else {
                        minX = initialMinX;
                        newMinX = minX;
                        minCount = minX;
                      }
                      if (newMaxX <= initialMaxX && newMinX >= initialMinX) {
                        interval = (newMaxX - newMinX) / 6;
                      }
                      wheelInterval = ((initialMaxX - initialMinX)) /
                          ((((initialMaxX - initialMinX) /
                              (maxCount - minCount))
                              .toInt()) *
                              constant);
                    });
                  },
                ),
                SizedBox(
                  width: 150,
                  height: 50,
                  child: WheelSlider(
                    totalCount: ((initialMaxX - initialMinX) /
                        (maxCount - minCount)).toInt(),
                    initValue: 0,
                    enableAnimation: false,
                    isInfinite: true,
                    listWidth: 15,
                    pointerHeight: 25,
                    interval: wheelInterval / 2,
                    onValueChanged: (val) {
                      setState(() {
                        const double fullCycleValue = 4320.0;
                        double delta = val - oldVal;

                        if (delta.abs() == fullCycleValue) {
                          delta = -delta;
                        }

                        double rangeAdjustment = (delta > 0 ? 1 : -1) *
                            (wheelInterval * constant / 2);

                        double newMaxX = maxX + rangeAdjustment;
                        double newMinX = minX + rangeAdjustment;

                        newMaxX = newMaxX.clamp(initialMinX, initialMaxX);
                        newMinX = newMinX.clamp(initialMinX, initialMaxX);

                        if (newMaxX == initialMaxX) {
                          double oldMaxX = maxX;
                          maxX = initialMaxX;
                          interval = interval + (newMaxX - oldMaxX);
                        } else if (newMinX == initialMinX) {
                          double oldMinX = minX;
                          minX = initialMinX;
                          interval = interval + (oldMinX - newMinX);
                        } else if (newMaxX > newMinX) {
                          maxX = newMaxX;
                          minX = newMinX;
                          interval = (maxX - minX) / 6;
                        }

                        oldVal = val;
                      });
                    },
                    hapticFeedbackType: HapticFeedbackType.vibrate,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.zoom_in,
                    color: Colors.black87,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(
                          () {
                        xMult = (maxX - minX) * 0.1;
                        if (xMult % 1000 * 60 * 60 != 0) {
                          xMult = 1000 * 60 * 60;
                        }
                        double newMaxX = maxX - xMult;
                        double newMinX = minX + xMult;

                        if ((newMaxX - newMinX) / 6 < 60 * 1000) {
                          return;
                        }

                        if (newMaxX <= initialMaxX) {
                          maxX = newMaxX;
                          maxCount = maxX;
                        } else {
                          maxX = initialMaxX;
                          newMaxX = maxX;
                          maxCount = maxX;
                        }
                        if (newMinX >= initialMinX) {
                          minX = newMinX;
                          minCount = minX;
                        } else {
                          minX = initialMinX;
                          newMinX = minX;
                          minCount = minX;
                        }
                        if (newMaxX <= initialMaxX && newMinX >= initialMinX) {
                          interval = (newMaxX - newMinX) / 6;
                        }
                        wheelInterval = (initialMaxX - initialMinX) /
                            ((((initialMaxX - initialMinX) /
                                (maxCount - minCount))
                                .toInt()) *
                                constant);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
