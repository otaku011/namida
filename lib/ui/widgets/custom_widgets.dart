import 'dart:ui';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:checkmark/checkmark.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide ReorderableDragStartListener;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_scrollbar_modified/flutter_scrollbar_modified.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:history_manager/history_manager.dart';
import 'package:known_extents_list_view_builder/known_extents_reorderable_list_view_builder.dart';
import 'package:known_extents_list_view_builder/known_extents_sliver_reorderable_list.dart';
import 'package:like_button/like_button.dart';
import 'package:selectable_autolink_text/selectable_autolink_text.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wheel_slider/wheel_slider.dart';

import 'package:namida/class/track.dart';
import 'package:namida/controller/current_color.dart';
import 'package:namida/controller/miniplayer_controller.dart';
import 'package:namida/controller/navigator_controller.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/controller/playlist_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/controller/waveform_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/dimensions.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/functions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/namida_converter_ext.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/ui/dialogs/setting_dialog_with_text_field.dart';
import 'package:namida/ui/pages/about_page.dart';
import 'package:namida/ui/pages/settings_page.dart';
import 'package:namida/ui/widgets/library/track_tile.dart';
import 'package:namida/ui/widgets/settings/extra_settings.dart';

class CustomReorderableDelayedDragStartListener extends ReorderableDragStartListener {
  final Duration delay;

  const CustomReorderableDelayedDragStartListener({
    this.delay = const Duration(milliseconds: 20),
    Key? key,
    required Widget child,
    required int index,
    PointerDownEventListener? onDragStart,
    PointerUpEventListener? onDragEnd,
  }) : super(
          key: key,
          child: child,
          index: index,
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
        );

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(delay: delay, debugOwner: this);
  }
}

class NamidaReordererableListener extends StatelessWidget {
  /// Will disable miniplayer listener when dragging.
  final bool isInQueue;
  final int index;
  final int durationMs;
  final Widget child;

  const NamidaReordererableListener({
    super.key,
    required this.isInQueue,
    required this.index,
    this.durationMs = 50,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomReorderableDelayedDragStartListener(
      onDragStart: (event) {
        if (isInQueue) {
          MiniPlayerController.inst.invokeStartReordering();
        }
      },
      onDragEnd: (event) {
        MiniPlayerController.inst.invokeDoneReordering();
      },
      index: index,
      delay: const Duration(milliseconds: 80),
      child: child,
    );
  }
}

class CustomSwitch extends StatelessWidget {
  final bool active;
  final double height;
  final double width;
  final Color? circleColor;
  final Color? bgColor;
  final Color? shadowColor;
  final int durationInMillisecond;
  final Color? passedColor;

  const CustomSwitch({
    super.key,
    required this.active,
    this.height = 21.0,
    this.width = 40.0,
    this.circleColor,
    this.durationInMillisecond = 400,
    this.bgColor,
    this.shadowColor,
    this.passedColor,
  });

  @override
  Widget build(BuildContext context) {
    final finalColor = passedColor ?? CurrentColor.inst.color;
    return AnimatedContainer(
      width: width,
      height: height,
      duration: Duration(milliseconds: durationInMillisecond),
      padding: EdgeInsets.symmetric(horizontal: width / 10),
      decoration: BoxDecoration(
        color: (active
            ? bgColor ?? Color.alphaBlend(finalColor.withAlpha(180), context.theme.colorScheme.background).withAlpha(140)
            // : context.theme.scaffoldBackgroundColor.withAlpha(34)
            : Color.alphaBlend(context.theme.scaffoldBackgroundColor.withAlpha(60), context.theme.disabledColor)),
        borderRadius: BorderRadius.circular(30.0.multipliedRadius),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: active ? 8 : 2,
            spreadRadius: 0,
            color: (shadowColor ?? Color.alphaBlend(finalColor.withAlpha(180), context.theme.colorScheme.background)).withOpacity(active ? 0.8 : 0.3),
          ),
        ],
      ),
      child: AnimatedAlign(
        duration: Duration(milliseconds: durationInMillisecond),
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: width / 3,
          height: height / 1.5,
          decoration: BoxDecoration(
            color: circleColor ?? Colors.white.withAlpha(222),
            borderRadius: BorderRadius.circular(30.0.multipliedRadius),
            // boxShadow: [
            //   BoxShadow(color: Colors.black.withAlpha(100), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2)),
            // ],
          ),
        ),
      ),
    );
  }
}

class CustomSwitchListTile extends StatelessWidget {
  final bool value;
  final void Function(bool isTrue) onChanged;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? icon;
  final Color? passedColor;
  final int? rotateIcon;
  final bool enabled;
  final bool largeTitle;
  final int maxSubtitleLines;
  final VisualDensity? visualDensity;
  final Color? bgColor;

  const CustomSwitchListTile({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.passedColor,
    this.rotateIcon,
    this.enabled = true,
    this.largeTitle = false,
    this.maxSubtitleLines = 8,
    this.visualDensity,
    this.bgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      bgColor: bgColor,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      icon: icon,
      leading: leading,
      largeTitle: largeTitle,
      maxSubtitleLines: maxSubtitleLines,
      passedColor: passedColor,
      rotateIcon: rotateIcon,
      onTap: () => onChanged(value),
      visualDensity: visualDensity,
      trailing: IgnorePointer(
        child: FittedBox(
          child: Row(
            children: [
              const SizedBox(
                width: 12.0,
              ),
              CustomSwitch(active: value, passedColor: passedColor),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  final void Function()? onTap;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? trailingText;
  final IconData? icon;
  final Widget? leading;
  final Color? passedColor;
  final int? rotateIcon;
  final bool enabled;
  final bool largeTitle;
  final int maxSubtitleLines;
  final Widget? trailingRaw;
  final VisualDensity? visualDensity;
  final TextStyle? titleStyle;
  final double borderR;
  final Color? bgColor;

  const CustomListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
    this.icon,
    this.passedColor,
    this.rotateIcon,
    this.trailingText,
    this.enabled = true,
    this.largeTitle = false,
    this.maxSubtitleLines = 8,
    this.trailingRaw,
    this.visualDensity,
    this.titleStyle,
    this.borderR = 20.0,
    this.bgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = context.defaultIconColor(passedColor);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: enabled ? 1.0 : 0.5,
      child: ListTile(
        enabled: enabled,
        tileColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderR.multipliedRadius),
        ),
        visualDensity: visualDensity,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        minVerticalPadding: 8.0,
        leading: icon != null
            ? SizedBox(
                height: double.infinity,
                child: rotateIcon != null
                    ? RotatedBox(
                        quarterTurns: rotateIcon!,
                        child: Icon(
                          icon,
                          color: iconColor,
                        ),
                      )
                    : Icon(
                        icon,
                        color: iconColor,
                      ),
              )
            : leading,
        title: Text(
          title,
          style: titleStyle ?? (largeTitle ? context.theme.textTheme.displayLarge : context.theme.textTheme.displayMedium),
          maxLines: subtitle != null ? 4 : 5,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: context.theme.textTheme.displaySmall,
                maxLines: maxSubtitleLines,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: trailingRaw ??
            (trailingText != null
                ? Text(
                    trailingText!,
                    style: context.textTheme.displayMedium?.copyWith(color: context.theme.colorScheme.onBackground.withAlpha(200)),
                  )
                : FittedBox(child: trailing)),
      ),
    );
  }
}

class NamidaBgBlur extends StatelessWidget {
  final double blur;
  final bool enabled;
  final BlendMode blendMode;
  final Widget child;
  const NamidaBgBlur({
    super.key,
    required this.blur,
    this.enabled = true,
    this.blendMode = BlendMode.srcOver,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      blendMode: blendMode,
      child: child,
    );
  }
}

class CustomBlurryDialog extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final Widget? titleWidget;
  final Widget? titleWidgetInPadding;
  final List<Widget>? trailingWidgets;
  final Widget? child;
  final List<Widget>? actions;
  final Widget? leftAction;
  final bool normalTitleStyle;
  final String? bodyText;
  final bool isWarning;
  final bool scrollable;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry contentPadding;
  final ThemeData? theme;

  const CustomBlurryDialog({
    super.key,
    this.child,
    this.trailingWidgets,
    this.title,
    this.titleWidget,
    this.titleWidgetInPadding,
    this.actions,
    this.icon,
    this.normalTitleStyle = false,
    this.bodyText,
    this.isWarning = false,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 50.0, vertical: 32.0),
    this.scrollable = true,
    this.contentPadding = const EdgeInsets.all(14.0),
    this.leftAction,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final ctxth = theme ?? context.theme;
    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: ctxth.dialogBackgroundColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: insetPadding,
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Title.
                  if (titleWidget != null) titleWidget!,
                  if (titleWidgetInPadding != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 28.0, left: 28.0, right: 24.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: titleWidgetInPadding,
                      ),
                    ),
                  if (titleWidget == null && titleWidgetInPadding == null)
                    normalTitleStyle
                        ? Padding(
                            padding: const EdgeInsets.only(top: 28.0, left: 28.0, right: 24.0),
                            child: Row(
                              children: [
                                if (icon != null || isWarning) ...[
                                  Icon(
                                    isWarning ? Broken.warning_2 : icon,
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    isWarning ? lang.WARNING : title ?? '',
                                    style: ctxth.textTheme.displayLarge,
                                  ),
                                ),
                                if (trailingWidgets != null) ...trailingWidgets!
                              ],
                            ),
                          )
                        : Container(
                            color: ctxth.cardTheme.color,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (icon != null) ...[
                                  Icon(
                                    icon,
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    title ?? '',
                                    style: ctxth.textTheme.displayMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                  /// Body.
                  Padding(
                    padding: contentPadding,
                    child: SizedBox(
                      width: context.width,
                      child: bodyText != null
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                bodyText!,
                                style: ctxth.textTheme.displayMedium,
                              ),
                            )
                          : child,
                    ),
                  ),

                  /// Actions.
                  if (actions != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: FittedBox(
                        child: SizedBox(
                          width: context.width - insetPadding.left - insetPadding.right,
                          child: Wrap(
                            alignment: leftAction == null ? WrapAlignment.end : WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (leftAction != null) ...[
                                const SizedBox(width: 6.0),
                                leftAction!,
                                const SizedBox(width: 6.0),
                              ],
                              ...actions!.addSeparators(separator: const SizedBox(width: 6.0))
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NamidaButton extends StatelessWidget {
  final IconData? icon;
  final double? iconSize;
  final String? text;
  final Widget? textWidget;

  /// will be used if the icon only is sent.
  final String tooltip;
  final void Function() onPressed;
  final bool minimumSize;
  final bool? enabled;

  const NamidaButton({
    super.key,
    this.icon,
    this.iconSize,
    this.text,
    this.textWidget,
    this.tooltip = '',
    required this.onPressed,
    this.minimumSize = false,
    this.enabled,
  });

  Widget _getWidget(Widget child) {
    return enabled == null
        ? child
        : IgnorePointer(
            ignoring: !enabled!,
            child: AnimatedOpacity(
              opacity: enabled! ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 250),
              child: child,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final iconChild = Icon(icon, size: iconSize);
    final textChild = Text(
      text ?? '',
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
    final onTap = onPressed;
    final style = minimumSize
        ? ElevatedButton.styleFrom(
            minimumSize: const Size(32.0, 38.0),
            padding: EdgeInsets.zero,
          )
        : null;

    if (textWidget != null) {
      return _getWidget(
        ElevatedButton(
          style: style,
          onPressed: onTap,
          child: textWidget,
        ),
      );
    }
    // -- icon X && text ✓
    if (icon == null && text != null) {
      return _getWidget(
        ElevatedButton(
          style: style,
          onPressed: onTap,
          child: textChild,
        ),
      );
    }
    // -- icon ✓ && text X
    if (icon != null && text == null) {
      return Tooltip(
        message: tooltip,
        child: _getWidget(
          ElevatedButton(
            style: style,
            onPressed: onTap,
            child: iconChild,
          ),
        ),
      );
    }
    // -- icon ✓ && text ✓
    if (icon != null && text != null) {
      return _getWidget(
        ElevatedButton.icon(
          style: style,
          onPressed: onTap,
          icon: iconChild,
          label: textChild,
        ),
      );
    }
    throw Exception('icon or text must be provided');
  }
}

class StatsContainer extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final String? title;
  final String? value;
  final String? total;

  const StatsContainer({super.key, this.child, this.icon, this.title, this.value, this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color?.withAlpha(200),
        borderRadius: BorderRadius.circular(22.0.multipliedRadius),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
      child: child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(
                width: 8.0,
              ),
              Text(title ?? ''),
              const SizedBox(
                width: 8.0,
              ),
              Text(value ?? ''),
              if (total != null) Text(" ${lang.OF} $total")
            ],
          ),
    );
  }
}

class SmallListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool active;
  final bool displayAnimatedCheck;
  final bool compact;
  final Color? color;
  final void Function()? onTap;
  final EdgeInsetsGeometry? padding;
  final double? titleGap;
  final double borderRadius;
  final Widget? leading;
  const SmallListTile({
    super.key,
    required this.title,
    this.onTap,
    this.trailing,
    this.active = false,
    this.icon,
    this.trailingIcon,
    this.displayAnimatedCheck = false,
    this.compact = true,
    this.subtitle,
    this.color,
    this.padding = const EdgeInsets.only(left: 16.0, right: 12.0),
    this.titleGap,
    this.borderRadius = 0.0,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: padding,
      horizontalTitleGap: titleGap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius.multipliedRadius),
      ),
      leading: leading ??
          SizedBox(
            height: double.infinity,
            child: icon != null
                ? Icon(icon, color: color != null ? context.defaultIconColor(color, context.textTheme.displayMedium?.color) : null)
                : active
                    ? const Icon(Broken.arrow_circle_right)
                    : const Icon(
                        Broken.arrow_right_3,
                        size: 18.0,
                      ),
          ),
      visualDensity: compact ? const VisualDensity(horizontal: -2.0, vertical: -2.0) : const VisualDensity(horizontal: -1.0, vertical: -1.0),
      title: Text(
        title,
        style: context.textTheme.displayMedium?.copyWith(
          color: color != null
              ? Color.alphaBlend(
                  color!.withAlpha(40),
                  context.textTheme.displayMedium!.color!,
                )
              : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: context.textTheme.displaySmall?.copyWith(
                color: color != null
                    ? Color.alphaBlend(
                        color!.withAlpha(40),
                        context.textTheme.displayMedium!.color!,
                      )
                    : null,
              ),
            )
          : null,
      trailing: displayAnimatedCheck
          ? SizedBox(
              height: 18.0,
              width: 18.0,
              child: CheckMark(
                // curve: Curves.easeInOutExpo,
                strokeWidth: 2,
                activeColor: color ?? context.theme.listTileTheme.iconColor!,
                inactiveColor: color ?? context.theme.listTileTheme.iconColor!,
                duration: const Duration(milliseconds: 400),
                active: settings.artistSortReversed.value,
              ),
            )
          : trailingIcon != null
              ? Icon(trailingIcon, color: color)
              : trailing,
      onTap: onTap,
    );
  }
}

class ListTileWithCheckMark extends StatelessWidget {
  final bool active;
  final void Function()? onTap;
  final String? title;
  final String subtitle;
  final IconData? icon;
  final Color? tileColor;
  final Widget? titleWidget;
  final Widget? leading;
  final double? iconSize;
  final bool dense;

  const ListTileWithCheckMark({
    super.key,
    required this.active,
    this.onTap,
    this.title,
    this.subtitle = '',
    this.icon,
    this.tileColor,
    this.titleWidget,
    this.leading,
    this.iconSize,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final tileAlpha = context.isDarkMode ? 5 : 20;
    return Material(
      borderRadius: BorderRadius.circular(16.0.multipliedRadius),
      color: tileColor ?? Color.alphaBlend(context.theme.colorScheme.onBackground.withAlpha(tileAlpha), context.theme.cardTheme.color!),
      child: ListTile(
        horizontalTitleGap: 10.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0.multipliedRadius)),
        leading: leading ??
            Icon(
              icon ?? Broken.arrange_circle,
              size: iconSize,
            ),
        title: titleWidget ??
            Text(
              title ?? lang.REVERSE_ORDER,
              style: context.textTheme.displayMedium,
            ),
        subtitle: subtitle != ''
            ? Text(
                subtitle,
                style: context.textTheme.displaySmall,
              )
            : null,
        trailing: NamidaCheckMark(
          size: 18.0,
          active: active,
        ),
        // visualDensity: VisualDensity.compact,
        visualDensity: const VisualDensity(horizontal: -2.8, vertical: -2.8),
        onTap: onTap,
        dense: dense,
      ),
    );
  }
}

class NamidaCheckMark extends StatelessWidget {
  final double size;
  final bool active;
  final Color? activeColor;
  final Color? inactiveColor;

  const NamidaCheckMark({
    super.key,
    required this.size,
    required this.active,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CheckMark(
        strokeWidth: 2,
        activeColor: activeColor ?? context.theme.listTileTheme.iconColor!,
        inactiveColor: inactiveColor ?? context.theme.listTileTheme.iconColor!,
        duration: const Duration(milliseconds: 400),
        active: active,
      ),
    );
  }
}

class NamidaExpansionTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final IconData? trailingIcon;
  final double trailingIconSize;
  final String titleText;
  final Color? textColor;
  final Color? textColorScheme;
  final List<Widget> children;
  final EdgeInsetsGeometry? childrenPadding;
  final bool initiallyExpanded;
  final Widget? trailing;
  final ValueChanged? onExpansionChanged;
  final bool normalRightPadding;
  final Color? bgColor;

  const NamidaExpansionTile({
    super.key,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailingIcon = Broken.arrow_down_2,
    this.trailingIconSize = 20.0,
    required this.titleText,
    this.textColor,
    this.textColorScheme,
    this.children = const <Widget>[],
    this.childrenPadding = EdgeInsets.zero,
    this.initiallyExpanded = false,
    this.trailing,
    this.onExpansionChanged,
    this.normalRightPadding = false,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      // horizontalTitleGap: 12.0,
      dense: true,
      child: ExpansionTile(
        collapsedBackgroundColor: bgColor,
        backgroundColor: bgColor,
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        expandedAlignment: Alignment.centerLeft,
        tilePadding: EdgeInsets.only(left: 16.0, right: normalRightPadding ? 16.0 : 12.0),
        leading: leading ??
            Icon(
              icon,
              color: iconColor,
            ),
        trailing: trailing ??
            (trailingIcon == null
                ? null
                : IgnorePointer(
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(trailingIcon, size: trailingIconSize),
                    ),
                  )),
        title: Text(
          titleText,
          style: context.textTheme.displayMedium?.copyWith(
            color: textColor ??
                (textColorScheme == null
                    ? null
                    : Color.alphaBlend(
                        textColorScheme!.withAlpha(40),
                        context.textTheme.displayMedium!.color!,
                      )),
          ),
        ),
        childrenPadding: childrenPadding,
        children: children,
      ),
    );
  }
}

class CreatePlaylistButton extends StatelessWidget {
  const CreatePlaylistButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NamidaButton(
      icon: Broken.add,
      text: lang.CREATE,
      onPressed: () => showSettingDialogWithTextField(
        title: lang.CREATE_NEW_PLAYLIST,
        addNewPlaylist: true,
      ),
    );
  }
}

class GeneratePlaylistButton extends StatelessWidget {
  const GeneratePlaylistButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NamidaButton(
      icon: Broken.shuffle,
      text: lang.RANDOM,
      onPressed: () {
        final numbers = PlaylistController.inst.generateRandomPlaylist();
        if (numbers == 0) {
          snackyy(title: lang.ERROR, message: lang.NO_ENOUGH_TRACKS);
        }
      },
    );
  }
}

class MoreIcon extends StatelessWidget {
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final bool rotated;
  final double padding;
  final Color? iconColor;
  final double iconSize;
  const MoreIcon({super.key, this.onPressed, this.rotated = true, this.padding = 1.0, this.iconColor, this.iconSize = 18.0, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: rotated ? 1 : 0,
      child: NamidaInkWell(
        borderRadius: 4.0,
        onTap: onPressed,
        onLongPress: onLongPress,
        padding: EdgeInsets.all(padding),
        child: Icon(
          Broken.more,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

class StackedIcon extends StatelessWidget {
  final IconData baseIcon;
  final IconData? secondaryIcon;
  final String? secondaryText;
  final Color? baseIconColor;
  final Color? secondaryIconColor;
  final double? iconSize;
  final double? secondaryIconSize;
  final double blurRadius;
  final Widget? smallChild;
  final bool disableColor;
  final bool delightenColors;

  const StackedIcon({
    super.key,
    required this.baseIcon,
    this.secondaryIcon,
    this.baseIconColor,
    this.secondaryIconColor,
    this.secondaryText,
    this.iconSize,
    this.secondaryIconSize = 14.0,
    this.blurRadius = 3.0,
    this.smallChild,
    this.disableColor = false,
    this.delightenColors = false,
  });
  Color? _getColory(BuildContext context, Color? c) {
    return disableColor
        ? null
        : delightenColors && c != null
            ? context.defaultIconColor(c)
            : c ?? context.defaultIconColor();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(
          baseIcon,
          color: _getColory(context, baseIconColor),
          size: iconSize,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: context.theme.scaffoldBackgroundColor, spreadRadius: 0, blurRadius: blurRadius),
              ],
            ),
            child: smallChild ??
                (secondaryText != null
                    ? Text(secondaryText!, style: context.textTheme.displaySmall?.copyWith(color: context.defaultIconColor()))
                    : Icon(
                        secondaryIcon,
                        size: secondaryIconSize,
                        color: _getColory(context, secondaryIconColor),
                      )),
          ),
        )
      ],
    );
  }
}

class SmallIconButton extends StatelessWidget {
  final IconData icon;
  final void Function()? onTap;

  const SmallIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NamidaIconButton(
      icon: icon,
      onPressed: onTap,
      iconSize: 20.0,
      horizontalPadding: 0,
    );
  }
}

class BlurryContainer extends StatelessWidget {
  final Container? container;
  final BorderRadius borderRadius;
  final Widget? child;
  final bool disableBlur;
  const BlurryContainer({super.key, this.container, this.child, this.borderRadius = BorderRadius.zero, this.disableBlur = false});

  @override
  Widget build(BuildContext context) {
    final Widget? finalChild = container ?? child;
    return ClipRRect(
      borderRadius: borderRadius,
      child: disableBlur || finalChild == null
          ? finalChild
          : NamidaBgBlur(
              blur: 5.0,
              child: finalChild,
            ),
    );
  }
}

class CancelButton extends StatelessWidget {
  final void Function()? onPressed;
  const CancelButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? () => NamidaNavigator.inst.closeDialog(),
      child: Text(lang.CANCEL),
    );
  }
}

class CollapsedSettingTileWidget extends StatelessWidget {
  final Color? bgColor;
  const CollapsedSettingTileWidget({super.key, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomSwitchListTile(
        bgColor: bgColor,
        icon: Broken.archive,
        title: lang.USE_COLLAPSED_SETTING_TILES,
        value: settings.useSettingCollapsedTiles.value,
        onChanged: (isTrue) async {
          settings.save(useSettingCollapsedTiles: !isTrue);
          await NamidaNavigator.inst.popPage();
          NamidaNavigator.inst.navigateTo(const SettingsPage());
        },
      ),
    );
  }
}

class AboutPageTileWidget extends StatelessWidget {
  const AboutPageTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        settings.selectedLanguage.value;
        return CustomCollapsedListTile(
          title: lang.ABOUT,
          subtitle: null,
          icon: Broken.info_circle,
          rawPage: true,
          page: const AboutPage(),
        );
      },
    );
  }
}

class NamidaBlurryContainer extends StatelessWidget {
  final Widget child;
  final void Function()? onTap;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;

  const NamidaBlurryContainer({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
  });

  @override
  Widget build(BuildContext context) {
    final blurredAlphaLight = context.isDarkMode ? 60 : 140;
    final con = BlurryContainer(
      disableBlur: !settings.enableBlurEffect.value,
      borderRadius: borderRadius ??
          BorderRadius.only(
            bottomLeft: Radius.circular(8.0.multipliedRadius),
          ),
      container: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: context.theme.cardColor.withAlpha(settings.enableBlurEffect.value ? blurredAlphaLight : 220),
            borderRadius: borderRadius ??
                BorderRadius.only(
                  bottomLeft: Radius.circular(8.0.multipliedRadius),
                ),
          ),
          child: child),
    );
    return onTap != null
        ? InkWell(
            onTap: onTap,
            child: con,
          )
        : con;
  }
}

class ContainerWithBorder extends StatelessWidget {
  final Widget? child;
  final Color? borderColor;
  const ContainerWithBorder({super.key, this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: borderColor ?? context.theme.cardColor.withAlpha(160),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withAlpha(60),
            blurRadius: 4,
            offset: const Offset(0, 2.0),
          )
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class NamidaWheelSlider<T> extends StatelessWidget {
  final double width;
  final double perspective;
  final int totalCount;
  final int initValue;
  final double itemSize;
  final double squeeze;
  final bool isInfinite;
  final String? text;
  final String? topText;
  final double? textPadding;
  final double? topTextPadding;
  final void Function(T val) onValueChanged;

  const NamidaWheelSlider({
    super.key,
    this.width = 80,
    this.perspective = 0.01,
    required this.totalCount,
    required this.initValue,
    this.itemSize = 5.0,
    this.squeeze = 1.0,
    this.isInfinite = false,
    required this.onValueChanged,
    this.text,
    this.topText,
    this.textPadding = 2.0,
    this.topTextPadding = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          if (topText != null) ...[
            Text(
              topText!,
              style: context.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: topTextPadding),
          ],
          WheelSlider(
            perspective: perspective,
            totalCount: totalCount,
            initValue: initValue,
            itemSize: itemSize,
            squeeze: squeeze,
            isInfinite: isInfinite,
            lineColor: Get.iconColor,
            pointerColor: context.theme.listTileTheme.textColor!,
            pointerHeight: 38.0,
            horizontalListHeight: 38.0,
            onValueChanged: (val) => onValueChanged(val as T),
            hapticFeedbackType: HapticFeedbackType.lightImpact,
          ),
          if (text != null) ...[
            SizedBox(height: textPadding),
            FittedBox(child: Text(text!, style: TextStyle(color: context.textTheme.displaySmall?.color))),
          ]
        ],
      ),
    );
  }
}

class NamidaRawLikeButton extends StatelessWidget {
  final double size;
  final Color? enabledColor;
  final Color? disabledColor;
  final bool? isLiked;
  final EdgeInsetsGeometry padding;
  final Future<void> Function(bool isLiked) onTap;
  final IconData likedIcon;
  final IconData normalIcon;

  const NamidaRawLikeButton({
    super.key,
    this.size = 24.0,
    this.enabledColor,
    this.disabledColor,
    required this.isLiked,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.likedIcon = Broken.heart_tick,
    this.normalIcon = Broken.heart,
  });

  @override
  Widget build(BuildContext context) {
    return LikeButton(
      size: size,
      padding: padding,
      likeCountPadding: EdgeInsets.zero,
      bubblesColor: BubblesColor(
        dotPrimaryColor: context.theme.colorScheme.primary,
        dotSecondaryColor: context.theme.colorScheme.primaryContainer,
      ),
      circleColor: CircleColor(
        start: context.theme.colorScheme.tertiary,
        end: context.theme.colorScheme.tertiary,
      ),
      isLiked: isLiked,
      onTap: (isLiked) async {
        onTap(isLiked);
        return !isLiked;
      },
      likeBuilder: (value) => value
          ? Icon(
              likedIcon,
              color: enabledColor ?? context.theme.colorScheme.primary,
              size: size,
            )
          : Icon(
              normalIcon,
              color: disabledColor ?? context.theme.colorScheme.secondary,
              size: size,
            ),
    );
  }
}

class NamidaLikeButton extends StatelessWidget {
  final Track? track;
  final double size;
  final Color? color;
  const NamidaLikeButton({super.key, required this.track, this.size = 30.0, this.color});

  @override
  Widget build(BuildContext context) {
    return NamidaRawLikeButton(
      size: size,
      enabledColor: color,
      disabledColor: color,
      isLiked: track?.isFavourite,
      onTap: (isLiked) async {
        if (track != null) {
          PlaylistController.inst.favouriteButtonOnPressed(track!);
        }
      },
    );
  }
}

class NamidaIconButton extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final double horizontalPadding;
  final double verticalPadding;
  final double? iconSize;
  final IconData? icon;
  final Color? iconColor;
  final void Function()? onPressed;
  final String? tooltip;
  final bool disableColor;
  final Widget? child;

  const NamidaIconButton({
    super.key,
    this.padding,
    this.horizontalPadding = 8.0,
    this.verticalPadding = 0.0,
    required this.icon,
    this.onPressed,
    this.iconSize,
    this.iconColor,
    this.tooltip,
    this.disableColor = false,
    this.child,
  });

  @override
  State<NamidaIconButton> createState() => _NamidaIconButtonState();
}

class _NamidaIconButtonState extends State<NamidaIconButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (value) => setState(() => isPressed = true),
        onTapUp: (value) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isPressed ? 0.5 : 1.0,
          child: Padding(
            padding: widget.padding ?? EdgeInsets.symmetric(horizontal: widget.horizontalPadding, vertical: widget.verticalPadding),
            child: widget.child ??
                Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.disableColor ? null : (widget.iconColor ?? context.theme.colorScheme.secondary),
                ),
          ),
        ),
      ),
    );
  }
}

class NamidaAppBarIcon extends StatelessWidget {
  final IconData icon;
  final void Function()? onPressed;
  final String? tooltip;

  const NamidaAppBarIcon({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return NamidaIconButton(
      horizontalPadding: 6.0,
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

class NamidaPartyContainer extends StatelessWidget {
  final double spreadRadiusMultiplier;
  final double? width;
  final double? height;
  const NamidaPartyContainer({
    super.key,
    this.spreadRadiusMultiplier = 1.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (!settings.enablePartyModeColorSwap.value) {
      return Obx(
        () {
          final finalScale = WaveformController.inst.getCurrentAnimatingScale(Player.inst.nowPlayingPosition);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: height,
            width: width,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: CurrentColor.inst.color.withAlpha(150),
                  spreadRadius: 150 * finalScale * spreadRadiusMultiplier,
                  blurRadius: 10 + (200 * finalScale),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Obx(
        () {
          final finalScale = WaveformController.inst.getCurrentAnimatingScale(Player.inst.nowPlayingPosition);
          final firstHalf = CurrentColor.inst.paletteFirstHalf;
          final secondHalf = CurrentColor.inst.paletteSecondHalf;
          return height != null
              ? Row(
                  children: [
                    ...firstHalf.map(
                      (e) => AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: height,
                        width: width ?? context.width / firstHalf.length,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: e.withAlpha(150),
                              spreadRadius: 150 * finalScale * spreadRadiusMultiplier,
                              blurRadius: 10 + (200 * finalScale),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    ...secondHalf.map(
                      (e) => AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: height ?? context.height / secondHalf.length,
                        width: width,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: e.withAlpha(150),
                              spreadRadius: 140 * finalScale * spreadRadiusMultiplier,
                              blurRadius: 10 + (200 * finalScale),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
        },
      );
    }
  }
}

class SubpagesTopContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final String thirdLineText;
  final double? height;
  final double topPadding;
  final double bottomPadding;
  final Widget imageWidget;
  final List<Selectable> tracks;
  final QueueSource source;
  final String heroTag;
  final Widget? bottomWidget;
  const SubpagesTopContainer({
    super.key,
    required this.title,
    required this.subtitle,
    this.thirdLineText = '',
    this.height,
    required this.imageWidget,
    required this.tracks,
    this.topPadding = 16.0,
    this.bottomPadding = 16.0,
    required this.source,
    required this.heroTag,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    const pauseHero = 'kururing';
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12.0),
          margin: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              imageWidget,
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Transform.scale(
                      scale: (constraints.maxWidth * 0.005).withMaximum(1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 18.0,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 14.0),
                            child: NamidaHero(
                              tag: '${pauseHero}line1_$heroTag',
                              child: Text(
                                title,
                                style: context.textTheme.displayLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 2.0,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 14.0),
                            child: NamidaHero(
                              tag: '${pauseHero}line2_$heroTag',
                              child: Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: context.textTheme.displayMedium?.copyWith(fontSize: 14.0.multipliedFontScale),
                              ),
                            ),
                          ),
                          if (thirdLineText != '') ...[
                            const SizedBox(
                              height: 2.0,
                            ),
                            Container(
                              padding: const EdgeInsets.only(left: 14.0),
                              child: NamidaHero(
                                tag: '${pauseHero}line3_$heroTag',
                                child: Text(
                                  thirdLineText,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: context.textTheme.displaySmall?.copyWith(fontSize: 14.0.multipliedFontScale),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(
                            height: 18.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(width: 6.0),
                              SizedBox(
                                width: constraints.maxWidth * 0.3,
                                child: NamidaButton(
                                  minimumSize: true,
                                  icon: Broken.shuffle,
                                  onPressed: () => Player.inst.playOrPause(
                                    0,
                                    tracks,
                                    source,
                                    shuffle: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Player.inst.addToQueue(tracks),
                                  icon: const StackedIcon(
                                    disableColor: true,
                                    baseIcon: Broken.play,
                                    secondaryIcon: Broken.add_circle,
                                  ),
                                  label: Text(
                                    lang.PLAY_LAST,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: (constraints.maxWidth * 0.1).clamp(10.0, 14.0).multipliedFontScale),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: const Size(0.0, 0.0),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6.0),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (bottomWidget != null) bottomWidget!,
      ],
    );
  }
}

class AnimatingTile extends StatelessWidget {
  final int position;
  final Widget child;
  final bool shouldAnimate;
  const AnimatingTile({super.key, required this.position, required this.child, this.shouldAnimate = true});

  @override
  Widget build(BuildContext context) {
    return shouldAnimate
        ? AnimationConfiguration.staggeredList(
            position: position,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 25.0,
              child: FadeInAnimation(
                duration: const Duration(milliseconds: 400),
                child: child,
              ),
            ),
          )
        : child;
  }
}

class AnimatingGrid extends StatelessWidget {
  final int position;
  final int columnCount;
  final Widget child;
  final bool shouldAnimate;
  const AnimatingGrid({super.key, required this.position, required this.columnCount, required this.child, this.shouldAnimate = true});

  @override
  Widget build(BuildContext context) {
    return shouldAnimate
        ? AnimationConfiguration.staggeredGrid(
            columnCount: columnCount,
            position: position,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 25.0,
              child: FadeInAnimation(
                duration: const Duration(milliseconds: 400),
                child: child,
              ),
            ),
          )
        : child;
  }
}

class NamidaDrawerListTile extends StatelessWidget {
  final void Function()? onTap;
  final bool enabled;
  final String title;
  final IconData? icon;
  final double width;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final bool isCentered;
  final double iconSize;
  const NamidaDrawerListTile({
    super.key,
    this.onTap,
    required this.enabled,
    required this.title,
    required this.icon,
    this.width = double.infinity,
    this.margin = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
    this.isCentered = false,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        width: width,
        decoration: BoxDecoration(
          color: enabled ? CurrentColor.inst.color : context.theme.cardColor,
          borderRadius: BorderRadius.circular(8.0.multipliedRadius),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: CurrentColor.inst.color.withAlpha(100),
                    spreadRadius: 0.2,
                    blurRadius: 8.0,
                    offset: const Offset(0.0, 4.0),
                  ),
                ]
              : null,
        ),
        child: NamidaInkWell(
          padding: padding,
          onTap: onTap,
          borderRadius: 8.0,
          child: Row(
            mainAxisAlignment: isCentered ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white.withAlpha(200) : null,
                size: iconSize,
              ),
              if (title != '') ...[
                const SizedBox(width: 12.0),
                Text(
                  title,
                  style: context.textTheme.displayMedium?.copyWith(
                    color: enabled ? Colors.white.withAlpha(200) : null,
                    fontSize: context.width / 29,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SearchPageTitleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final String? buttonText;
  final IconData? buttonIcon;
  final void Function()? onPressed;
  const SearchPageTitleRow({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.icon,
    this.trailing,
    this.buttonText,
    this.buttonIcon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16.0),
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.displayLarge?.copyWith(fontSize: 15.5.multipliedFontScale),
                ),
                if (subtitle != '')
                  Text(
                    subtitle,
                    style: context.textTheme.displaySmall,
                  ),
              ],
            ),
          ],
        ),
        const Spacer(),
        trailing ??
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: context.theme.listTileTheme.iconColor),
              icon: Icon(buttonIcon, size: 20.0),
              label: Text(buttonText ?? ''),
              onPressed: onPressed,
            ),
        const SizedBox(width: 8.0),
      ],
    );
  }
}

class NamidaLogoContainer extends StatelessWidget {
  const NamidaLogoContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0).add(const EdgeInsets.only(top: 16.0, bottom: 8.0)),
      child: NamidaInkWell(
        onTap: () {
          NamidaNavigator.inst.toggleDrawer();
          if (NamidaNavigator.inst.currentRoute?.route != RouteType.PAGE_about) {
            NamidaNavigator.inst.navigateTo(const AboutPage());
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.center,
          width: double.infinity,
          height: 54.0,
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xffb9a48b).withAlpha(200) : const Color(0xffdfc6a7).withAlpha(255),
            borderRadius: BorderRadius.circular(12.0.multipliedRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffdfc6a7).withAlpha(context.isDarkMode ? 40 : 100),
                spreadRadius: 0.2,
                blurRadius: 8.0,
                offset: const Offset(0.0, 4.0),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/namida_icon.png',
                width: 40.0,
                height: 40.0,
                cacheHeight: 240,
                cacheWidth: 240,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Namida',
                style: context.textTheme.displayLarge?.copyWith(
                  color: Color.alphaBlend(const Color(0xffdfc6a7).withAlpha(90), Colors.white),
                  fontSize: context.width / 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NamidaContainerDivider extends StatelessWidget {
  final double? width;
  final double height;
  final Color? color;
  final Color? colorForce;
  final EdgeInsetsGeometry? margin;

  const NamidaContainerDivider({
    super.key,
    this.width,
    this.height = 2.0,
    this.color,
    this.margin,
    this.colorForce,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: colorForce ?? (color ?? context.theme.dividerColor).withAlpha(Get.isDarkMode ? 100 : 20),
        borderRadius: BorderRadius.circular(18.0.multipliedRadius),
      ),
    );
  }
}

class FadeDismissible extends StatefulWidget {
  final Widget child;
  final void Function(DismissDirection onDismissed)? onDismissed;
  final void Function(DismissUpdateDetails detailts)? onUpdate;
  final DismissDirection direction;

  const FadeDismissible({
    required super.key,
    required this.child,
    this.onDismissed,
    this.onUpdate,
    this.direction = DismissDirection.horizontal,
  });

  @override
  State<FadeDismissible> createState() => _FadeDismissibleState();
}

class _FadeDismissibleState extends State<FadeDismissible> {
  final fadeOpacity = ValueNotifier(0.0);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: widget.key!,
      onDismissed: widget.onDismissed,
      onUpdate: (details) {
        fadeOpacity.value = details.progress;
        if (widget.onUpdate != null) widget.onUpdate!(details);
      },
      direction: widget.direction,
      child: ValueListenableBuilder(
        valueListenable: fadeOpacity,
        builder: (context, value, child) => NamidaOpacity(
          opacity: 1 - fadeOpacity.value,
          child: widget.child,
        ),
      ),
    );
  }
}

class NamidaSelectableAutoLinkText extends StatelessWidget {
  final String text;
  const NamidaSelectableAutoLinkText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SelectableAutoLinkText(
      text,
      style: context.textTheme.displayMedium?.copyWith(fontSize: 13.5.multipliedFontScale),
      linkStyle: context.textTheme.displayMedium?.copyWith(
        color: context.theme.colorScheme.primary.withAlpha(210),
        fontSize: 13.5.multipliedFontScale,
      ),
      highlightedLinkStyle: TextStyle(
        color: context.theme.colorScheme.primary.withAlpha(220),
        backgroundColor: context.theme.colorScheme.onBackground.withAlpha(40),
        fontSize: 13.5.multipliedFontScale,
      ),
      onTap: (url) async {
        try {
          await launchUrlString(url, mode: LaunchMode.externalNonBrowserApplication);
        } catch (e) {
          await launchUrlString(url);
        }
      },
    );
  }
}

class DefaultPlaylistCard extends StatelessWidget {
  final Color colorScheme;
  final IconData icon;
  final String title;
  final String text;
  final double? width;
  final bool displayLoadingIndicator;
  final void Function()? onTap;

  const DefaultPlaylistCard({
    super.key,
    required this.colorScheme,
    required this.icon,
    required this.title,
    this.text = '',
    this.width,
    this.displayLoadingIndicator = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NamidaInkWell(
      borderRadius: 12.0,
      bgColor: Color.alphaBlend(colorScheme.withAlpha(10), context.theme.cardColor),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.withAlpha(200),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              title.overflow,
              style: context.textTheme.displayMedium?.copyWith(color: Color.alphaBlend(colorScheme.withAlpha(10), context.textTheme.displayMedium!.color!)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6.0),
          displayLoadingIndicator
              ? const LoadingIndicator()
              : Text(
                  text,
                  style: context.textTheme.displayMedium?.copyWith(color: Color.alphaBlend(colorScheme.withAlpha(30), context.textTheme.displayMedium!.color!)),
                ),
          const SizedBox(width: 2.0),
        ],
      ),
    );
  }
}

class NamidaCircularPercentage extends StatelessWidget {
  final double size;
  final double percentage;
  const NamidaCircularPercentage({super.key, this.size = 48.0, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SleekCircularSlider(
          appearance: CircularSliderAppearance(
            customWidths: CustomSliderWidths(
              trackWidth: size / 24,
              progressBarWidth: size / 12,
            ),
            customColors: CustomSliderColors(
              dotColor: Colors.transparent,
              trackColor: context.theme.cardTheme.color,
              dynamicGradient: true,
              progressBarColors: [
                context.theme.colorScheme.primary.withAlpha(100),
                Colors.transparent,
                context.theme.colorScheme.secondary.withAlpha(100),
                Colors.transparent,
                context.theme.colorScheme.primary.withAlpha(100),
              ],
              hideShadow: true,
            ),
            size: size,
            spinnerMode: true,
          ),
        ),
        if (percentage.isFinite)
          Text(
            "${((percentage).clamp(0.01, 1) * 100).toStringAsFixed(0)}%",
            style: context.textTheme.displaySmall?.copyWith(fontSize: size / 3.2),
          )
      ],
    );
  }
}

class NamidaListView extends StatelessWidget {
  final Widget Function(BuildContext context, int i) itemBuilder;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(int index)? onReorderStart;
  final void Function(int index)? onReorderEnd;
  final Widget? header;
  final List<Widget>? widgetsInColumn;
  final EdgeInsets? padding;
  final List<double>? itemExtents;
  final ScrollController? scrollController;
  final int itemCount;
  final List<Widget>? moreWidgets;
  final bool buildDefaultDragHandles;
  final ScrollPhysics? physics;

  const NamidaListView({
    super.key,
    this.header,
    this.widgetsInColumn,
    this.padding,
    this.onReorder,
    required this.itemBuilder,
    required this.itemCount,
    required this.itemExtents,
    this.moreWidgets,
    this.scrollController,
    this.buildDefaultDragHandles = true,
    this.onReorderStart,
    this.onReorderEnd,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final sc = scrollController ?? ScrollController();
    return AnimationLimiter(
      child: CupertinoScrollbar(
        controller: sc,
        child: Column(
          children: [
            if (widgetsInColumn != null) ...widgetsInColumn!,
            Expanded(
              child: itemExtents != null
                  ? KnownExtentsReorderableListView.builder(
                      itemExtents: itemExtents!,
                      scrollController: sc,
                      padding: padding ?? const EdgeInsets.only(bottom: kBottomPadding),
                      itemBuilder: itemBuilder,
                      itemCount: itemCount,
                      onReorder: onReorder ?? (oldIndex, newIndex) {},
                      proxyDecorator: (child, index, animation) => child,
                      header: header,
                      buildDefaultDragHandles: buildDefaultDragHandles,
                      physics: physics,
                      onReorderStart: onReorderStart,
                      onReorderEnd: onReorderEnd,
                    )
                  : ReorderableListView.builder(
                      itemExtent: itemExtents?.firstOrNull,
                      scrollController: sc,
                      padding: padding ?? const EdgeInsets.only(bottom: kBottomPadding),
                      itemBuilder: itemBuilder,
                      itemCount: itemCount,
                      onReorder: onReorder ?? (oldIndex, newIndex) {},
                      proxyDecorator: (child, index, animation) => child,
                      onReorderStart: onReorderStart,
                      onReorderEnd: onReorderEnd,
                      header: header,
                      buildDefaultDragHandles: onReorder != null,
                      physics: physics,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NamidaTracksList extends StatelessWidget {
  final List<Selectable>? queue;
  final int queueLength;
  final Widget Function(BuildContext context, int i)? itemBuilder;
  final Widget? header;
  final Widget? footer;
  final List<Widget>? widgetsInColumn;
  final EdgeInsetsGeometry? paddingAfterHeader;
  final ScrollController? scrollController;
  final EdgeInsets? padding;
  final bool isTrackSelectable;
  final ScrollPhysics? physics;
  final QueueSource queueSource;
  final bool displayTrackNumber;
  final bool shouldAnimate;
  final String Function(Selectable track)? thirdLineText;

  const NamidaTracksList({
    super.key,
    this.queue,
    this.itemBuilder,
    this.header,
    this.footer,
    this.widgetsInColumn,
    this.paddingAfterHeader,
    this.scrollController,
    this.padding = const EdgeInsets.only(bottom: kBottomPadding),
    required this.queueLength,
    this.isTrackSelectable = true,
    this.physics,
    required this.queueSource,
    this.displayTrackNumber = false,
    this.shouldAnimate = true,
    this.thirdLineText,
  });

  @override
  Widget build(BuildContext context) {
    return NamidaListView(
      header: header,
      widgetsInColumn: widgetsInColumn,
      scrollController: scrollController,
      itemCount: queueLength,
      itemExtents: List<double>.filled(queueLength, Dimensions.inst.trackTileItemExtent),
      padding: padding,
      physics: physics,
      itemBuilder: itemBuilder ??
          (context, i) {
            if (queue != null) {
              final track = queue![i];
              return AnimatingTile(
                key: ValueKey(i),
                position: i,
                shouldAnimate: shouldAnimate,
                child: TrackTile(
                  index: i,
                  trackOrTwd: track,
                  draggableThumbnail: false,
                  selectable: isTrackSelectable,
                  queueSource: queueSource,
                  displayTrackNumber: displayTrackNumber,
                  thirdLineText: thirdLineText == null ? '' : thirdLineText!(track),
                ),
              );
            }
            return const Text('PASS A QUEUE OR USE ITEM BUILDER');
          },
    );
  }
}

class NamidaSupportButton extends StatelessWidget {
  final String? title;
  final bool closeDialog;
  const NamidaSupportButton({super.key, this.title, this.closeDialog = true});

  @override
  Widget build(BuildContext context) {
    return NamidaButton(
      icon: Broken.heart,
      text: title ?? lang.SUPPORT,
      onPressed: () {
        closeDialog.closeDialog();
        launchUrlString(AppSocial.DONATE_BUY_ME_A_COFFEE);
      },
    );
  }
}

class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: child,
    );
  }
}

class NamidaInkWell extends StatelessWidget {
  final Color? bgColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxDecoration decoration;
  final Widget? child;
  final int animationDurationMS;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  /// Setting this to [true] will force the [borderRadius] to be [0.0].
  final bool transparentHighlight;
  const NamidaInkWell({
    super.key,
    this.bgColor,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 12.0,
    this.padding = EdgeInsets.zero,
    this.decoration = const BoxDecoration(),
    this.child,
    this.transparentHighlight = false,
    this.animationDurationMS = 0,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final realBorderRadius = transparentHighlight ? 0.0 : borderRadius;
    final borderR = BorderRadius.circular(realBorderRadius.multipliedRadius);
    return AnimatedContainer(
      height: height,
      width: width,
      margin: margin,
      duration: Duration(milliseconds: animationDurationMS),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.transparent,
        borderRadius: borderR,
      ),
      foregroundDecoration: BoxDecoration(
        border: decoration.border,
        borderRadius: borderR,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          highlightColor: transparentHighlight ? Colors.transparent : Color.alphaBlend(context.theme.scaffoldBackgroundColor.withAlpha(20), context.theme.highlightColor),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class HistoryJumpToDayIcon<T extends ItemWithDate, E> extends StatelessWidget {
  final HistoryManager<T, E> controller;
  const HistoryJumpToDayIcon({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return NamidaAppBarIcon(
      icon: Broken.calendar,
      tooltip: lang.JUMP_TO_DAY,
      onPressed: () {
        showCalendarDialog(
          historyController: controller,
          title: lang.JUMP_TO_DAY,
          buttonText: lang.JUMP,
          calendarType: CalendarDatePicker2Type.single,
          useHistoryDates: true,
          onGenerate: (dates) {
            NamidaNavigator.inst.closeDialog();
            final dayToScrollTo = dates.firstOrNull?.toDaysSince1970() ?? 0;
            final days = controller.historyDays.toList();
            days.removeWhere((element) => element <= dayToScrollTo);
            final itemExtents = controller.allItemsExtentsHistory;
            double totalScrollOffset = 0;
            days.loop((e, index) => totalScrollOffset += itemExtents[index]);
            controller.scrollController.jumpTo(totalScrollOffset + 100.0);
          },
        );
      },
    );
  }
}

class BetweenDatesTextButton extends StatefulWidget {
  final bool useHistoryDates;
  final void Function(List<DateTime> dates) onConfirm;
  final bool maxToday;
  final int tracksLength;

  const BetweenDatesTextButton({
    super.key,
    required this.useHistoryDates,
    required this.onConfirm,
    this.maxToday = false,
    this.tracksLength = 0,
  });

  @override
  State<BetweenDatesTextButton> createState() => _BetweenDatesTextButtonState();
}

class _BetweenDatesTextButtonState extends State<BetweenDatesTextButton> {
  DateTime? oldestDate;
  DateTime? newestDate;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(lang.BETWEEN_DATES);

    return TextButton.icon(
      onPressed: () {
        showCalendarDialog(
          useHistoryDates: widget.useHistoryDates,
          lastDate: widget.maxToday ? DateTime.now() : null,
          title: lang.BETWEEN_DATES,
          buttonText: lang.CONFIRM,
          onGenerate: (dates) {
            oldestDate = dates.firstOrNull;
            newestDate = dates.lastOrNull;
            widget.onConfirm(dates);
            setState(() {});
          },
        );
      },
      icon: const Icon(Broken.calendar_1),
      label: oldestDate == null || newestDate == null
          ? textWidget
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    textWidget,
                    const SizedBox(width: 6.0),
                    if (widget.tracksLength != 0)
                      Text(
                        "(${widget.tracksLength.displayTrackKeyword})",
                        style: context.textTheme.displaySmall,
                      ),
                  ],
                ),
                Text(
                  "${oldestDate?.millisecondsSinceEpoch.dateFormattedOriginal} → ${newestDate?.millisecondsSinceEpoch.dateFormattedOriginal}",
                  style: context.textTheme.displaySmall,
                ),
              ],
            ),
    );
  }
}

/// Obx(() => showIf.value ? child : const SizedBox());
class ObxShow extends StatelessWidget {
  final RxBool showIf;
  final Widget child;

  const ObxShow({
    super.key,
    required this.showIf,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Obx(() => showIf.value ? child : const SizedBox());
}

class NamidaHero extends StatelessWidget {
  final Object tag;
  final Widget child;
  final bool enabled;
  const NamidaHero({super.key, required this.tag, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return enabled
        ? Hero(
            tag: tag,
            child: child,
          )
        : child;
  }
}

class NamidaAnimatedSwitcher extends StatelessWidget {
  final Widget firstChild;
  final Widget secondChild;
  final bool showFirst;
  final int durationMS;
  final int? reverseDurationMS;
  final Curve firstCurve;
  final Curve secondCurve;
  final Curve sizeCurve;
  final Curve? allCurves;
  const NamidaAnimatedSwitcher({
    super.key,
    required this.firstChild,
    required this.secondChild,
    required this.showFirst,
    this.durationMS = 400,
    this.reverseDurationMS,
    this.firstCurve = Curves.linear,
    this.secondCurve = Curves.linear,
    this.sizeCurve = Curves.linear,
    this.allCurves,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState: showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: Duration(milliseconds: durationMS),
      reverseDuration: Duration(milliseconds: reverseDurationMS ?? durationMS),
      firstCurve: allCurves ?? firstCurve,
      secondCurve: allCurves ?? secondCurve,
      sizeCurve: allCurves ?? sizeCurve,
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              key: bottomChildKey,
              top: 0,
              child: bottomChild,
            ),
            Positioned(
              key: topChildKey,
              child: topChild,
            ),
          ],
        );
      },
    );
  }
}

class ShimmerWrapper extends StatelessWidget {
  final bool shimmerEnabled;
  final Widget child;
  final int fadeDurationMS;
  final int shimmerDelayMS;
  final int shimmerDurationMS;
  final bool transparent;

  const ShimmerWrapper({
    super.key,
    required this.shimmerEnabled,
    required this.child,
    this.fadeDurationMS = 600,
    this.shimmerDelayMS = 400,
    this.shimmerDurationMS = 700,
    this.transparent = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = transparent ? Colors.transparent : context.theme.cardColor.withAlpha(120);
    return AnimatedSwitcher(
      duration: fadeDurationMS.ms,
      child: shimmerEnabled
          ? child.animate(
              onPlay: (controller) => controller.repeat(),
              effects: [
                ShimmerEffect(
                  delay: shimmerDelayMS.ms,
                  duration: shimmerDurationMS.ms,
                  colors: [
                    color,
                    const Color(0x80FFFFFF),
                    color,
                  ],
                ),
              ],
            )
          : child,
    );
  }
}

class LazyLoadListView extends StatefulWidget {
  final Widget Function(ScrollController controller) listview;
  final Future<void> Function() onReachingEnd;
  final int extend;
  final ScrollController? scrollController;
  const LazyLoadListView({
    super.key,
    required this.listview,
    required this.onReachingEnd,
    this.extend = 400,
    this.scrollController,
  });

  @override
  State<LazyLoadListView> createState() => _LazyLoadListViewState();
}

class _LazyLoadListViewState extends State<LazyLoadListView> {
  late ScrollController controller;
  bool isExecuting = false;

  void _scrollListener() async {
    if (isExecuting) return;

    if (controller.offset >= controller.position.maxScrollExtent - widget.extend && !controller.position.outOfRange) {
      isExecuting = true;
      await widget.onReachingEnd();
      isExecuting = false;
    }
  }

  @override
  void initState() {
    super.initState();
    controller = (widget.scrollController ?? ScrollController())..addListener(_scrollListener);
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.listview(controller);
  }
}

class NamidaPopupItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final void Function() onTap;

  const NamidaPopupItem({
    required this.icon,
    required this.title,
    this.subtitle = '',
    required this.onTap,
  });
}

class NamidaPopupWrapper extends StatelessWidget {
  final Widget child;
  final List<Widget> children;
  final List<NamidaPopupItem> childrenDefault;
  final VoidCallback? onTap;
  final VoidCallback? onPop;
  final bool openOnTap;
  final bool openOnLongPress;

  const NamidaPopupWrapper({
    super.key,
    this.child = const MoreIcon(),
    this.children = const [],
    this.childrenDefault = const [],
    this.onTap,
    this.onPop,
    this.openOnTap = true,
    this.openOnLongPress = true,
  });

  void popMenu({bool handleClosing = true}) {
    onPop?.call();
    NamidaNavigator.inst.popMenu(handleClosing: handleClosing);
  }

  void _showPopupMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    const offset = Offset(0.0, 24.0);
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset, ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    await NamidaNavigator.inst.showMenu(
      showMenu(
        useRootNavigator: true,
        context: context,
        position: position,
        items: [
          ...childrenDefault.map(
            (e) => PopupMenuItem(
              height: 42.0,
              onTap: e.onTap,
              child: Row(
                children: [
                  Icon(e.icon, size: 20.0),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: context.textTheme.displayMedium,
                        ),
                        if (e.subtitle != '')
                          Text(
                            e.subtitle,
                            style: context.textTheme.displaySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...children.map(
            (e) => PopupMenuItem(
              onTap: null,
              height: 32.0,
              padding: EdgeInsets.zero,
              child: e,
            ),
          ),
        ],
      ),
    );
    if (context.mounted) {
      popMenu(handleClosing: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) onTap!();
        if (openOnTap) {
          _showPopupMenu(context);
        }
      },
      onLongPress: openOnLongPress ? () => _showPopupMenu(context) : null,
      child: child,
    );
  }
}

class NamidaLifeCycleWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onResume;
  final Future<void> Function()? onSuspending;
  final Future<void> Function()? onDetach;

  const NamidaLifeCycleWrapper({
    super.key,
    required this.child,
    this.onResume,
    this.onSuspending,
    this.onDetach,
  });

  @override
  State<NamidaLifeCycleWrapper> createState() => _NamidaLifeCycleWrapperState();
}

class _NamidaLifeCycleWrapperState extends State<NamidaLifeCycleWrapper> {
  late final MethodChannel namidaChannel;

  @override
  void initState() {
    super.initState();
    // -- the new flutter update, calls AppLifecycleState.inactive whenever the app
    // -- loses focus, like swiping notification center, not ideal for what we need
    // -- so we use a method channel whenever `onUserLeaveHint` is called from FlutterActivity
    namidaChannel = const MethodChannel('namida');

    namidaChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onResume':
          await Future.wait([
            SystemChrome.setPreferredOrientations(kDefaultOrientations),
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values),
            if (widget.onResume != null) widget.onResume!(),
          ]);
        case 'onUserLeaveHint':
          await widget.onSuspending?.call();
        case 'onStop':
          await widget.onDetach?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class NamidaAspectRatio extends StatelessWidget {
  final double? aspectRatio;
  final Widget child;

  const NamidaAspectRatio({
    super.key,
    required this.aspectRatio,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return aspectRatio == null
        ? child
        : AspectRatio(
            aspectRatio: aspectRatio!,
            child: child,
          );
  }
}

class NamidaTabView extends StatefulWidget {
  final int initialIndex;
  final List<String> tabs;
  final List<Widget> children;
  final void Function(int index) onIndexChanged;
  final bool isScrollable;

  const NamidaTabView({
    super.key,
    required this.children,
    required this.initialIndex,
    required this.tabs,
    required this.onIndexChanged,
    this.isScrollable = false,
  });

  @override
  State<NamidaTabView> createState() => _NamidaTabViewState();
}

class _NamidaTabViewState extends State<NamidaTabView> with SingleTickerProviderStateMixin {
  late TabController controller;

  void fn() => widget.onIndexChanged(controller.index);

  @override
  void initState() {
    widget.onIndexChanged(widget.initialIndex);
    controller = TabController(
      length: widget.children.length,
      vsync: this,
      animationDuration: const Duration(milliseconds: 500),
      initialIndex: widget.initialIndex,
    );
    controller.addListener(fn);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(fn);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          indicatorWeight: 3.0,
          controller: controller,
          isScrollable: widget.isScrollable,
          tabs: widget.tabs
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Text(e),
                ),
              )
              .toList(),
          splashBorderRadius: BorderRadius.circular(12.0.multipliedRadius),
          // indicatorPadding: const EdgeInsets.symmetric(horizontal: 32.0),
          indicatorSize: TabBarIndicatorSize.label,
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}

class ShaderFadingWidget extends StatelessWidget {
  final bool biggerValues;
  final Widget child;
  final Alignment begin;
  final Alignment end;
  const ShaderFadingWidget({
    super.key,
    this.biggerValues = false,
    required this.child,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final stops = biggerValues ? [0.07, 0.3, 0.6, 0.8, 1.0] : [0.0, 0.2, 0.8, 0.9, 1.0];
        return LinearGradient(
          begin: begin,
          end: end,
          tileMode: TileMode.clamp,
          stops: stops,
          colors: const [Colors.transparent, Colors.white, Colors.white, Colors.white, Colors.transparent],
        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
      },
      child: child,
    );
  }
}

class NamidaOpacity extends StatelessWidget {
  final bool enabled;
  final double opacity;
  final Widget child;

  const NamidaOpacity({
    super.key,
    required this.opacity,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity == 0) {
      return const SizedBox();
    } else if (!enabled || opacity == 1) {
      return child;
    }
    return Opacity(
      key: key,
      opacity: opacity,
      child: child,
    );
  }
}
