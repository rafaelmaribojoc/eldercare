import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  Breakpoints._();

  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop }

/// Screen size information
class ScreenInfo {
  final double width;
  final double height;
  final DeviceType deviceType;
  final Orientation orientation;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final double horizontalPadding;
  final double verticalPadding;
  final int gridColumns;

  const ScreenInfo({
    required this.width,
    required this.height,
    required this.deviceType,
    required this.orientation,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.gridColumns,
  });

  factory ScreenInfo.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final width = size.width;

    DeviceType deviceType;
    bool isMobile = false;
    bool isTablet = false;
    bool isDesktop = false;
    double horizontalPadding;
    double verticalPadding;
    int gridColumns;

    if (width < Breakpoints.tablet) {
      deviceType = DeviceType.mobile;
      isMobile = true;
      horizontalPadding = 16;
      verticalPadding = 16;
      gridColumns = 1;
    } else if (width < Breakpoints.desktop) {
      deviceType = DeviceType.tablet;
      isTablet = true;
      horizontalPadding = 24;
      verticalPadding = 20;
      gridColumns = 2;
    } else {
      deviceType = DeviceType.desktop;
      isDesktop = true;
      horizontalPadding = 32;
      verticalPadding = 24;
      gridColumns = width < Breakpoints.largeDesktop ? 3 : 4;
    }

    return ScreenInfo(
      width: width,
      height: size.height,
      deviceType: deviceType,
      orientation: orientation,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      gridColumns: gridColumns,
    );
  }

  /// Get responsive value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Check if screen width is at least the given breakpoint
  bool isAtLeast(double breakpoint) => width >= breakpoint;

  /// Check if screen width is less than the given breakpoint
  bool isLessThan(double breakpoint) => width < breakpoint;
}

/// Extension for easy access to screen info
extension ResponsiveContext on BuildContext {
  ScreenInfo get screen => ScreenInfo.of(this);

  bool get isMobile => screen.isMobile;
  bool get isTablet => screen.isTablet;
  bool get isDesktop => screen.isDesktop;

  double get screenWidth => screen.width;
  double get screenHeight => screen.height;

  /// Get responsive value
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      screen.value(mobile: mobile, tablet: tablet, desktop: desktop);
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenInfo screen) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, ScreenInfo.of(context));
  }
}

/// Widget that shows different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screen) {
        switch (screen.deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    final padding = screen.value(
      mobile: mobilePadding ?? EdgeInsets.all(screen.horizontalPadding),
      tablet: tabletPadding,
      desktop: desktopPadding,
    );
    return Padding(padding: padding, child: child);
  }
}

/// Responsive container with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final CrossAxisAlignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    final effectiveMaxWidth = maxWidth ??
        screen.value<double>(
          mobile: double.infinity,
          tablet: 720.0,
          desktop: 1200.0,
        );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: screen.horizontalPadding,
                vertical: screen.verticalPadding,
              ),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive card with consistent styling
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);

    return Card(
      elevation: elevation ?? 0,
      color: color ?? Theme.of(context).cardColor,
      margin: margin ?? EdgeInsets.zero,
      child: Padding(
        padding: padding ??
            EdgeInsets.all(
              screen.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
            ),
        child: child,
      ),
    );
  }
}

/// Responsive grid that adapts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    final columns = screen.value(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    if (childAspectRatio != null) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: childAspectRatio!,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        final itemWidth = (screen.width -
                (screen.horizontalPadding * 2) -
                (spacing * (columns - 1))) /
            columns;
        return SizedBox(
          width: itemWidth.clamp(0, screen.width),
          child: child,
        );
      }).toList(),
    );
  }
}

/// Responsive row that becomes column on mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool forceColumn;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
    this.forceColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    final useColumn = forceColumn || screen.isMobile;

    if (useColumn) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, spacing, isVertical: true),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _addSpacing(children, spacing, isVertical: false),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets, double spacing,
      {required bool isVertical}) {
    if (widgets.isEmpty) return widgets;

    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      if (isVertical) {
        result.add(widgets[i]);
      } else {
        result.add(Expanded(child: widgets[i]));
      }
      if (i < widgets.length - 1) {
        result.add(SizedBox(
          width: isVertical ? null : spacing,
          height: isVertical ? spacing : null,
        ));
      }
    }
    return result;
  }
}

/// Responsive visibility - shows/hides based on screen size
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  });

  /// Hide on mobile only
  const ResponsiveVisibility.hiddenOnMobile({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = false,
        visibleOnTablet = true,
        visibleOnDesktop = true;

  /// Show on mobile only
  const ResponsiveVisibility.mobileOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = true,
        visibleOnTablet = false,
        visibleOnDesktop = false;

  /// Show on desktop only
  const ResponsiveVisibility.desktopOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = false,
        visibleOnTablet = false,
        visibleOnDesktop = true;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    final isVisible = screen.value(
      mobile: visibleOnMobile,
      tablet: visibleOnTablet,
      desktop: visibleOnDesktop,
    );

    if (isVisible) {
      return child;
    }
    return replacement ?? const SizedBox.shrink();
  }
}

/// Responsive text that scales based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    final fontSize = screen.value(
      mobile: mobileSize ?? 14,
      tablet: tabletSize ?? (mobileSize ?? 14) * 1.1,
      desktop: desktopSize ?? (mobileSize ?? 14) * 1.2,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive sized box
class ResponsiveSizedBox extends StatelessWidget {
  final double? mobileWidth;
  final double? mobileHeight;
  final double? tabletWidth;
  final double? tabletHeight;
  final double? desktopWidth;
  final double? desktopHeight;
  final Widget? child;

  const ResponsiveSizedBox({
    super.key,
    this.mobileWidth,
    this.mobileHeight,
    this.tabletWidth,
    this.tabletHeight,
    this.desktopWidth,
    this.desktopHeight,
    this.child,
  });

  /// Responsive height only
  const ResponsiveSizedBox.height({
    super.key,
    required double mobile,
    double? tablet,
    double? desktop,
    this.child,
  })  : mobileHeight = mobile,
        tabletHeight = tablet,
        desktopHeight = desktop,
        mobileWidth = null,
        tabletWidth = null,
        desktopWidth = null;

  /// Responsive width only
  const ResponsiveSizedBox.width({
    super.key,
    required double mobile,
    double? tablet,
    double? desktop,
    this.child,
  })  : mobileWidth = mobile,
        tabletWidth = tablet,
        desktopWidth = desktop,
        mobileHeight = null,
        tabletHeight = null,
        desktopHeight = null;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);

    return SizedBox(
      width: screen.value(
        mobile: mobileWidth,
        tablet: tabletWidth,
        desktop: desktopWidth,
      ),
      height: screen.value(
        mobile: mobileHeight,
        tablet: tabletHeight,
        desktop: desktopHeight,
      ),
      child: child,
    );
  }
}
