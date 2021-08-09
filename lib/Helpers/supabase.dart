import 'package:supabase/supabase.dart';

class SupaBase {
  final client = SupabaseClient('https://vuakihfddljlzovzbdaf.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYyNzU1MTk3MywiZXhwIjoxOTQzMTI3OTczfQ.4PzxpfIk81ZvLtUOe0muHVGiZLr-dMK7BLyFsUcrVtc');

  Future<Map> getUpdate() async {
    final response = await client
        .from('Update')
        .select()
        .order('LatestVersion', ascending: false)
        .execute();
    List result = response.data;
    return result.isEmpty
        ? {}
        : {
            'LatestVersion': response.data[0]['LatestVersion'],
            'LatestUrl': response.data[0]['LatestUrl']
          };
  }

  Future<void> updateUserDetails(
      String userId, String key, String value) async {
    // final response = await client.from('Users').update({key: value},
    //     returning: ReturningOption.minimal).match({'id': userId}).execute();
    // print(response.toJson());
  }

  Future<int> createUser(Map data) async {
    final response = await client
        .from('Users')
        .insert(data, returning: ReturningOption.minimal)
        .execute();
    return response.status;
  }
}
