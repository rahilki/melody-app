import 'package:flutter/material.dart';

class CommonHomeScaffold extends StatefulWidget {
  final String title;
  final List<Widget>
      pages; // صفحات التبويبات الداخلية (مثلاً: [الرئيسية, الفعاليات])
  final List<NavItemData> items; // عناصر الشريط السفلي
  final List<Widget> actions; // أزرار AppBar
  final FloatingActionButton? fab;

  const CommonHomeScaffold({
    super.key,
    required this.title,
    required this.pages,
    required this.items,
    this.actions = const [],
    this.fab,
  });

  @override
  State<CommonHomeScaffold> createState() => _CommonHomeScaffoldState();
}

class _CommonHomeScaffoldState extends State<CommonHomeScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // ضمان أن الإندكس دايمًا ضمن مدى الصفحات
    final safeIndex =
        (_index >= 0 && _index < widget.pages.length) ? _index : 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: widget.actions),
      body: widget.pages[safeIndex],
      floatingActionButton: widget.fab,
      bottomNavigationBar: BottomAppBar(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 4, horizontal: 8), // 👈 قللنا البادينغ
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.items.length, (i) {
                final it = widget.items[i];
                final selected =
                    (it.pageIndex != null && it.pageIndex == safeIndex);
                return _NavItem(
                  icon: it.icon,
                  label: it.label,
                  selected: selected,
                  onTap: () {
                    if (it.onTapRoute != null) {
                      Navigator.pushNamed(context, it.onTapRoute!);
                    } else if (it.pageIndex != null) {
                      // اضبط تبويب داخلي بشكل صريح
                      setState(() => _index = it.pageIndex!);
                    } else if (it.onTap != null) {
                      it.onTap!(); // مخصص
                    }
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? Theme.of(context).colorScheme.primary : Colors.black54;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11, // حجم النص
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// نوع عام لعناصر الشريط
class NavItemData {
  final IconData icon;
  final String label;
  final String? onTapRoute; // يفتح صفحة خارجية عبر Navigator
  final int? pageIndex; // يحدد أي تبويب داخلي من pages نعرضه
  final VoidCallback? onTap;

  const NavItemData({
    required this.icon,
    required this.label,
    this.onTapRoute,
    this.pageIndex,
    this.onTap,
  });
}
