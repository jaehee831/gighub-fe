import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:madcamp_week4_front/admin/admin_profile.dart';
import 'package:madcamp_week4_front/main.dart';
import 'user_wage.dart';
import 'homepage_no_store_worker.dart'; // Ensure this import is correct based on your project structure
import 'channel_board_page.dart';
import 'attendance_bot.dart';
import 'package:madcamp_week4_front/worker_profile.dart';
import 'package:madcamp_week4_front/schedule.dart';
import 'package:madcamp_week4_front/member.dart';
import 'package:madcamp_week4_front/signup/mobile_logout.dart';
import 'package:madcamp_week4_front/signup/signup_owner.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final int storeId;

  const HomePage({super.key, required this.userId, required this.storeId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _notice = '공지 사항이 없습니다';
  late String storeName = '';
  late List<Map<String, dynamic>> tasks = [];
  late Map<int, int> userWages = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getStoreName(widget.storeId);
    _fetchNotice();
    _fetchRooms();
    _fetchTasks(widget.storeId);
    _fetchTasks(widget.storeId);
    _fetchUserWages();
  }

  Future<void> _fetchNotice() async {
    final url = Uri.parse(
        'http://143.248.191.63:3001/get_notice?idstore=${widget.storeId}');
    final response = await http.get(url);
    print("get_notice: ${response.body}");
    print("get_notice: ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _notice = data['content'];
      });
    } else {
      setState(() {
        _notice = '공지 사항을 불러오지 못했습니다.';
      });
    }
  }

  Future<String> _fetchUserName(int userId) async {
    final response = await http.post(
      Uri.parse('http://143.248.191.63:3001/get_user_name'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['user_name'];
    } else {
      throw Exception('Failed to load user name');
    }
  }

  List<Map<String, dynamic>> _rooms = [];

  Future<void> _fetchRooms() async {
    final url = Uri.parse('http://143.248.191.63:3001/get_boards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _rooms = List<Map<String, dynamic>>.from(data);
      });
    } else {
      _rooms = [];
    }
  }

  Future<List<int>> _getStoreList(int userId) async {
    final url = Uri.parse('http://143.248.191.63:3001/get_store_list');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId.toString()}),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody.containsKey('storeIds')) {
        List<int> storeIds = List<int>.from(responseBody['storeIds']);
        return storeIds;
      } else {
        throw Exception('No store registered');
      }
    } else if (response.statusCode == 400) {
      final responseBody = jsonDecode(response.body);
      throw Exception('Missing Fields: ${responseBody['error']}');
    } else {
      throw Exception(
          'Failed to load store ids. Status code: ${response.statusCode}');
    }
  }

  Future<String> _getStoreName(int storeId) async {
    final url = Uri.parse('http://143.248.191.63:3001/get_store_name_list');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'store_id': storeId.toString()}),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      setState(() {
        storeName = responseBody['store_name'];
      });
      return responseBody['store_name'];
    } else {
      throw Exception(
          'Failed to load store name. Status code: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> _getStoreData(int userId) async {
    try {
      List<int> storeIds = await _getStoreList(userId);
      List<Map<String, dynamic>> storeData = [];
      for (int storeId in storeIds) {
        String storeName = await _getStoreName(storeId);
        storeData.add({'id': storeId, 'name': storeName});
      }
      return storeData;
    } catch (e) {
      throw Exception('Failed to load store data: $e');
    }
  }

  void _showChannelChangePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getStoreData(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('채널 변경'),
                content: SizedBox(
                  width: double.minPositive,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('채널 변경'),
                content: const SizedBox(
                  width: double.minPositive,
                  child: Center(child: Text('Failed to load stores')),
                ),
                actions: [
                  TextButton(
                    child: const Text('닫기'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            } else {
              final storeData = snapshot.data ?? [];
              return AlertDialog(
                title: const Text('채널 변경'),
                content: SizedBox(
                  width: double.minPositive,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (var store in storeData)
                        ListTile(
                          title: Text(store['name']),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(
                                  userId: widget.userId,
                                  storeId: store['id'],
                                ),
                              ),
                            );
                          },
                        ),
                      ListTile(
                        title: const Text('+ 채널 추가하기'),
                        onTap: () async {
                          bool isAdmin = await _checkIsAdmin(widget.userId);
                          String nickname = await _fetchUserName(widget.userId);
                          if (isAdmin) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupOwner(
                                  userId: widget.userId,
                                  nickname: nickname,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomepageNoStoreWorker(
                                    userId: widget.userId),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('닫기'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  void _navigateToChannelBoard(BuildContext context, int userId,
      String channelName, int boardId, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelBoardPage(
            userId: userId,
            channelName: channelName,
            boardId: boardId,
            description: description),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomePage(userId: widget.userId, storeId: widget.storeId),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Member(userId: widget.userId, storeId: widget.storeId),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceBotPage(userId: widget.userId),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        backgroundColor: primaryColor,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _onPersonPressed(widget.userId);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: primaryColor,
                ),
                child: GestureDetector(
                  onTap: () => _showChannelChangePopup(context),
                  child: const Row(
                    children: [
                      Icon(Icons.swap_horiz),
                      SizedBox(width: 8.0),
                      Text(
                        '채널 변경',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ..._rooms.map((room) => ListTile(
                    leading: const Icon(Icons.group),
                    title: Text(room['title'] ?? '방 이름 없음'),
                    tileColor: Colors.white,
                    onTap: () => _navigateToChannelBoard(
                        context,
                        widget.userId,
                        room['title'] ?? '방 이름 없음',
                        room['idboard'],
                        room['description']), // null 값을 처리
                  )),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('방 추가하기'),
                tileColor: Colors.white,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return RoomDialog(
                        onRoomAdded: () {
                          _fetchRooms();
                        },
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                tileColor: Colors.white,
                onTap: () {
                  logoutFromKakao(
                    onLogoutSuccess: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      Navigator.pushReplacementNamed(
                          context, '/'); // 로그아웃 성공 시 메인 화면으로 이동
                    },
                    onLogoutFailed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('로그아웃 실패'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 공지 섹션
              const Text(
                '공지',
                style: TextStyle(fontSize: 24.0),
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  _notice,
                  style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16.0),
              // 업무 시간표 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '업무 시간표',
                    style: TextStyle(fontSize: 24.0),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Schedule(
                                  userId: widget.userId,
                                  storeId: widget.storeId)));
                    },
                    child: const Text('더보기'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '업무 시간표',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(height: 16.0),
                    if (tasks.isEmpty ||
                        tasks
                            .where((task) =>
                                DateTime.parse(task['start_time']).day ==
                                DateTime.now().day)
                            .isEmpty)
                      const Text(
                        '오늘 배정된 task가 없습니다.',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey),
                      )
                    else
                      for (var task in tasks)
                        if (DateTime.parse(task['start_time']).day ==
                            DateTime.now().day)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${task['start_time'].substring(11, 16)}~${task['end_time'].substring(11, 16)}  ${task['task_name']}',
                                style: const TextStyle(
                                    fontSize: 14.0, color: Colors.black),
                              ),
                              const SizedBox(height: 4.0),
                            ],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              // 급여 계산 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '급여 계산',
                    style: TextStyle(fontSize: 24.0),
                  ),
                  TextButton(
                    onPressed: () async {
                      String userName = await _fetchUserName(widget.userId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserWagePage(
                            userId: widget.userId,
                            userName: userName,
                          ),
                        ),
                      );
                    },
                    child: const Text('더보기'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: FutureBuilder<bool>(
                  future: _checkIsAdmin(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Text(
                        '급여 정보 조회',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey),
                      );
                    } else {
                      final isAdmin = snapshot.data ?? false;
                      if (isAdmin) {
                        return const Text(
                          '직원 전용 페이지입니다.',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey),
                        );
                      } else {
                        return FutureBuilder<int>(
                          future: _fetchMemberWorkTime(widget.userId),
                          builder: (context, timeSnapshot) {
                            if (timeSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (timeSnapshot.hasError) {
                              return const Text(
                                '오류 발생',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.grey),
                              );
                            } else {
                              final totalMinutes = timeSnapshot.data ?? 0;
                              final hourlyRate = userWages[widget.userId] ?? 0;
                              final monthlySalary =
                                  (hourlyRate / 60) * totalMinutes;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '이번 달 월급',
                                    style: TextStyle(
                                        fontSize: 14.0, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    '${monthlySalary.toStringAsFixed(0)} 원 쌓였어요',
                                    style: const TextStyle(
                                        fontSize: 14.0, color: Colors.black),
                                  ),
                                ],
                              );
                            }
                          },
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFFFFF0BA),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '멤버',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: '출첵',
          ),
        ],
      ),
    );
  }

  void _onPersonPressed(int userId) async {
    bool isAdmin = await _checkIsAdmin(userId);
    if (isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminProfile(userId: userId)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WorkerProfile(userId: userId)),
      );
    }
  }

  void _onWagePressed(int userId) async {
    bool isAdmin = await _checkIsAdmin(userId);
    if (isAdmin) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('직원 전용 페이지입니다'),
            actions: [
              TextButton(
                child: const Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }
    try {
      String userName = await _fetchUserName(userId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserWagePage(
            userId: widget.userId,
            userName: userName,
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user name')),
      );
    }
  }

  Future<void> _fetchUserWages() async {
    final url = Uri.parse('http://143.248.191.63:3001/get_user_wage');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      setState(() {
        userWages = {
          for (var wageInfo in responseBody)
            wageInfo['iduser']:
                int.parse(wageInfo['hourly_rate'].toString().split('.')[0])
        };
      });
    } else {
      throw Exception(
          'Failed to load user wages. Status code: ${response.statusCode}');
    }
  }

  Future<int> _fetchMemberWorkTime(int userId) async {
    final url = Uri.parse(
        'http://143.248.191.63:3001/get_member_work_time?user_id=$userId');
    final response =
        await http.get(url, headers: {'Content-Type': 'application/json'});
    print('get_member_work_time: ${response.body}');
    print('get_member_work_time: ${response.statusCode}');
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final records = responseBody['records'];
      int totalMinutes = 0;
      for (var record in records) {
        if (record['check_in_time'] != null && 
            record['check_out_time'] != null && 
            record['break_start_time'] != null && 
            record['break_end_time'] != null) {
          
          DateTime checkIn = DateTime.parse(record['check_in_time']);
          DateTime checkOut = DateTime.parse(record['check_out_time']);
          DateTime breakStart = DateTime.parse(record['break_start_time']);
          DateTime breakEnd = DateTime.parse(record['break_end_time']);
          
          totalMinutes += checkOut.difference(checkIn).inMinutes;
          totalMinutes -= breakEnd.difference(breakStart).inMinutes;
        }
      }
      return totalMinutes;
    } else if (responseBody.containsKey('message') &&
        responseBody['message'] ==
            'No records found for the specified user_id') {
      return 0;
    } else {
      throw Exception(
          'Failed to load work time. Status code: ${response.statusCode}');
    }
  }

  Future<void> _fetchTasks(int storeId) async {
    final url = Uri.parse('http://143.248.191.63:3001/get_tasks');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'store_id': storeId}),
    );
    print('get_tasks: Response Body: ${response.body}');
    print('get_tasks: Response Code: ${response.statusCode}');
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody is List) {
        DateTime today = DateTime.now();
        setState(() {
          tasks = List<Map<String, dynamic>>.from(responseBody)
              .where(
                  (task) => DateTime.parse(task['start_time']).day == today.day)
              .toList();
        });
      } else if (responseBody is Map && responseBody.containsKey('message')) {
        print('no registered tasks in the store');
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception(
          'Failed to load tasks in the store. Status code: ${response.statusCode}');
    }
  }

  Future<bool> _checkIsAdmin(int userId) async {
    final url = Uri.parse('http://143.248.191.63:3001/check_isadmin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    print("check_isadmin: ${response.body}");
    if (response.statusCode == 200) {
      if (jsonDecode(response.body) == 1) {
        return true;
      } else {
        return false;
      }
    } else {
      throw Exception(
          'Failed to check if user is admin. Status code: ${response.statusCode}');
    }
  }
}

class RoomDialog extends StatefulWidget {
  final VoidCallback onRoomAdded;
  const RoomDialog({super.key, required this.onRoomAdded});

  @override
  _RoomDialogState createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _addRoom() async {
    final name = _nameController.text;
    final description = _descriptionController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방 이름을 입력하세요')),
      );
      return;
    }

    final url = Uri.parse('http://143.248.191.63:3001/add_board');
    print('Adding room with name: $name and description: $description');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': name, 'description': description}),
    );

    if (response.statusCode == 201) {
      widget.onRoomAdded();
      Navigator.of(context).pop();
    } else {
      print(
          'Failed to add room. Response status: ${response.statusCode}, body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방 추가에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('방 추가하기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '방 이름',
            ),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '설명',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _addRoom,
          child: const Text('작성 완료'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
