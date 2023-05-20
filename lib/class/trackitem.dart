import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';

class TrackItem {
  late TrackTileItem row1Item1;
  late TrackTileItem row1Item2;
  late TrackTileItem row1Item3;
  late TrackTileItem row2Item1;
  late TrackTileItem row2Item2;
  late TrackTileItem row2Item3;
  late TrackTileItem row3Item1;
  late TrackTileItem row3Item2;
  late TrackTileItem row3Item3;
  late TrackTileItem rightItem1;
  late TrackTileItem rightItem2;

  TrackItem(
    this.row1Item1,
    this.row1Item2,
    this.row1Item3,
    this.row2Item1,
    this.row2Item2,
    this.row2Item3,
    this.row3Item1,
    this.row3Item2,
    this.row3Item3,
    this.rightItem1,
    this.rightItem2,
  );
  TrackItem.fromJson(Map<String, dynamic> json) {
    row1Item1 = TrackTileItem.values.getEnum(json['row1Item1']) ?? TrackTileItem.title;
    row1Item2 = TrackTileItem.values.getEnum(json['row1Item2']) ?? TrackTileItem.none;
    row1Item3 = TrackTileItem.values.getEnum(json['row1Item3']) ?? TrackTileItem.none;
    row2Item1 = TrackTileItem.values.getEnum(json['row2Item1']) ?? TrackTileItem.artists;
    row2Item2 = TrackTileItem.values.getEnum(json['row2Item2']) ?? TrackTileItem.none;
    row2Item3 = TrackTileItem.values.getEnum(json['row2Item3']) ?? TrackTileItem.none;
    row3Item1 = TrackTileItem.values.getEnum(json['row3Item1']) ?? TrackTileItem.album;
    row3Item2 = TrackTileItem.values.getEnum(json['row3Item2']) ?? TrackTileItem.year;
    row3Item3 = TrackTileItem.values.getEnum(json['row3Item3']) ?? TrackTileItem.none;
    rightItem1 = TrackTileItem.values.getEnum(json['rightItem1']) ?? TrackTileItem.duration;
    rightItem2 = TrackTileItem.values.getEnum(json['rightItem2']) ?? TrackTileItem.none;
  }

  Map<String, dynamic> toJson() {
    return {
      'row1Item1': row1Item1.convertToString,
      'row1Item2': row1Item2.convertToString,
      'row1Item3': row1Item3.convertToString,
      'row2Item1': row2Item1.convertToString,
      'row2Item2': row2Item2.convertToString,
      'row2Item3': row2Item3.convertToString,
      'row3Item1': row3Item1.convertToString,
      'row3Item2': row3Item2.convertToString,
      'row3Item3': row3Item3.convertToString,
      'rightItem1': rightItem1.convertToString,
      'rightItem2': rightItem2.convertToString,
    };
  }
}
