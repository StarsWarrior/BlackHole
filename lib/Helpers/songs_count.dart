import 'package:hive/hive.dart';

class AddSongsCount {
  void addSong(String playlistName, int len, List images) {
    Map playlistDetails =
        Hive.box('settings').get('playlistDetails', defaultValue: {});
    if (playlistDetails.containsKey(playlistName)) {
      playlistDetails[playlistName]['count'] = len;
      playlistDetails[playlistName]['imagesList'] = images;
    } else {
      playlistDetails.addEntries([
        MapEntry(playlistName, {'count': len, 'imagesList': images})
      ]);
    }
    Hive.box('settings').put('playlistDetails', playlistDetails);
  }
}
