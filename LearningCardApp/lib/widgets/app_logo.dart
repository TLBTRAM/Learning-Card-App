import '../core/localization/localized_material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool inverted;

  const AppLogo({super.key, this.size = 64, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    final background = inverted ? AppColors.ivory : AppColors.navy;
    final foreground = inverted ? AppColors.navy : AppColors.ivory;
    return Semantics(
      label: 'Learning Card App',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * .28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: size * .3,
              offset: Offset(0, size * .12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -.09,
              child: Container(
                width: size * .48,
                height: size * .36,
                decoration: BoxDecoration(
                  border: Border.all(color: foreground, width: size * .035),
                  borderRadius: BorderRadius.circular(size * .08),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(size * .06, size * .06),
              child: Container(
                width: size * .48,
                height: size * .36,
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(
                    color: AppColors.brass,
                    width: size * .035,
                  ),
                  borderRadius: BorderRadius.circular(size * .08),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: size * .18,
                  color: AppColors.brass,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
