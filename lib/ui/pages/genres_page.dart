import 'package:flutter/cupertino.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:namida/controller/indexer_controller.dart';
import 'package:namida/controller/scroll_search_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/functions.dart';
import 'package:namida/core/translations/strings.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/ui/dialogs/common_dialogs.dart';
import 'package:namida/ui/widgets/expandable_box.dart';
import 'package:namida/ui/widgets/library/multi_artwork_card.dart';
import 'package:namida/ui/widgets/sort_by_button.dart';

class GenresPage extends StatelessWidget {
  GenresPage({super.key});
  final ScrollController _scrollController = ScrollSearchController.inst.genreScrollcontroller;
  final countPerRow = SettingsController.inst.genreGridCount.value;
  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(
      controller: _scrollController,
      child: AnimationLimiter(
        child: Obx(
          () => Column(
            children: [
              ExpandableBox(
                gridWidget: ChangeGridCountWidget(
                  currentCount: SettingsController.inst.genreGridCount.value,
                  onTap: () {
                    final n = SettingsController.inst.genreGridCount.value;
                    final nToSave = n < 4 ? n + 1 : 2;
                    SettingsController.inst.save(genreGridCount: nToSave);
                  },
                ),
                isBarVisible: ScrollSearchController.inst.isGenreBarVisible.value,
                showSearchBox: ScrollSearchController.inst.showGenreSearchBox.value,
                leftText: Indexer.inst.genreSearchList.length.displayGenreKeyword,
                onFilterIconTap: () => ScrollSearchController.inst.switchGenreSearchBoxVisibilty(),
                onCloseButtonPressed: () => ScrollSearchController.inst.clearGenreSearchTextField(),
                sortByMenuWidget: SortByMenu(
                  title: SettingsController.inst.genreSort.value.toText,
                  popupMenuChild: const SortByMenuGenres(),
                  isCurrentlyReversed: SettingsController.inst.genreSortReversed.value,
                  onReverseIconTap: () => Indexer.inst.sortGenres(reverse: !SettingsController.inst.genreSortReversed.value),
                ),
                textField: CustomTextFiled(
                  textFieldController: Indexer.inst.genresSearchController,
                  textFieldHintText: Language.inst.FILTER_GENRES,
                  onTextFieldValueChanged: (value) => Indexer.inst.searchGenres(value),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: countPerRow, childAspectRatio: 0.8, mainAxisSpacing: 8.0),
                  controller: _scrollController,
                  itemCount: Indexer.inst.genreSearchList.length,
                  padding: const EdgeInsets.only(bottom: kBottomPadding),
                  itemBuilder: (BuildContext context, int i) {
                    final genre = Indexer.inst.genreSearchList[i];
                    return AnimatingGrid(
                      columnCount: Indexer.inst.genreSearchList.length,
                      position: i,
                      child: MultiArtworkCard(
                        heroTag: 'parent_genre_artwork_${genre.name}',
                        tracks: genre.tracks,
                        name: genre.name,
                        gridCount: countPerRow,
                        showMenuFunction: () => NamidaDialogs.inst.showGenreDialog(
                          genre.name,
                          genre.tracks,
                          heroTag: 'genre_artwork_${genre.name}',
                        ),
                        onTap: () => NamidaOnTaps.inst.onGenreTap(genre.name),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
