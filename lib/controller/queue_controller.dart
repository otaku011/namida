import 'dart:io';

import 'package:get/get.dart';

import 'package:namida/class/queue.dart';
import 'package:namida/class/track.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/functions.dart';
import 'package:namida/core/namida_converter_ext.dart';

class QueueController {
  static QueueController get inst => _instance;
  static final QueueController _instance = QueueController._internal();
  QueueController._internal();

  final RxList<Queue> queueList = <Queue>[].obs;
  final RxList<Track> latestQueue = <Track>[].obs;

  /// doesnt save queues with more than 2000 tracks.
  void addNewQueue(
    QueueSource source, {
    int? date,
    List<Track> tracks = const <Track>[],
  }) async {
    /// if there are more than 2000 tracks.
    if (tracks.length > 2000) {
      printInfo(info: "UWAH QUEUE DEKKA");
      return;
    }

    /// if the queue is the same, it will skip instead of saving the same queue.
    if (checkIfQueueSameAsCurrent(tracks)) {
      printInfo(info: "Didnt Save Queue: Similar as Current");
      return;
    }
    printInfo(info: "Added New Queue");
    date ??= DateTime.now().millisecondsSinceEpoch;
    final q = Queue(source.toText(), date, false, tracks);
    queueList.add(q);
    await _saveQueueToStorage(q);
  }

  void removeQueue(Queue queue) async {
    queueList.remove(queue);
    await _deleteQueueFromStorage(queue);
  }

  void insertQueue(Queue queue, int index) async {
    queueList.insertSafe(index, queue);
    await _saveQueueToStorage(queue);
  }

  // void removeQueues(List<Queue> queues) async {
  //   queues.loop((q) => removeQueue(q));
  // }

  void updateQueue(Queue oldQueue, Queue newQueue) async {
    final plIndex = queueList.indexOf(oldQueue);
    queueList.remove(oldQueue);
    queueList.insertSafe(plIndex, newQueue);

    await _saveQueueToStorage(newQueue);
  }

  void updateLatestQueue(List<Track> tracks) async {
    latestQueue.assignAll(tracks);
    if (queueList.isNotEmpty) {
      queueList.last.tracks.assignAll(tracks);
      await _saveLatestQueueToStorage(queueList.last);
    }
  }

  void insertTracksQueue(Queue queue, List<Track> tracks, int index) async {
    queue.tracks.insertAllSafe(index, tracks);
    await _saveQueueToStorage(queue);
  }

  Future<void> removeTrackFromQueue(Queue queue, int index) async {
    queue.tracks.removeAt(index);
    await _saveQueueToStorage(queue);
  }

  ///
  Future<void> prepareAllQueuesFile() async {
    await for (final p in Directory(k_DIR_QUEUES).list()) {
      // prevents freezing the ui. cheap alternative for Isolate/compute.
      await Future.delayed(Duration.zero);

      await File(p.path).readAsJsonAnd((response) async {
        queueList.add(Queue.fromJson(response));
      });

      /// Sorting accensingly by date since [Directory().list()] doesnt maintain order
      queueList.sort((a, b) => a.date.compareTo(b.date));
    }
  }

  ///
  Future<void> prepareLatestQueueFile() async {
    await File(k_FILE_PATH_LATEST_QUEUE).readAsJsonAnd((response) async {
      final lq = Queue.fromJson(response);
      latestQueue.assignAll(lq.tracks);
    });
  }

  /// Assigns the last queue to the [Player]
  Future<void> putLatestQueue() async {
    if (latestQueue.isEmpty) {
      return;
    }
    final latestTrack = SettingsController.inst.lastPlayedTrackPath.value.toTrackOrNull();
    final ind = latestQueue.indexOf(latestTrack);
    if (latestTrack == null) return;

    await Player.inst.playOrPause(
      ind == -1 ? 0 : ind,
      latestQueue.toList(),
      QueueSource.playerQueue,
      startPlaying: false,
      dontAddQueue: true,
    );
  }

  Future<void> _saveQueueToStorage(Queue queue) async {
    await File('$k_DIR_QUEUES${queue.date}.json').writeAsJson(queue.toJson());
  }

  Future<void> _saveLatestQueueToStorage(Queue queue) async {
    await File(k_FILE_PATH_LATEST_QUEUE).writeAsJson(queue.toJson());
  }

  Future<void> _deleteQueueFromStorage(Queue queue) async {
    await File('$k_DIR_QUEUES${queue.date}.json').delete();
  }
}
