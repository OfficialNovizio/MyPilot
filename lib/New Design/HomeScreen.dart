import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Bar ─────────────────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  _circleAction(
                    icon: Icons.search_rounded,
                    background: const Color(0xFF13161B),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _circleAction(
                        icon: Icons.notifications_none_rounded,
                        background: const Color(0xFF13161B),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                    backgroundColor: Color(0xFF2A2D33),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ─── Overview + Period selector ───────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE9EDF3),
                    ),
                  ),
                  const Spacer(),
                  _chipButton(
                    label: 'Monthly',
                    trailing: Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ─── Green Tiles (2 x 2) ─────────────────────────────────────────
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                crossAxisCount: 2,
                childAspectRatio: 1.18,
                children: const [
                  _StatTile(
                    value: '\$24,450',
                    label: 'Total Sales',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  _StatTile(
                    value: '4,300',
                    label: 'Total Orders',
                    icon: Icons.local_grocery_store_outlined,
                  ),
                  _StatTile(
                    value: '260',
                    label: 'Available Stock',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _StatTile(
                    value: '126',
                    label: 'Pending Orders',
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ─── Order Overview Title ────────────────────────────────────────
              const Text(
                'Order Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),

              // ─── Month chips ─────────────────────────────────────────────────
              Row(
                children: const [
                  _MonthChip('Jan'),
                  SizedBox(width: 8),
                  _MonthChip('Feb'),
                  SizedBox(width: 8),
                  _MonthChip('Mar', selected: true),
                  SizedBox(width: 8),
                  _MonthChip('Apr'),
                  SizedBox(width: 8),
                  _MonthChip('May'),
                ],
              ),

              const SizedBox(height: 12),

              // ─── Chart card ──────────────────────────────────────────────────
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1216),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Stack(
                  children: [
                    // Chart
                    Positioned.fill(
                      child: LineChart(_chartData(cs.primary)),
                    ),
                    // X-axis labels (dates)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _AxisLabel('2 Mar'),
                            _AxisLabel('3 Mar'),
                            _AxisLabel('4 Mar'),
                            _AxisLabel('5 Mar'),
                            _AxisLabel('6 Mar'),
                            _AxisLabel('7 Mar'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // bottom spacer so the nav bar doesn't overlap scroll
            ],
          ),
        ),
      ),

      // ─── Bottom Bar ─────────────────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1216),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _NavIcon(
                icon: Icons.grid_view_rounded,
                selected: true,
              ),
              _NavIcon(icon: Icons.home_outlined),
              _NavIcon(icon: Icons.insights_rounded),
              _NavIcon(icon: Icons.checklist_rtl_outlined),
              _NavIcon(icon: Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _NavIcon({required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: selected ? green.withOpacity(.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: green.withOpacity(.6)) : null,
      ),
      child: Icon(icon, color: selected ? green : const Color(0xFFE8EDF4)),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String t;
  const _AxisLabel(this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      t,
      style: const TextStyle(fontSize: 11, color: Color(0xFF8D96A4)),
    );
  }
}

class _MonthChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _MonthChip(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? green : const Color(0xFF13161B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF0A0B0C) : Colors.white,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final neon = const Color(0xFF31F27A); // close to screenshot neon
    return Container(
      decoration: BoxDecoration(
        color: neon,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(.18),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.85),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: neon),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // bottom-right mini button
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Icon(Icons.add_rounded, size: 18, color: neon),
            ),
          )
        ],
      ),
    );
  }
}

Widget _chipButton({required String label, IconData? trailing}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF14171C),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF242932)),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Color(0xFFE3E8F0),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 2),
          Icon(trailing, size: 18, color: const Color(0xFF8D96A4)),
        ]
      ],
    ),
  );
}

Widget _circleAction({required IconData icon, required Color background}) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: background,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: const Color(0xFFE8EDF4)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart config
// ─────────────────────────────────────────────────────────────────────────────
LineChartData _chartData(Color green) {
  final bgGrid = const Color(0xFF2B323D).withOpacity(.35);
  final points = <FlSpot>[
    const FlSpot(0, 35),
    const FlSpot(1, 58),
    const FlSpot(2, 48), // highlighted
    const FlSpot(3, 40),
    const FlSpot(4, 52),
    const FlSpot(5, 45),
    const FlSpot(6, 78),
  ];

  return LineChartData(
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 90,
    gridData: FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: 20,
      verticalInterval: 1,
      getDrawingHorizontalLine: (v) => FlLine(color: bgGrid, strokeWidth: 1, dashArray: [3, 4]),
      getDrawingVerticalLine: (v) => FlLine(color: bgGrid, strokeWidth: .6, dashArray: [3, 6]),
    ),
    borderData: FlBorderData(show: false),
    titlesData: const FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    lineTouchData: LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: const Color(0xFF111317),
        getTooltipItems: (items) {
          return items.map((e) {
            final v = e.y.toInt();
            return LineTooltipItem(
              '$v',
              const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Colors.white,
              ),
            );
          }).toList();
        },
      ),
      getTouchedSpotIndicator: (bar, indexes) {
        return indexes.map((index) {
          return TouchedSpotIndicatorData(
            FlLine(color: Colors.white24, strokeWidth: 1, dashArray: [4, 4]),
            FlDotData(
              show: true,
              getDotPainter: (spot, p1, p2, p3) => FlDotCirclePainter(
                color: Colors.white,
                radius: 4,
                strokeWidth: 3,
                strokeColor: green,
              ),
            ),
          );
        }).toList();
      },
    ),
    lineBarsData: [
      LineChartBarData(
        spots: points,
        isCurved: true,
        color: green,
        barWidth: 3,
        isStrokeCapRound: true,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              green.withOpacity(.35),
              green.withOpacity(.0),
            ],
          ),
        ),
        dotData: const FlDotData(show: false),
      ),
    ],
  );
}
