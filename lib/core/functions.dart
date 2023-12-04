import 'dart:async';
import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:history_manager/history_manager.dart';

import 'package:namida/class/folder.dart';
import 'package:namida/class/queue.dart';
import 'package:namida/class/track.dart';
import 'package:namida/controller/current_color.dart';
import 'package:namida/controller/folders_controller.dart';
import 'package:namida/controller/history_controller.dart';
import 'package:namida/controller/indexer_controller.dart';
import 'package:namida/controller/miniplayer_controller.dart';
import 'package:namida/controller/navigator_controller.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/controller/playlist_controller.dart';
import 'package:namida/controller/scroll_search_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/namida_converter_ext.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/ui/dialogs/edit_tags_dialog.dart';
import 'package:namida/ui/pages/subpages/album_tracks_subpage.dart';
import 'package:namida/ui/pages/subpages/artist_tracks_subpage.dart';
import 'package:namida/ui/pages/subpages/genre_tracks_subpage.dart';
import 'package:namida/ui/pages/subpages/playlist_tracks_subpage.dart';
import 'package:namida/ui/pages/subpages/queue_tracks_subpage.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';

class NamidaOnTaps {
  static NamidaOnTaps get inst => _instance;
  static final NamidaOnTaps _instance = NamidaOnTaps._internal();
  NamidaOnTaps._internal();

  Future<void> onArtistTap(String name, [List<Track>? tracksPre]) async {
    final tracks = tracksPre ?? name.getArtistTracks();

    final albumIds = name.getArtistAlbums();

    NamidaNavigator.inst.navigateTo(
      ArtistTracksPage(
        name: name,
        tracks: tracks,
        albumIdentifiers: albumIds,
      ),
    );
  }

  Future<void> onAlbumTap(String albumIdentifier) async {
    final tracks = albumIdentifier.getAlbumTracks();

    NamidaNavigator.inst.navigateTo(
      AlbumTracksPage(
        albumIdentifier: albumIdentifier,
        tracks: tracks,
      ),
    );
  }

  Future<void> onGenreTap(String name) async {
    NamidaNavigator.inst.navigateTo(
      GenreTracksPage(
        name: name,
        tracks: name.getGenresTracks(),
      ),
    );
  }

  Future<void> onNormalPlaylistTap(
    String playlistName, {
    bool disableAnimation = false,
  }) async {
    NamidaNavigator.inst.navigateTo(
      NormalPlaylistTracksPage(
        playlistName: playlistName,
        disableAnimation: disableAnimation,
      ),
    );
  }

  Future<void> onHistoryPlaylistTap({
    double initialScrollOffset = 0,
    int? indexToHighlight,
    int? dayOfHighLight,
  }) async {
    HistoryController.inst.indexToHighlight.value = indexToHighlight;
    HistoryController.inst.dayOfHighLight.value = dayOfHighLight;

    void jump() => HistoryController.inst.scrollController.jumpTo(initialScrollOffset);

    if (NamidaNavigator.inst.currentRoute?.route == RouteType.SUBPAGE_historyTracks) {
      NamidaNavigator.inst.closeAllDialogs();
      MiniPlayerController.inst.snapToMini();
      jump();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        jump();
      });
      await NamidaNavigator.inst.navigateTo(
        const HistoryTracksPage(),
      );
    }
  }

  Future<void> onMostPlayedPlaylistTap() async {
    NamidaNavigator.inst.navigateTo(const MostPlayedTracksPage());
  }

  Future<void> onFolderTap(Folder folder, {Track? trackToScrollTo}) async {
    ScrollSearchController.inst.animatePageController(LibraryTab.folders);
    Folders.inst.stepIn(folder, trackToScrollTo: trackToScrollTo);
  }

  Future<void> onQueueTap(Queue queue) async {
    NamidaNavigator.inst.navigateTo(
      QueueTracksPage(queue: queue),
    );
  }

  Future<void> onRemoveTracksFromPlaylist(String name, List<TrackWithDate> tracksWithDates) async {
    void showSnacky({required void Function() whatDoYouWant}) {
      snackyy(
        title: lang.UNDO_CHANGES,
        message: lang.UNDO_CHANGES_DELETED_TRACK,
        displaySeconds: 3,
        button: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            whatDoYouWant();
          },
          child: Text(lang.UNDO),
        ),
      );
    }

    final bool isHistory = name == k_PLAYLIST_NAME_HISTORY;

    if (isHistory) {
      final tempList = List<TrackWithDate>.from(tracksWithDates);
      await HistoryController.inst.removeTracksFromHistory(tracksWithDates);
      showSnacky(
        whatDoYouWant: () async {
          await HistoryController.inst.addTracksToHistory(tempList);
          HistoryController.inst.sortHistoryTracks(tempList.mapped((e) => e.dateAdded.toDaysSince1970()));
        },
      );
    } else {
      final playlist = PlaylistController.inst.getPlaylist(name);
      if (playlist == null) return;

      final Map<TrackWithDate, int> twdAndIndexes = {};
      tracksWithDates.loop((twd, index) {
        twdAndIndexes[twd] = playlist.tracks.indexOf(twd);
      });

      await PlaylistController.inst.removeTracksFromPlaylist(playlist, twdAndIndexes.values.toList());
      showSnacky(
        whatDoYouWant: () async {
          PlaylistController.inst.insertTracksInPlaylistWithEachIndex(
            playlist,
            twdAndIndexes,
          );
        },
      );
    }
  }

  void onSubPageTracksSortIconTap(MediaType media) {
    final sorters = (settings.mediaItemsTrackSorting[media] ?? []).obs;
    final defaultSorts = <MediaType, List<SortType>>{
      MediaType.album: [SortType.trackNo, SortType.year, SortType.title],
      MediaType.artist: [SortType.year, SortType.title],
      MediaType.genre: [SortType.year, SortType.title],
      MediaType.folder: [SortType.filename],
    };

    final allSorts = List<SortType>.from(SortType.values).obs;
    void resortVisualItems() => allSorts.sortByReverse((e) {
          final active = sorters.contains(e);
          return active ? sorters.length - sorters.indexOf(e) : sorters.indexOf(e);
        });
    resortVisualItems();

    void resortMedia() {
      settings.updateMediaItemsTrackSorting(media, sorters);
      Indexer.inst.sortMediaTracksSubLists([media]);
    }

    NamidaNavigator.inst.navigateDialog(
      onDismissing: resortMedia,
      dialog: CustomBlurryDialog(
        title: "${lang.SORT_BY} (${lang.REORDERABLE})",
        actions: [
          IconButton(
            icon: const Icon(Broken.refresh),
            tooltip: lang.RESTORE_DEFAULTS,
            onPressed: () {
              final defaults = defaultSorts[media] ?? [SortType.year];
              sorters
                ..clear()
                ..addAll(defaults);
              settings.updateMediaItemsTrackSorting(media, defaults);
            },
          ),
          NamidaButton(
            text: lang.DONE,
            onPressed: () {
              resortMedia();
              NamidaNavigator.inst.closeDialog();
            },
          ),
        ],
        child: SizedBox(
          width: Get.width,
          height: Get.height * 0.4,
          child: Column(
            children: [
              Obx(
                () {
                  final currentlyReverse = settings.mediaItemsTrackSortingReverse[media] ?? false;
                  return ListTileWithCheckMark(
                    title: lang.REVERSE_ORDER,
                    active: currentlyReverse,
                    onTap: () {
                      settings.updateMediaItemsTrackSortingReverse(media, !currentlyReverse);
                    },
                  );
                },
              ),
              const SizedBox(height: 12.0),
              Expanded(
                child: Obx(
                  () => NamidaListView(
                    padding: EdgeInsets.zero,
                    itemCount: allSorts.length,
                    itemExtents: null,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = allSorts.removeAt(oldIndex);
                      allSorts.insertSafe(newIndex, item);
                      final activeSorts = allSorts.where((element) => sorters.contains(element)).toList();
                      sorters
                        ..clear()
                        ..addAll(activeSorts);
                      settings.updateMediaItemsTrackSorting(media, activeSorts);
                    },
                    itemBuilder: (context, i) {
                      final sorting = allSorts[i];
                      return Padding(
                        key: ValueKey(i),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        child: Obx(
                          () {
                            final isActive = sorters.contains(sorting);
                            return ListTileWithCheckMark(
                              title: "${i + 1}. ${sorting.toText()}",
                              active: isActive,
                              onTap: () {
                                if (isActive && sorters.length <= 1) {
                                  showMinimumItemsSnack();
                                  return;
                                }
                                if (sorters.contains(sorting)) {
                                  sorters.remove(sorting);
                                } else {
                                  sorters.insertSafe(i, sorting);
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showCalendarDialog<T extends ItemWithDate, E>({
  required String title,
  required String buttonText,
  CalendarDatePicker2Type calendarType = CalendarDatePicker2Type.range,
  DateTime? firstDate,
  DateTime? lastDate,
  required bool useHistoryDates,
  HistoryManager<T, E>? historyController,
  void Function(List<DateTime> dates)? onChanged,
  required void Function(List<DateTime> dates) onGenerate,
}) async {
  historyController ??= HistoryController.inst as HistoryManager<T, E>;

  final dates = <DateTime>[];

  final RxInt daysNumber = 0.obs;
  final RxBool canGenerate = false.obs;

  void calculateDaysNumber() {
    if (canGenerate.value) {
      if (dates.length == 2) {
        daysNumber.value = dates[0].difference(dates[1]).inDays.abs() + 1;
      }
    } else {
      daysNumber.value = 0;
    }
  }

  void reEvaluateCanGenerate() {
    switch (calendarType) {
      case CalendarDatePicker2Type.range:
        canGenerate.value = dates.length == 2;
      case CalendarDatePicker2Type.single:
        canGenerate.value = dates.length == 1;
      case CalendarDatePicker2Type.multi:
        canGenerate.value = true;
      default:
        null;
    }
  }

  await NamidaNavigator.inst.navigateDialog(
    scale: 0.90,
    dialog: CustomBlurryDialog(
      titleWidgetInPadding: Obx(
        () => Text(
          '$title ${daysNumber.value == 0 ? '' : "(${daysNumber.value.displayDayKeyword})"}',
          style: Get.textTheme.displayLarge,
        ),
      ),
      normalTitleStyle: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28.0),
      actions: [
        const CancelButton(),
        Obx(
          () => NamidaButton(
            enabled: canGenerate.value,
            onPressed: () => onGenerate(dates),
            text: buttonText,
          ),
        ),
      ],
      child: CalendarDatePicker2(
        onValueChanged: (value) {
          final dts = value.whereType<DateTime>().toList();
          dates
            ..clear()
            ..addAll(dts);

          if (onChanged != null) onChanged(dts);

          reEvaluateCanGenerate();
          calculateDaysNumber();
        },
        config: CalendarDatePicker2Config(
          calendarType: calendarType,
          firstDate: useHistoryDates ? historyController.oldestTrack?.dateTimeAdded : firstDate,
          lastDate: useHistoryDates ? historyController.newestTrack?.dateTimeAdded : lastDate,
        ),
        value: const [],
      ),
    ),
  );
}

Future<String> showNamidaBottomSheetWithTextField({
  required BuildContext context,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
  bool showDragHandle = true,
  required String title,
  String? initalControllerText,
  required String hintText,
  required String labelText,
  required String? Function(String? value)? validator,
  required String buttonText,
  TextStyle? buttonTextStyle,
  Color? buttonColor,
  required FutureOr<bool> Function(String text) onButtonTap,
}) async {
  final controller = TextEditingController(text: initalControllerText);
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final focusNode = FocusNode();
  focusNode.requestFocus();

  await Future.delayed(Duration.zero); // delay bcz sometimes doesnt show
  // ignore: use_build_context_synchronously
  await showModalBottomSheet(
    context: context,
    useRootNavigator: useRootNavigator,
    showDragHandle: showDragHandle,
    isScrollControlled: isScrollControlled,
    builder: (context) {
      final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0).add(EdgeInsets.only(bottom: 18.0 + bottomPadding)),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: context.textTheme.displayLarge,
              ),
              const SizedBox(height: 18.0),
              CustomTagTextField(
                focusNode: focusNode,
                controller: controller,
                hintText: hintText,
                labelText: labelText,
                validator: validator,
              ),
              const SizedBox(height: 18.0),
              Row(
                children: [
                  SizedBox(width: context.width * 0.1),
                  CancelButton(onPressed: context.safePop),
                  SizedBox(width: context.width * 0.1),
                  Expanded(
                    child: NamidaInkWell(
                      borderRadius: 12.0,
                      padding: const EdgeInsets.all(12.0),
                      height: 48.0,
                      bgColor: buttonColor ?? CurrentColor.inst.color,
                      decoration: const BoxDecoration(),
                      child: Center(
                        child: Text(
                          buttonText,
                          style: buttonTextStyle ?? context.textTheme.displayMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ),
                      onTap: () async {
                        if (formKey.currentState!.validate()) {
                          final canPop = await onButtonTap(controller.text);
                          if (canPop && context.mounted) context.safePop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  final t = controller.text;
  controller.disposeAfterAnimation(also: focusNode.dispose);
  return t;
}

// Returns a [0-1] scale representing how much similar both are.
double checkIfListsSimilar<E>(List<E> q1, List<E> q2, {bool fullyFunctional = false}) {
  if (fullyFunctional) {
    if (q1.isEmpty && q2.isEmpty) {
      return 1.0;
    }
    final finallength = q1.length > q2.length ? q2.length : q1.length;
    int trueconditions = 0;
    for (int i = 0; i < finallength; i++) {
      if (q1[i] == q2[i]) trueconditions++;
    }
    return trueconditions / finallength;
  } else {
    return q1.isEqualTo(q2) ? 1.0 : 0.0;
  }
}

bool checkIfQueueSameAsCurrent(List<Selectable> queue) {
  return checkIfListsSimilar(queue, Player.inst.currentQueue) == 1.0;
}

bool checkIfQueueSameAsAllTracks(List<Selectable> queue) {
  return checkIfListsSimilar(queue, allTracksInLibrary) == 1.0;
}

/// **takes:**
/// ```
/// {
///   'allAvailableDirectories': <Directory, bool>{},
///   'directoriesToExclude': <String>[],
///   'extensions': <String>{},
///   'respectNoMedia': bool ?? true,
/// }
/// ```
///
/// **returns:**
/// ```
/// {
/// 'allPaths': <String>{},
/// 'pathsExcludedByNoMedia': <String>{},
/// }
/// ```
Map<String, Set<String>> getFilesTypeIsolate(Map parameters) {
  final allAvailableDirectories = parameters['allAvailableDirectories'] as Map<Directory, bool>;
  final directoriesToExclude = parameters['directoriesToExclude'] as List<String>? ?? [];
  final extensions = parameters['extensions'] as Set<String>;
  final respectNoMedia = parameters['respectNoMedia'] as bool? ?? true;

  final allPaths = <String>{};
  final excludedByNoMedia = <String>{};

  allAvailableDirectories.keys.toList().loop((d, index) {
    final hasNoMedia = allAvailableDirectories[d] ?? false;
    try {
      for (final systemEntity in d.listSync()) {
        if (systemEntity is File) {
          final path = systemEntity.path;
          // -- skip if not in extensions
          if (!extensions.any((ext) => path.endsWith(ext))) {
            continue;
          }
          // -- skip if in nomedia folder & specified to exclude
          if (respectNoMedia && hasNoMedia) {
            excludedByNoMedia.add(path);
            continue;
          }

          // -- skips if the file is included in one of the excluded folders.
          if (directoriesToExclude.any((exc) => path.startsWith(exc))) {
            continue;
          }
          allPaths.add(path);
        }
      }
    } catch (_) {}
  });
  return {
    'allPaths': allPaths,
    'pathsExcludedByNoMedia': excludedByNoMedia,
  };
}
