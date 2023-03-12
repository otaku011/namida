import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:on_audio_edit/on_audio_edit.dart' as audioedit;

import 'package:namida/class/track.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';

class Indexer extends GetxController {
  static final Indexer inst = Indexer();

  RxBool isIndexing = false.obs;

  RxInt allTracksPaths = 0.obs;
  RxList<FileSystemEntity> tracksFileSystemEntity = <FileSystemEntity>[].obs;
  RxInt filteredForSizeDurationTracks = 0.obs;
  RxInt duplicatedTracksLength = 0.obs;
  Set<String> filteredPathsToBeDeleted = {};

  RxInt artworksInStorage = Directory(kArtworksDirPath).listSync().length.obs;
  RxInt waveformsInStorage = Directory(kWaveformDirPath).listSync().length.obs;
  RxInt colorPalettesInStorage = Directory(kPaletteDirPath).listSync().length.obs;
  RxInt videosInStorage = Directory(kWaveformDirPath).listSync().length.obs;

  RxInt artworksSizeInStorage = 0.obs;
  RxInt waveformsSizeInStorage = 0.obs;
  RxInt videosSizeInStorage = 0.obs;

  Rx<TextEditingController> globalSearchController = TextEditingController().obs;
  Rx<TextEditingController> tracksSearchController = TextEditingController().obs;
  Rx<TextEditingController> albumsSearchController = TextEditingController().obs;
  Rx<TextEditingController> artistsSearchController = TextEditingController().obs;
  Rx<TextEditingController> genresSearchController = TextEditingController().obs;
  // Rx<TextEditingController> foldersSearchController = TextEditingController().obs;

  RxList<Track> tracksInfoList = <Track>[].obs;
  RxMap<String, Set<Track>> albumsMap = <String, Set<Track>>{}.obs;
  RxMap<String, Set<Track>> groupedArtistsMap = <String, Set<Track>>{}.obs;
  RxMap<String, Set<Track>> groupedGenresMap = <String, Set<Track>>{}.obs;
  RxMap<String, List<Track>> groupedFoldersMap = <String, List<Track>>{}.obs;

  RxList<Track> trackSearchList = <Track>[].obs;
  RxMap<String, Set<Track>> albumSearchList = <String, Set<Track>>{}.obs;
  RxMap<String, Set<Track>> artistSearchList = <String, Set<Track>>{}.obs;
  RxMap<String, Set<Track>> genreSearchList = <String, Set<Track>>{}.obs;
  // RxMap<String, List<Track>> foldersSearchList = <String, List<Track>>{}.obs;

  final OnAudioQuery _query = OnAudioQuery();
  final onAudioEdit = audioedit.OnAudioEdit();

  Future<void> prepareTracksFile() async {
    /// Only awaits if the track file exists, otherwise it will get into normally and start indexing.
    if (await File(kTracksFilePath).exists() && await File(kTracksFilePath).stat().then((value) => value.size > 8)) {
      await readTrackData();
      afterIndexing();
    }

    /// doesnt exists
    else {
      await File(kTracksFilePath).create();
      refreshLibraryAndCheckForDiff(forceReIndex: true);
    }
  }

  Future<void> refreshLibraryAndCheckForDiff({bool forceReIndex = false}) async {
    isIndexing.value = true;
    final files = await getAudioFiles();

    Set<String> newFoundPaths = files.difference(Set.of(tracksInfoList.map((t) => t.path)));
    Set<String> deletedPaths = Set.of(tracksInfoList.map((t) => t.path)).difference(files);

    await fetchAllSongsAndWriteToFile(audioFiles: newFoundPaths, deletedPaths: deletedPaths, forceReIndex: forceReIndex || tracksInfoList.isEmpty);
    afterIndexing();
    isIndexing.value = false;
  }

  void afterIndexing() {
    albumsMap.clear();
    groupedArtistsMap.clear();
    groupedGenresMap.clear();
    groupedFoldersMap.clear();
    for (Track track in tracksInfoList) {
      albumsMap.putIfAbsent(track.album, () => {}).addIf(() {
        /// a check to not add tracks with the same filename to the album
        return !(albumsMap[track.album] ?? {}).map((e) => e.displayName).contains(track.displayName);
      }, track);
    }
    for (Track map in tracksInfoList) {
      for (var artist in map.artistsList) {
        groupedArtistsMap.putIfAbsent(artist, () => {}).addIf(() {
          return !(groupedArtistsMap[artist] ?? {}).map((e) => e.displayName).contains(map.displayName);
        }, map);
      }
    }

    for (Track map in tracksInfoList) {
      for (var genre in map.genresList) {
        groupedGenresMap.putIfAbsent(genre, () => {}).addIf(() {
          return !(groupedGenresMap[genre] ?? {}).map((e) => e.displayName).contains(map.displayName);
        }, map);
      }
    }

    groupedFoldersMap.assignAll(tracksInfoList.groupBy((p0) => p0.folderPath));

    sortTracks();
    sortAlbums();
    sortArtists();
    sortGenres();
  }

  /// extracts artwork from [bytes] or [path] and save to file.
  /// path is needed bothways for making the file name.
  /// using path for extracting will call [onAudioEdit.readAudio] so it will be slower.
  Future<void> extractOneArtwork(String path, {Uint8List? bytes, bool forceReExtract = false}) async {
    final fileOfFull = File("$kArtworksDirPath${path.getFilename}.png");

    if (forceReExtract) {
      await fileOfFull.delete();
    }

    /// prevent redundent re-creation of image file
    if (!await fileOfFull.exists()) {
      final art = bytes ?? await onAudioEdit.readAudio(path).then((value) => value.firstArtwork);
      if (art != null) {
        final imgFile = await fileOfFull.create(recursive: true);
        imgFile.writeAsBytesSync(art);
      }
    }

    updateImageSizeInStorage();
  }

  Future<void> updateTracks(List<Track> tracks, {bool updateArtwork = false}) async {
    for (final track in tracks) {
      if (updateArtwork) {
        await extractOneArtwork(track.path, forceReExtract: true);
      }
      await fetchAllSongsAndWriteToFile(audioFiles: {}, deletedPaths: {track.path}, forceReIndex: false);
      await fetchAllSongsAndWriteToFile(audioFiles: {track.path}, deletedPaths: {}, forceReIndex: false);
      if (updateArtwork) {
        await extractOneArtwork(track.path, forceReExtract: true);
      }
    }

    afterIndexing();
  }

  Map<String?, Set<Track>> getAlbumsForArtist(String artist) {
    Map<String?, Set<Track>> trackAlbumsMap = {};
    for (Track track in tracksInfoList) {
      if (track.artistsList.contains(artist)) {
        trackAlbumsMap.putIfAbsent(track.album, () => {}).addIf(() {
          /// a check to not add tracks with the same filename to the album
          return !(trackAlbumsMap[track.album] ?? {}).map((e) => e.displayName).contains(track.displayName);
        }, track);
      }
    }
    return trackAlbumsMap;
  }

  Future<void> fetchAllSongsAndWriteToFile({required Set<String> audioFiles, required Set<String> deletedPaths, bool forceReIndex = true}) async {
    if (forceReIndex) {
      print(tracksInfoList.length);
      tracksInfoList.clear();
      audioFiles = await getAudioFiles();
    } else {
      audioFiles = audioFiles;
    }
    debugPrint("New Audio Files: ${audioFiles.length}");
    debugPrint("Deleted Audio Files: ${deletedPaths.length}");

    List<SongModel> tracksOld = await _query.querySongs();
    filteredForSizeDurationTracks.value = 0;
    duplicatedTracksLength.value = 0;
    final minDur = SettingsController.inst.indexMinDurationInSec.value; // Seconds
    final minSize = SettingsController.inst.indexMinFileSizeInB.value; // bytes

    Future<void> extractAllMetadata() async {
      Set<String> listOfCurrentFileNames = <String>{};
      for (var track in audioFiles) {
        print(track);
        try {
          final trackInfo = await onAudioEdit.readAudio(track);

          /// skip duplicated tracks according to filename
          if (SettingsController.inst.preventDuplicatedTracks.value && listOfCurrentFileNames.contains(track.getFilename)) {
            duplicatedTracksLength.value++;
            continue;
          }

          /// Since duration & dateAdded can't be accessed using [onAudioEdit] (jaudiotagger), im using [onAudioQuery] to access it
          int? duration;
          // int? dateAdded;
          for (var h in tracksOld) {
            if (h.data == track) {
              duration = h.duration;
              // dateAdded = h.dateAdded;
            }
          }
          final fileStat = await File(track).stat();

          // breaks the loop early depending on size [byte] or duration [seconds]
          if ((duration ?? 0) < minDur * 1000 || fileStat.size < minSize) {
            filteredForSizeDurationTracks++;
            filteredPathsToBeDeleted.add(track);
            deletedPaths.add(track);
            continue;
          }

          /// Split Artists
          final List<String> _artistsListfinal = <String>[];
          List<String> _artistsListPre = trackInfo.artist?.trim().multiSplit(SettingsController.inst.trackArtistsSeparators.toList()) ?? ['Unkown Artist'];
          for (var element in _artistsListPre) {
            _artistsListfinal.add(element.trim());
          }

          /// Split Genres
          final List<String> _genresListfinal = <String>[];
          List<String> _genresListPre = trackInfo.genre?.trim().multiSplit(SettingsController.inst.trackGenresSeparators.toList()) ?? ['Unkown Genre'];
          for (var element in _genresListPre) {
            _genresListfinal.add(element.trim());
          }

          Track newTrackEntry = Track(
            trackInfo.title ?? '',
            _artistsListfinal,
            trackInfo.album ?? 'Unknown Album',
            trackInfo.albumArtist ?? '',
            _genresListfinal,
            trackInfo.composer ?? 'Unknown Composer',
            trackInfo.track ?? 0,
            duration ?? 0,
            trackInfo.year ?? 0,
            fileStat.size,
            //TODO: REMOVE CREATION DATE
            fileStat.accessed.millisecondsSinceEpoch,
            fileStat.changed.millisecondsSinceEpoch,
            track,
            "$kArtworksDirPath${track.getFilename}.png",
            track.getDirectoryName,
            track.getFilename,
            track.getFilenameWOExt,
            track.getExtension,
            trackInfo.getMap['COMMENT'] ?? '',
            trackInfo.bitrate ?? 0,
            trackInfo.sampleRate ?? 0,
            trackInfo.format ?? '',
            trackInfo.channels ?? '',
            trackInfo.discNo ?? 0,
            trackInfo.language ?? '',
            trackInfo.lyricist ?? '',
            trackInfo.mood ?? '',
            trackInfo.tags ?? '',
          );
          tracksInfoList.add(newTrackEntry);
          print(tracksInfoList.length);

          listOfCurrentFileNames.add(track.getFilename);
          searchTracks('');
          extractOneArtwork(track, bytes: trackInfo.firstArtwork);
        } catch (e) {
          printError(info: e.toString());

          /// TODO: Should i add a dummy track that has a real path?
          // final fileStat = await File(track).stat();
          // tracksInfoList.add(Track(p.basenameWithoutExtension(track), ['Unkown Artist'], 'Unkown Album', 'Unkown Album Artist', ['Unkown Genre'], 'Unknown Composer', 0, 0, 0, fileStat.size, fileStat.accessed.millisecondsSinceEpoch, fileStat.changed.millisecondsSinceEpoch, track,
          //     "$kAppDirectoryPath/Artworks/${p.basename(track)}.png", p.dirname(track), p.basename(track), p.basenameWithoutExtension(track), p.extension(track).substring(1), '', 0, 0, '', '', 0, '', '', '', ''));

          continue;
        }
      }
      debugPrint('Extracted All Metadata');
    }

    Future<void> extractAllArtworks() async {
      for (var track in audioFiles) {
        printInfo(info: track);
        try {
          await extractOneArtwork(track);
        } catch (e) {
          printError(info: e.toString());
          continue;
        }
      }
      printInfo(info: 'Extracted All Artworks Successfully');
    }

    if (deletedPaths.isEmpty) {
      await Future.wait([
        extractAllMetadata(),
        // extractAllArtworks(),
      ]);
    } else {
      for (var p in deletedPaths) {
        tracksInfoList.removeWhere((track) => track.path == p);
      }
    }

    /// removes tracks after increasing duration
    tracksInfoList.removeWhere(
      (tr) => tr.duration < minDur * 1000 || tr.size < minSize,
    );

    /// removes duplicated tracks after a refresh
    if (SettingsController.inst.preventDuplicatedTracks.value) {
      Set<String> listOfCurrentFileNames = <String>{};
      var listOfTracksWithoutDuplicates = <Track>[];
      for (var tr in tracksInfoList) {
        if (!listOfCurrentFileNames.contains(tr.displayName)) {
          listOfTracksWithoutDuplicates.add(tr);
          listOfCurrentFileNames.add(tr.displayName);
        } else {
          duplicatedTracksLength.value++;
        }
      }
      tracksInfoList.assignAll(listOfTracksWithoutDuplicates);
    }

    printInfo(info: "FINAL: ${tracksInfoList.length}");

    tracksInfoList.map((track) => track.toJson()).toList();
    File(kTracksFilePath).writeAsStringSync(json.encode(tracksInfoList));
  }

  Future<void> readTrackData({File? file}) async {
    file ??= File(kTracksFilePath);
    String contents = await file.readAsString();
    if (contents.isNotEmpty) {
      var jsonResponse = jsonDecode(contents);

      for (var p in jsonResponse) {
        tracksInfoList.add(Track.fromJson(p));
        debugPrint("Tracks Info List Length From File: ${tracksInfoList.length}");
      }
    }
  }

  Future<Set<String>> getAudioFiles() async {
    final allPaths = <String>{};
    tracksFileSystemEntity.clear();
    for (final path in SettingsController.inst.directoriesToScan.toList()) {
      if (await Directory(path).exists()) {
        final directory = Directory(path);
        final filesPre = directory.listSync(recursive: true, followLinks: true);

        /// Respects .nomedia
        /// Typically Skips a directory if a .nomedia file was detected
        if (SettingsController.inst.respectNoMedia.value) {
          final basenames = <String>[];
          for (final b in filesPre) {
            basenames.add(b.path.split('/').last);
            printInfo(info: b.path.split('/').last);
          }
          if (basenames.contains('nomedia')) {
            printInfo(info: '.nomedia skipped');
            continue;
          }
        }

        for (final file in filesPre) {
          try {
            if (file is File) {
              for (final extension in kFileExtensions) {
                if (file.path.endsWith(extension)) {
                  // Checks if the file is not included in one of the excluded folders.
                  if (!SettingsController.inst.directoriesToExclude.toList().any((exc) => file.path.startsWith(exc))) {
                    // tracksFileSystemEntity.add(file);
                    allPaths.add(file.path);
                  }

                  break;
                }
              }
            }
            if (file is Directory) {
              if (!SettingsController.inst.directoriesToExclude.toList().any((exc) => file.path.startsWith(exc))) {
                tracksFileSystemEntity.add(file);
                print("Added $file");
                print("Added ${tracksFileSystemEntity.length}");
              }
            }
          } catch (e) {
            printError(info: e.toString());
            continue;
          }
        }
      }
      allTracksPaths.value = allPaths.length;
      print(allPaths.length);
    }
    return allPaths;
  }

  void searchAll(String text) {
    searchTracks(text);
    searchAlbums(text);
    searchArtists(text);
  }

  void searchTracks(String text) {
    if (text == '') {
      tracksSearchController.value.clear();
      trackSearchList.assignAll(tracksInfoList);
      return;
    }

    final tsf = SettingsController.inst.trackSearchFilter;
    final sTitle = tsf.contains('title');
    final sAlbum = tsf.contains('album');
    final sAlbumArtist = tsf.contains('albumartist');
    final sArtist = tsf.contains('artist');
    final sGenre = tsf.contains('genre');
    final sComposer = tsf.contains('composer');
    final sYear = tsf.contains('year');

    trackSearchList.clear();
    for (var item in tracksInfoList) {
      final lctext = text.toLowerCase();

      if ((sTitle && item.title.toLowerCase().contains(lctext)) ||
          (sAlbum && item.album.toLowerCase().contains(lctext)) ||
          (sAlbumArtist && item.albumArtist.toLowerCase().contains(lctext)) ||
          (sArtist && item.artistsList.any((element) => element.toLowerCase().contains(lctext))) ||
          (sGenre && item.genresList.any((element) => element.toLowerCase().contains(lctext))) ||
          (sComposer && item.composer.toLowerCase().contains(lctext)) ||
          (sYear && item.year.toString().contains(lctext))) {
        trackSearchList.add(item);
      }

      print(item.title);
    }
    print(trackSearchList.length);
    // sortTracks();
  }

  void searchAlbums(String text) {
    if (text == '') {
      albumsSearchController.value.clear();
      albumSearchList.assignAll(albumsMap);
      return;
    }
    Map<String, Set<Track>> newMap = <String, Set<Track>>{};
    for (var album in albumsMap.entries) {
      newMap.addAllIf(album.key.toLowerCase().contains(text.toLowerCase()), {album.key: album.value});
    }
    albumSearchList.assignAll(newMap);
  }

  void searchArtists(String text) {
    if (text == '') {
      artistsSearchController.value.clear();
      artistSearchList.assignAll(groupedArtistsMap);
      return;
    }
    Map<String, Set<Track>> newMap = <String, Set<Track>>{};
    for (var artist in groupedArtistsMap.entries) {
      newMap.addAllIf(artist.key.toLowerCase().contains(text.toLowerCase()), {artist.key: artist.value});
    }
    artistSearchList.assignAll(newMap);
  }

  void searchGenres(String text) {
    if (text == '') {
      genresSearchController.value.clear();
      genreSearchList.assignAll(groupedGenresMap);
      return;
    }

    Map<String, Set<Track>> newMap = <String, Set<Track>>{};
    for (var genre in groupedGenresMap.entries) {
      newMap.addAllIf(genre.key.toLowerCase().contains(text.toLowerCase()), {genre.key: genre.value});
    }
    genreSearchList.assignAll(newMap);
  }

  /// Sorts Tracks and Saves automatically to settings
  void sortTracks({SortType? sortBy, bool? reverse}) {
    sortBy ??= SettingsController.inst.tracksSort.value;
    reverse ??= SettingsController.inst.tracksSortReversed.value;
    switch (sortBy) {
      case SortType.title:
        tracksInfoList.sort((a, b) => (a.title).compareTo(b.title));
        break;
      case SortType.album:
        tracksInfoList.sort((a, b) => (a.album).compareTo(b.album));
        break;
      case SortType.albumArtist:
        tracksInfoList.sort((a, b) => (a.albumArtist).compareTo(b.albumArtist));
        break;
      case SortType.year:
        tracksInfoList.sort((a, b) => (a.year).compareTo(b.year));
        break;
      case SortType.artistsList:
        tracksInfoList.sort((a, b) => (a.artistsList.toString()).compareTo(b.artistsList.toString()));
        break;
      case SortType.genresList:
        tracksInfoList.sort((a, b) => (a.genresList.toString()).compareTo(b.genresList.toString()));
        break;
      case SortType.dateAdded:
        tracksInfoList.sort((a, b) => (a.dateAdded).compareTo(b.dateAdded));
        break;
      case SortType.dateModified:
        tracksInfoList.sort((a, b) => (a.dateModified).compareTo(b.dateModified));
        break;
      case SortType.bitrate:
        tracksInfoList.sort((a, b) => (a.bitrate).compareTo(b.bitrate));
        break;
      case SortType.composer:
        tracksInfoList.sort((a, b) => (a.composer).compareTo(b.composer));
        break;
      case SortType.discNo:
        tracksInfoList.sort((a, b) => (a.discNo).compareTo(b.discNo));
        break;
      case SortType.displayName:
        tracksInfoList.sort((a, b) => (a.displayName).compareTo(b.displayName));
        break;
      case SortType.duration:
        tracksInfoList.sort((a, b) => (a.duration).compareTo(b.duration));
        break;
      case SortType.sampleRate:
        tracksInfoList.sort((a, b) => (a.sampleRate).compareTo(b.sampleRate));
        break;
      case SortType.size:
        tracksInfoList.sort((a, b) => (a.size).compareTo(b.size));
        break;

      default:
        null;
    }

    if (reverse) {
      tracksInfoList.value = tracksInfoList.reversed.toList();
    }
    SettingsController.inst.save(tracksSort: sortBy, tracksSortReversed: reverse);
    searchTracks(tracksSearchController.value.text);
  }

  /// Sorts Albums and Saves automatically to settings
  void sortAlbums({GroupSortType? sortBy, bool? reverse}) {
    sortBy ??= SettingsController.inst.albumSort.value;
    reverse ??= SettingsController.inst.albumSortReversed.value;
    var mapEntries = albumsMap.entries.toList();
    switch (sortBy) {
      case GroupSortType.album:
        mapEntries.sort((a, b) => a.value.first.album.compareTo(b.value.first.album));
        break;
      case GroupSortType.albumArtist:
        mapEntries.sort((a, b) => a.value.first.albumArtist.compareTo(b.value.first.albumArtist));
        break;
      case GroupSortType.year:
        mapEntries.sort((a, b) => a.value.first.year.compareTo(b.value.first.year));
        break;
      case GroupSortType.artistsList:
        mapEntries.sort((a, b) => a.value.first.artistsList.toString().compareTo(b.value.first.artistsList.toString()));
        break;

      case GroupSortType.composer:
        mapEntries.sort((a, b) => a.value.first.composer.compareTo(b.value.first.composer));
        break;
      case GroupSortType.dateModified:
        mapEntries.sort((a, b) => a.value.first.dateModified.compareTo(b.value.first.dateModified));
        break;
      case GroupSortType.duration:
        mapEntries.sort((a, b) => a.value.toList().totalDuration.compareTo(b.value.toList().totalDuration));
        break;
      case GroupSortType.numberOfTracks:
        mapEntries.sort((a, b) => a.value.length.compareTo(b.value.length));
        break;

      default:
        null;
    }

    if (reverse) {
      albumsMap.value = Map.fromEntries(mapEntries.reversed);
    } else {
      albumsMap.value = Map.fromEntries(mapEntries);
    }

    SettingsController.inst.save(albumSort: sortBy, albumSortReversed: reverse);

    searchAlbums(albumsSearchController.value.text);
  }

  /// Sorts Artists and Saves automatically to settings
  void sortArtists({GroupSortType? sortBy, bool? reverse}) {
    sortBy ??= SettingsController.inst.artistSort.value;
    reverse ??= SettingsController.inst.artistSortReversed.value;
    var mapEntries = groupedArtistsMap.entries.toList();
    switch (sortBy) {
      case GroupSortType.album:
        mapEntries.sort((a, b) => a.value.elementAt(0).album.compareTo(b.value.elementAt(0).album));
        break;
      case GroupSortType.albumArtist:
        mapEntries.sort((a, b) => a.value.elementAt(0).albumArtist.compareTo(b.value.elementAt(0).albumArtist));
        break;
      case GroupSortType.year:
        mapEntries.sort((a, b) => a.value.elementAt(0).year.compareTo(b.value.elementAt(0).year));
        break;
      case GroupSortType.artistsList:
        // mapEntries.sort((a, b) => a.value.elementAt(0).artistsList.toString().compareTo(b.value.elementAt(0).artistsList.toString()));
        mapEntries.sort(((a, b) => a.key.compareTo(b.key)));
        break;
      case GroupSortType.genresList:
        mapEntries.sort((a, b) => a.value.elementAt(0).genresList.toString().compareTo(b.value.elementAt(0).genresList.toString()));
        break;
      case GroupSortType.composer:
        mapEntries.sort((a, b) => a.value.elementAt(0).composer.compareTo(b.value.elementAt(0).composer));
        break;
      case GroupSortType.dateModified:
        mapEntries.sort((a, b) => a.value.elementAt(0).dateModified.compareTo(b.value.elementAt(0).dateModified));
        break;
      case GroupSortType.duration:
        mapEntries.sort((a, b) => a.value.toList().totalDuration.compareTo(b.value.toList().totalDuration));
        break;
      case GroupSortType.numberOfTracks:
        mapEntries.sort((a, b) => a.value.length.compareTo(b.value.length));
        break;
      default:
        null;
    }

    if (reverse) {
      groupedArtistsMap.assignAll(Map.fromEntries(mapEntries.reversed));
    } else {
      groupedArtistsMap.assignAll(Map.fromEntries(mapEntries));
    }

    SettingsController.inst.save(artistSort: sortBy, artistSortReversed: reverse);

    searchArtists(artistsSearchController.value.text);
  }

  /// Sorts Genres and Saves automatically to settings
  void sortGenres({GroupSortType? sortBy, bool? reverse}) {
    sortBy ??= SettingsController.inst.genreSort.value;
    reverse ??= SettingsController.inst.genreSortReversed.value;
    var mapEntries = groupedGenresMap.entries.toList();
    switch (sortBy) {
      case GroupSortType.album:
        mapEntries.sort((a, b) => a.value.elementAt(0).album.compareTo(b.value.elementAt(0).album));
        break;
      case GroupSortType.albumArtist:
        mapEntries.sort((a, b) => a.value.elementAt(0).albumArtist.compareTo(b.value.elementAt(0).albumArtist));
        break;
      case GroupSortType.year:
        mapEntries.sort((a, b) => a.value.elementAt(0).year.compareTo(b.value.elementAt(0).year));
        break;
      case GroupSortType.artistsList:
        mapEntries.sort((a, b) => a.value.elementAt(0).artistsList.toString().compareTo(b.value.elementAt(0).artistsList.toString()));
        break;
      case GroupSortType.genresList:
        // mapEntries.sort((a, b) => a.value.elementAt(0).genresList.toString().compareTo(b.value.elementAt(0).genresList.toString()));
        mapEntries.sort(((a, b) => a.key.compareTo(b.key)));
        break;
      case GroupSortType.composer:
        mapEntries.sort((a, b) => a.value.elementAt(0).composer.compareTo(b.value.elementAt(0).composer));
        break;
      case GroupSortType.dateModified:
        mapEntries.sort((a, b) => a.value.elementAt(0).dateModified.compareTo(b.value.elementAt(0).dateModified));
        break;
      case GroupSortType.duration:
        mapEntries.sort((a, b) => a.value.toList().totalDuration.compareTo(b.value.toList().totalDuration));
        break;
      case GroupSortType.numberOfTracks:
        mapEntries.sort((a, b) => a.value.length.compareTo(b.value.length));
        break;

      default:
        null;
    }

    if (reverse) {
      groupedGenresMap.value = Map.fromEntries(mapEntries.reversed);
    } else {
      groupedGenresMap.value = Map.fromEntries(mapEntries);
    }

    SettingsController.inst.save(genreSort: sortBy, genreSortReversed: reverse);
    searchGenres(genresSearchController.value.text);
  }

  void updateImageSizeInStorage() {
    // resets values
    artworksInStorage.value = 0;
    artworksSizeInStorage.value = 0;

    Directory(kArtworksDirPath).listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
      if (entity is File) {
        artworksInStorage.value++;
        artworksSizeInStorage.value += entity.lengthSync();
      }
    });
  }

  void updateWaveformSizeInStorage() {
    // resets values
    waveformsInStorage.value = 0;
    waveformsSizeInStorage.value = 0;

    Directory(kWaveformDirPath).listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
      if (entity is File) {
        waveformsInStorage.value++;
        waveformsSizeInStorage.value += entity.lengthSync();
      }
    });
  }

  void updateColorPalettesSizeInStorage() {
    // resets values
    colorPalettesInStorage.value = 0;

    Directory(kPaletteDirPath).listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
      if (entity is File) {
        colorPalettesInStorage.value++;
      }
    });
  }

  void updateVideosSizeInStorage() {
    // resets values
    videosInStorage.value = 0;
    videosSizeInStorage.value = 0;

    Directory(kVideosCachePath).listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
      if (entity is File) {
        videosInStorage.value++;
        videosSizeInStorage.value += entity.lengthSync();
      }
    });
  }

  Future<void> clearImageCache() async {
    await Directory(kArtworksDirPath).delete(recursive: true);
    await Directory(kArtworksDirPath).create();
    updateImageSizeInStorage();
  }

  Future<void> clearWaveformData() async {
    await Directory(kWaveformDirPath).delete(recursive: true);
    await Directory(kWaveformDirPath).create();
    updateWaveformSizeInStorage();
  }

  Future<void> clearVideoCache() async {
    await Directory(kVideosCachePath).delete(recursive: true);
    await Directory(kVideosCachePath).create();
    updateVideosSizeInStorage();
  }

  @override
  void onClose() {
    Get.delete();
    super.onClose();
  }
}
