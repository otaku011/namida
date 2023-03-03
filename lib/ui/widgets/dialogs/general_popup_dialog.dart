import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:namida/controller/indexer_controller.dart';
import 'package:namida/controller/playlist_controller.dart';

import 'package:namida/controller/video_controller.dart';
import 'package:namida/ui/pages/subpages/album_tracks_subpage.dart';
import 'package:namida/ui/pages/subpages/artist_tracks_subpage.dart';
import 'package:namida/ui/widgets/dialogs/add_to_playlist_dialog.dart';
import 'package:namida/class/playlist.dart';
import 'package:namida/class/track.dart';
import 'package:namida/controller/current_color.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/translations/strings.dart';
import 'package:namida/ui/widgets/artwork.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/ui/widgets/dialogs/edit_tags_dialog.dart';
import 'package:namida/ui/widgets/dialogs/track_clear_dialog.dart';
import 'package:namida/ui/widgets/library/multi_artwork_container.dart';

Future<void> showGeneralPopupDialog(
  List<Track> tracks,
  String title,
  String subtitle, {
  void Function()? onTopBarTap,
  Playlist? playlist,
  String thirdLineText = '',
  bool forceSquared = false,
  bool? forceSingleArtwork,
  bool isTrackInPlaylist = false,
  bool extractColor = true,
}) async {
  // just in case a smart user pressed when selected tracks list is empty
  // if (tracks.isEmpty) {
  //   return;
  // }
  forceSingleArtwork ??= tracks.length == 1;
  final isSingle = tracks.length == 1;

  final colorDelightened = await generateDelightnedColor(extractColor ? tracks.first : null);

  final List<String> availableAlbums = tracks.map((e) => e.album).toSet().toList();
  final List<String> availableArtists = tracks.map((e) => e.artistsList).expand((list) => list).toSet().toList();

  await Get.dialog(
    BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 34.0, vertical: 24.0),
        clipBehavior: Clip.antiAlias,
        backgroundColor: Color.alphaBlend(colorDelightened.withAlpha(10), Get.theme.backgroundColor),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Top Widget
              InkWell(
                highlightColor: const Color.fromARGB(60, 0, 0, 0),
                splashColor: Colors.transparent,
                onTap: () {
                  Get.close(1);
                  Get.to(() => AlbumTracksPage(album: Indexer.inst.albumSearchList[availableAlbums.first]!.toList()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16.0),
                      if (forceSingleArtwork)
                        ArtworkWidget(
                          track: tracks.first,
                          thumnailSize: 60,
                          forceSquared: forceSquared,
                        ),
                      if (!forceSingleArtwork)
                        MultiArtworkContainer(
                          heroTag: 'edittags_artwork',
                          size: 60,
                          tracks: tracks,
                          margin: EdgeInsets.zero,
                        ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title.overflow,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Get.textTheme.displayLarge?.copyWith(
                                  fontSize: 17.0.multipliedFontScale,
                                  color: Color.alphaBlend(colorDelightened.withAlpha(40), Get.textTheme.displayMedium!.color!),
                                ),
                              ),
                            const SizedBox(
                              height: 1.0,
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle.overflow,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Get.textTheme.displayMedium?.copyWith(
                                  fontSize: 14.0.multipliedFontScale,
                                  color: Color.alphaBlend(colorDelightened.withAlpha(80), Get.textTheme.displayMedium!.color!),
                                ),
                              ),
                            if (thirdLineText.isNotEmpty) ...[
                              const SizedBox(
                                height: 1.0,
                              ),
                              Text(
                                thirdLineText.overflow,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Get.textTheme.displaySmall?.copyWith(
                                  fontSize: 12.5.multipliedFontScale,
                                  color: Color.alphaBlend(colorDelightened.withAlpha(40), Get.textTheme.displayMedium!.color!),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 16.0,
                      ),
                      const Icon(
                        Broken.arrow_right_3,
                      ),
                      const SizedBox(
                        width: 16.0,
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                color: Get.theme.dividerColor,
                thickness: 0.5,
                height: 0,
              ),

              /// List Items
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (availableAlbums.length == 1)
                    SmallListTile(
                      color: colorDelightened,
                      compact: true,
                      title: Language.inst.GO_TO_ALBUM,
                      subtitle: availableAlbums.first,
                      icon: Broken.music_dashboard,
                      onTap: () {
                        Get.close(1);
                        Get.to(() => AlbumTracksPage(album: Indexer.inst.albumSearchList[availableAlbums.first]!.toList()));
                      },
                    ),
                  if (availableAlbums.length > 1)
                    ExpansionTile(
                      expandedAlignment: Alignment.centerLeft,
                      leading: Icon(
                        Broken.music_dashboard,
                        color: Color.alphaBlend(colorDelightened.withAlpha(120), Get.textTheme.displayMedium!.color!),
                      ),
                      title: Text(
                        Language.inst.GO_TO_ALBUM,
                        style: Get.textTheme.displayMedium?.copyWith(
                          color: Color.alphaBlend(colorDelightened.withAlpha(40), Get.textTheme.displayMedium!.color!),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 20.0).add(const EdgeInsets.only(bottom: 12.0)),
                      children: [
                        Wrap(
                          alignment: WrapAlignment.start,
                          children: [
                            ...availableAlbums
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: InkWell(
                                        onTap: () {
                                          Get.to(() => AlbumTracksPage(album: Indexer.inst.albumSearchList[e.value]!.toList()));
                                        },
                                        child: Text(
                                          "${e.value}, ",
                                          style: Get.textTheme.displaySmall?.copyWith(decoration: TextDecoration.underline),
                                        )),
                                  ),
                                )
                                .toList(),
                          ],
                        )
                      ],
                    ),

                  if (availableArtists.length == 1)
                    SmallListTile(
                      color: colorDelightened,
                      compact: true,
                      title: Language.inst.GO_TO_ARTIST,
                      subtitle: availableArtists.first,
                      icon: Broken.microphone,
                      onTap: () {
                        Get.close(1);
                        Get.to(() => ArtistTracksPage(name: availableArtists.first));
                      },
                    ),

                  if (availableArtists.length > 1)
                    ExpansionTile(
                      expandedAlignment: Alignment.centerLeft,
                      leading: Icon(
                        Broken.profile_2user,
                        color: Color.alphaBlend(colorDelightened.withAlpha(120), Get.textTheme.displayMedium!.color!),
                      ),
                      title: Text(
                        Language.inst.GO_TO_ARTIST,
                        style: Get.textTheme.displayMedium?.copyWith(
                          color: Color.alphaBlend(colorDelightened.withAlpha(40), Get.textTheme.displayMedium!.color!),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 20.0).add(const EdgeInsets.only(bottom: 12.0)),
                      children: [
                        Wrap(
                          alignment: WrapAlignment.start,
                          children: [
                            ...availableArtists
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: InkWell(
                                        onTap: () {
                                          Get.to(() => ArtistTracksPage(name: e.value));
                                        },
                                        child: Text(
                                          "${e.value}, ",
                                          style: Get.textTheme.displaySmall?.copyWith(decoration: TextDecoration.underline),
                                        )),
                                  ),
                                )
                                .toList(),
                          ],
                        )
                      ],
                    ),

                  SmallListTile(
                    color: colorDelightened,
                    compact: false,
                    title: Language.inst.ADD_TO_PLAYLIST,
                    icon: Broken.music_library_2,
                    onTap: () {
                      Get.close(1);
                      showAddToPlaylistDialog(tracks);
                    },
                  ),
                  SmallListTile(
                    color: colorDelightened,
                    compact: false,
                    title: Language.inst.EDIT_TAGS,
                    icon: Broken.edit,
                    onTap: () {
                      Get.close(1);
                      if (isSingle) {
                        showEditTrackTagsDialog(tracks.first);
                      } else {
                        editMultipleTracksTags(tracks);
                      }
                    },
                  ),
                  SmallListTile(
                    color: colorDelightened,
                    compact: true,
                    title: Language.inst.CLEAR,
                    subtitle: Language.inst.CHOOSE_WHAT_TO_CLEAR,
                    icon: Broken.trash,
                    onTap: () => showTrackClearDialog(tracks),
                  ),
                  if (isSingle)
                    SmallListTile(
                      color: colorDelightened,
                      compact: false,
                      title: Language.inst.SET_YOUTUBE_LINK,
                      icon: Broken.edit_2,
                      onTap: () async {
                        Get.close(1);

                        TextEditingController controller = TextEditingController();
                        final ytlink = VideoController.inst.extractYTLinkFromTrack(tracks.first);
                        controller.text = ytlink;
                        Get.dialog(
                          CustomBlurryDialog(
                            title: Language.inst.SET_YOUTUBE_LINK,
                            actions: [
                              const CancelButton(),
                              ElevatedButton(
                                onPressed: () async {
                                  editTrackMetadata(tracks.first, insertComment: controller.text);

                                  Indexer.inst.updateTracks([tracks.first]);
                                  Get.close(1);
                                },
                                child: Text(Language.inst.SAVE),
                              ),
                            ],
                            child: CustomTagTextField(
                              controller: controller,
                              hintText: ytlink.overflow,
                            ),
                          ),
                        );
                      },
                    ),
                  if (playlist != null && !isTrackInPlaylist)
                    SmallListTile(
                      color: colorDelightened,
                      compact: false,
                      title: Language.inst.SET_MOODS,
                      icon: Broken.edit_2,
                      onTap: () async {
                        Get.close(1);

                        TextEditingController controller = TextEditingController();
                        final currentMoods = playlist.modes.join(', ');
                        controller.text = currentMoods;
                        Get.dialog(
                          CustomBlurryDialog(
                            title: Language.inst.SET_MOODS,
                            actions: [
                              const CancelButton(),
                              ElevatedButton(
                                onPressed: () async {
                                  List<String> moodsPre = controller.text.split(',');
                                  List<String> moodsFinal = [];
                                  for (final m in moodsPre) {
                                    if (m.contains(',') || m == ' ' || m.isEmpty) {
                                      continue;
                                    }
                                    moodsFinal.add(m.trim());
                                  }
                                  PlaylistController.inst.updatePropertyInPlaylist(playlist, modes: moodsFinal);

                                  Get.close(1);
                                },
                                child: Text(Language.inst.SAVE),
                              ),
                            ],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Language.inst.SET_MOODS_SUBTITLE,
                                  style: Get.textTheme.displaySmall,
                                ),
                                const SizedBox(
                                  height: 20.0,
                                ),
                                CustomTagTextField(
                                  controller: controller,
                                  hintText: currentMoods.overflow,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  if (playlist != null && !isTrackInPlaylist)
                    SmallListTile(
                      color: colorDelightened,
                      compact: true,
                      title: Language.inst.DELETE_PLAYLIST,
                      icon: Broken.pen_remove,
                      onTap: () {
                        PlaylistController.inst.removePlaylist(playlist);
                        Get.close(1);
                      },
                    ),
                  if (playlist != null && isTrackInPlaylist)
                    SmallListTile(
                      color: colorDelightened,
                      compact: true,
                      title: Language.inst.REMOVE_FROM_PLAYLIST,
                      icon: Broken.box_remove,
                      onTap: () {
                        PlaylistController.inst.removeTracksFromPlaylist(playlist.id, tracks);
                        Get.close(1);
                      },
                    ),
                  //
                  Divider(
                    color: Get.theme.dividerColor,
                    thickness: 0.5,
                    height: 0,
                  ),

                  /// bottom 2 tiles
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: SmallListTile(
                            color: colorDelightened,
                            compact: false,
                            title: Language.inst.PLAY_NEXT,
                            icon: Broken.next,
                            onTap: () {
                              Get.close(1);

                              Player.inst.addToQueue(tracks, insertNext: true);
                            },
                          ),
                        ),
                        VerticalDivider(
                          color: Get.theme.dividerColor,
                          thickness: 0.5,
                          width: 0,
                        ),
                        Expanded(
                          child: SmallListTile(
                            color: colorDelightened,
                            compact: false,
                            title: Language.inst.PLAY_LAST,
                            icon: Broken.play_cricle,
                            onTap: () {
                              Get.close(1);

                              Player.inst.addToQueue(tracks);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                color: Get.theme.dividerColor.withAlpha(40),
                thickness: 1,
                height: 0,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
