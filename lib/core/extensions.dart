// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dart_extensions/dart_extensions.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import 'package:namida/class/track.dart';
import 'package:namida/controller/indexer_controller.dart';
import 'package:namida/controller/navigator_controller.dart';
import 'package:namida/controller/playlist_controller.dart';
import 'package:namida/controller/search_sort_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/namida_converter_ext.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';

export 'package:dart_extensions/dart_extensions.dart';

extension TracksSelectableUtils on List<Selectable> {
  String get displayTrackKeyword => length.displayTrackKeyword;

  List<String> toImagePaths([int? limit = 4]) => withLimit(limit).map((e) => e.track.pathToImage).toList();
}

extension TracksWithDatesUtils on List<TrackWithDate> {
  int get totalDurationInS => fold(0, (previousValue, element) => previousValue + element.track.duration);
  String get totalDurationFormatted {
    return totalDurationInS.formattedTime;
  }
}

extension TracksUtils on List<Track> {
  String get totalSizeFormatted {
    int size = 0;
    loop((t, index) {
      size += t.size;
    });
    return size.fileSizeFormatted;
  }

  int get totalDurationInS => fold(0, (previousValue, element) => previousValue + element.duration);

  String get totalDurationFormatted {
    return totalDurationInS.formattedTime;
  }

  int get year {
    if (isEmpty) return 0;
    for (int i = length - 1; i >= 0; i--) {
      final y = this[i].year;
      if (y != 0) return y;
    }
    return 0;
  }

  String get yearPreferyyyyMMdd {
    if (isEmpty) return '';
    for (int i = length - 1; i >= 0; i--) {
      final y = this[i].yearPreferyyyyMMdd;
      if (y != '') return y;
    }
    return '';
  }

  /// should be upgraded to check if image file exist, but performance...
  String get pathToImage {
    if (isEmpty) return '';
    return this[indexOfImage].pathToImage;
  }

  Track? get trackOfImage {
    if (isEmpty) return null;
    return this[indexOfImage];
  }

  int get indexOfImage => 0;

  Track get firstTrackWithImage {
    if (isEmpty) return kDummyTrack;
    return this[indexOfImage];
  }

  String get album {
    if (isEmpty) return '';
    for (int i = length - 1; i >= 0; i--) {
      final a = this[i].album;
      if (a != '') return a;
    }
    return '';
  }

  String get albumArtist {
    if (isEmpty) return '';
    for (int i = length - 1; i >= 0; i--) {
      final aa = this[i].albumArtist;
      if (aa != '') return aa;
    }
    return '';
  }

  String get composer {
    if (isEmpty) return '';
    for (int i = length - 1; i >= 0; i--) {
      final aa = this[i].composer;
      if (aa != '') return aa;
    }
    return '';
  }
}

extension StringListJoiner on Iterable<String?> {
  String joinText({String separator = ' • '}) {
    return where((element) => element != null && element != '').join(separator);
  }
}

extension DisplayKeywords on int {
  String get displayTrackKeyword => displayKeyword(lang.TRACK, lang.TRACKS);
  String get displayDayKeyword => displayKeyword(lang.DAY, lang.DAYS);
  String get displayAlbumKeyword => displayKeyword(lang.ALBUM, lang.ALBUMS);
  String get displayArtistKeyword => displayKeyword(lang.ARTIST, lang.ARTISTS);
  String get displayGenreKeyword => displayKeyword(lang.GENRE, lang.GENRES);
  String get displayFolderKeyword => displayKeyword(lang.FOLDER, lang.FOLDERS);
  String get displayPlaylistKeyword => displayKeyword(lang.PLAYLIST, lang.PLAYLISTS);
  String get displayVideoKeyword => displayKeyword(lang.VIDEO, lang.VIDEOS);
}

extension YearDateFormatted on int {
  String get formattedTime => getTimeFormatted(hourChar: 'h', minutesChar: 'min', separator: ' ');

  String get yearFormatted => getYearFormatted(settings.dateTimeFormat.value);

  String get dateFormatted => formatTimeFromMSSE(settings.dateTimeFormat.value);

  String get dateFormattedOriginal {
    final valInSetting = settings.dateTimeFormat.value;
    return getDateFormatted(format: valInSetting.contains('d') ? settings.dateTimeFormat.value : 'dd MMM yyyy');
  }

  String dateFormattedOriginalNoYears(DateTime diffDate) {
    final valInSettingMain = settings.dateTimeFormat.value;
    String valInSettingNew = valInSettingMain.contains('d') ? valInSettingMain : 'dd MMM yyyy';

    bool lessThan1Year(Duration d) => d.inDays.abs() < 364;
    final thisDate = DateTime.fromMillisecondsSinceEpoch(this);
    final diffFromNow = thisDate.difference(DateTime.now());
    final diffDur = thisDate.difference(diffDate);
    if (lessThan1Year(diffDur) && lessThan1Year(diffFromNow)) {
      valInSettingNew = valInSettingNew.replaceAll('y', '').replaceAll('Y', '');
    }
    return getDateFormatted(format: valInSettingNew);
  }

  String get clockFormatted => getClockFormatted(settings.hourFormat12.value);

  /// this one gurantee that the format will return with the day included, even if the format in setting doesnt have day.
  /// if (valInSet.contains('d')) return userformat;
  /// else return dateFormattedOriginal ('dd MMM yyyy');
  String get dateAndClockFormattedOriginal {
    final valInSet = settings.dateTimeFormat.value;
    if (valInSet.contains('d')) {
      return dateAndClockFormatted;
    }
    return [dateFormattedOriginal, clockFormatted].join(' - ');
  }

  String get dateAndClockFormatted => [dateFormatted, clockFormatted].join(' - ');
}

extension BorderRadiusSetting on double {
  double get multipliedRadius {
    return this * settings.borderRadiusMultiplier.value;
  }
}

extension FontScaleSetting on double {
  double get multipliedFontScale {
    return this * settings.fontScaleFactor.value;
  }
}

extension TrackItemSubstring on TrackTileItem {
  String get label => convertToString;
}

extension Channels on String {
  String? get channelToLabel {
    final ch = int.tryParse(this);
    if (ch == 0) {
      return '';
    }
    if (ch == 1) {
      return 'mono';
    }
    if (ch == 2) {
      return 'stereo';
    }
    return this;
  }
}

extension FavouriteTrack on Track {
  bool get isFavourite {
    return PlaylistController.inst.favouritesPlaylist.value.tracks.firstWhereEff((element) => element.track == this) != null;
  }
}

extension PLNAME on String {
  String translatePlaylistName() => replaceFirst(k_PLAYLIST_NAME_AUTO_GENERATED, lang.AUTO_GENERATED)
      .replaceFirst(k_PLAYLIST_NAME_FAV, lang.FAVOURITES)
      .replaceFirst(k_PLAYLIST_NAME_HISTORY, lang.HISTORY)
      .replaceFirst(k_PLAYLIST_NAME_MOST_PLAYED, lang.MOST_PLAYED);
}

extension EnumUtils<E extends Enum> on E {
  E nextElement(List<E> enumsList) {
    final newIndex = (index + 1) % enumsList.length;
    final val = enumsList[newIndex];
    return val;
  }
}

extension TRACKPLAYMODE on TrackPlayMode {
  bool get shouldBeIndex0 => this == TrackPlayMode.selectedTrack || this == TrackPlayMode.trackAlbum || this == TrackPlayMode.trackArtist || this == TrackPlayMode.trackGenre;

  List<Track> getQueue(Track trackPre, {List<Track>? searchQueue}) {
    List<Track> queue = [];
    final track = trackPre.toTrackExt();
    if (this == TrackPlayMode.selectedTrack) {
      queue = [trackPre];
    }
    if (this == TrackPlayMode.searchResults) {
      queue = searchQueue ?? (SearchSortController.inst.trackSearchTemp.isNotEmpty ? SearchSortController.inst.trackSearchTemp : SearchSortController.inst.trackSearchList);
    }
    if (this == TrackPlayMode.trackAlbum) {
      queue = track.albumIdentifier.getAlbumTracks();
    }
    if (this == TrackPlayMode.trackArtist) {
      queue = track.artistsList.first.getArtistTracks();
    }
    if (this == TrackPlayMode.trackGenre) {
      queue = track.artistsList.first.getGenresTracks();
    }
    if (shouldBeIndex0) {
      queue.remove(trackPre);
      queue.insertSafe(0, trackPre);
    }
    return queue;
  }
}

extension ConvertPathToTrack on String {
  Future<TrackExtended?> removeTrackThenExtract({bool onlyIfNewFileExists = true}) async {
    if (onlyIfNewFileExists && !await File(this).exists()) return null;
    Indexer.inst.allTracksMappedByPath.remove(Track(this));
    return (await Indexer.inst.extractTracksInfo(tracksPath: [this]))[this];
  }

  Future<TrackExtended?> toTrackExtOrExtract() async => toTrackExtOrNull() ?? (await Indexer.inst.extractTracksInfo(tracksPath: [this]))[this];
  Track toTrack() => Track(this);
  Track? toTrackOrNull() => Indexer.inst.allTracksMappedByPath[toTrack()] == null ? null : toTrack();
  TrackExtended? toTrackExtOrNull() => Indexer.inst.allTracksMappedByPath[Track(this)];

  TrackExtended toTrackExt() {
    return toTrackExtOrNull() ?? kDummyExtendedTrack.copyWith(title: getFilenameWOExt, path: this);
  }
}

extension YTLinkToID on String {
  String get getYoutubeID {
    final regex = RegExp(r'((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?', caseSensitive: false);
    final match = regex.firstMatch(this);
    final idAndMore = match?.group(5);
    final id = idAndMore?.length == 11 ? idAndMore : null;
    return id ?? '';
  }
}

extension TitleAndArtistUtils on String {
  /// (artist, title)
  (String?, String?) splitArtistAndTitle() {
    final input = this;
    if (input == '') return (null, null);
    final regexCareForSpaces = RegExp(
      r'^(.*?)(?:\s+-\s+|\s+\|\s+|\s+by\s+|\s+["「]|-\||-\s+|」)(.*?)(?:"|」)?$',
      caseSensitive: false,
    );
    final match2 = regexCareForSpaces.firstMatch(input);
    if (match2 != null) {
      final artist = match2.group(1)?.trim();
      final title = match2.group(2)?.trim();
      if (artist != null && title != null) {
        final a = artist.startsWith('「') ? artist.replaceRange(0, 1, '') : artist;
        return (a, title);
      }
    }
    // final regexDoesntCareAboutSpaces = RegExp(
    //   r'^(.*?)(?:\s?-\s?|\s?\|\s?|\s?by\s|\s?["「])(.*?)(?:"|」)?$',
    //   caseSensitive: false,
    // );
    // final match = regexDoesntCareAboutSpaces.firstMatch(input);
    // if (match != null) {
    //   final artist = match.group(1)?.trim();
    //   final title = match.group(2)?.trim();
    //   if (artist != null && title != null) {
    //     final a = artist.startsWith('「') ? artist.replaceRange(0, 1, '') : artist;
    //     return (a, title);
    //   }
    // }
    return (null, null);
  }

  String keepFeatKeywordsOnly() {
    if (this == '') return '';
    final regex = RegExp(
      r'\s*\((?!remix|featured|ft\.|feat\.|featuring)(?!.*Remix)[^)]*\)|\s*\[(?!remix|featured|ft\.|feat\.|featuring)(?!.*Remix)[^\]]*\]',
      caseSensitive: false,
    );
    String res = replaceAll(regex, '').trimAll();
    while (res.trim().endsWith(' -')) {
      res = res.substring(0, res.length - 2);
    }
    return res.trim();
  }
}

extension TagFieldsUtils on TagField {
  bool get isNumeric => this == TagField.trackNumber || this == TagField.trackTotal || this == TagField.discNumber || this == TagField.discTotal || this == TagField.year;
}

extension WidgetsUtils on Widget {
  Widget animateEntrance({
    required bool showWhen,
    int durationMS = 400,
    int? reverseDurationMS,
    Curve firstCurve = Curves.linear,
    Curve secondCurve = Curves.linear,
    Curve sizeCurve = Curves.linear,
    Curve? allCurves,
  }) {
    return NamidaAnimatedSwitcher(
      firstChild: this,
      secondChild: const SizedBox(),
      showFirst: showWhen,
      durationMS: durationMS,
      reverseDurationMS: reverseDurationMS,
      firstCurve: firstCurve,
      secondCurve: secondCurve,
      sizeCurve: sizeCurve,
      allCurves: allCurves,
    );
  }

  Widget toSliver() => SliverToBoxAdapter(child: this);
}

extension CloseDialogIfTrueFuture on FutureOr<bool> {
  /// Closes dialog if [this == true].
  ///
  /// This is mainly created for [addToQueue] Function inside Player Class,
  /// where it should close the dialog only if there were tracks added.
  void closeDialog([int count = 1]) async {
    final res = await this;
    res.executeIfTrue(() => NamidaNavigator.inst.closeDialog(count));
  }
}

extension ThreadOpener<M, R> on ComputeCallback<M, R> {
  /// Executes function on a separate thread using compute().
  /// Must be `static` or `global` function.
  Future<R> thready(M parameter) async {
    WidgetsFlutterBinding.ensureInitialized();
    return await compute(this, parameter);
  }
}

extension FunctionsExecuter<T> on Iterable<Future<T>?> {
  Future<List<T>> execute() async {
    return await Future.wait(whereType<Future<T>>());
  }
}

extension FileUtils on File {
  int? fileSizeSync() {
    try {
      return lengthSync();
    } catch (e) {
      return null;
    }
  }

  String? fileSizeFormatted() {
    return fileSizeSync()?.fileSizeFormatted;
  }
}

extension FileStatsUtils on FileStat {
  DateTime get creationDate {
    DateTime lowest = modified;

    bool validateLower(DateTime date) {
      return changed != DateTime(1970) && (lowest == DateTime(1970) || date.microsecondsSinceEpoch < lowest.microsecondsSinceEpoch);
    }

    if (validateLower(changed)) lowest = changed;

    if (validateLower(accessed)) lowest = accessed;

    return lowest;
  }
}

extension CompleterCompleter<T> on Completer<T>? {
  void completeIfWasnt([FutureOr<T>? value]) async {
    final c = this;
    if (c?.isCompleted == false) c?.complete(value);
  }

  void completeErrorIfWasnt(Object error, [StackTrace? stackTrace]) async {
    final c = this;
    if (c?.isCompleted == false) c?.completeError(error, stackTrace);
  }
}

extension ScrollerPerf on ScrollController {
  /// Animates a scrollview to a certain [offset] after jumping closer for faster performance
  ///
  /// The final distance to animate is defined by [jumpitator]
  Future<void> animateToEff(
    double offset, {
    required Duration duration,
    required Curve curve,
    final double jumpitator = 800.0,
  }) async {
    final diff = offset - this.offset;

    if (diff > jumpitator) {
      // -- is now above the target, so we jump offset-jumpitator
      jumpTo(offset - jumpitator);
    } else if (diff < -jumpitator) {
      // -- is now under the target, so we jump offset+jumpitator
      jumpTo(offset + jumpitator);
    }
    await animateTo(offset, duration: duration, curve: curve);
  }
}

extension NavigatorUtils on BuildContext? {
  void safePop({bool rootNavigator = false}) {
    final context = this;
    if (context != null && context.mounted) Navigator.of(context, rootNavigator: rootNavigator).maybePop();
  }
}

extension DisposingUtils on TextEditingController {
  Future<void> disposeAfterAnimation({int durationMS = 200, void Function()? also}) async {
    void fn() {
      dispose();
      if (also != null) also();
    }

    await fn.executeDelayed(Duration(milliseconds: durationMS));
  }
}

extension ExecuteDelayedUtils<T> on T Function() {
  Future<T> executeDelayed(Duration dur) async {
    return await Future.delayed(dur, this);
  }
}

extension RxStreamClosing<T> on Rx<T> {
  Future<void> closeAfterDelay({int durationMS = 500}) async {
    return await Future.delayed(Duration(milliseconds: durationMS), close);
  }
}
