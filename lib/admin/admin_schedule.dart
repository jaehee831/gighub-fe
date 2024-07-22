import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class scheduleChooseStore extends StatefulWidget {
  final int userId;

  const scheduleChooseStore({
    super.key,
    required this.userId
  });

  @override
  _scheduleChooseStoreState createState() => _scheduleChooseStoreState();
}
  
class _scheduleChooseStoreState extends State<scheduleChooseStore> {
  late Future<List<Map<String, dynamic>>> storeFuture;

  @override
  void initState() {
    super.initState();
    storeFuture = _fetchStores(widget.userId);
  }

  Future<List<Map<String, dynamic>>> _fetchStores(int userId) async {
    final storeListUrl = Uri.parse('http://143.248.191.173:3001/get_store_list');
    final storeNameUrl = Uri.parse('http://143.248.191.173:3001/get_store_name_list');

    final storeListResponse = await http.post(
      storeListUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId.toString()}),
    );

    if (storeListResponse.statusCode != 200) {
      throw Exception('Failed to load store ids');
    }else if (jsonDecode(storeListResponse.body).containsKey('message')) {
      throw Exception('No store registered');
    }

    final storeIds = List<int>.from(jsonDecode(storeListResponse.body)['storeIds']);
    final List<Map<String, dynamic>> stores = [];

    for (int storeId in storeIds) {
      final storeNameResponse = await http.post(
        storeNameUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'store_id': storeId.toString()}),
      );

      if (storeNameResponse.statusCode == 200) {
        final storeName = jsonDecode(storeNameResponse.body)['store_name'];
        stores.add({'store_id': storeId, 'store_name': storeName});
      }
    }

    return stores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스케줄 수정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 로그아웃 동작 추가
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: storeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('등록된 가게가 없습니다.'));
          } else {
            final stores = snapshot.data!;
            return ListView(
              children: stores.map((store) {
                return ListTile(
                  title: Text(store['store_name']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminSchedule(storeId: store['store_id']),
                        ),
                      );
                    },
                    child: const Text('선택'),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 정보',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}


class AdminSchedule extends StatefulWidget {
  final int storeId;

  const AdminSchedule({super.key, required this.storeId});

  @override
  _AdminScheduleState createState() => _AdminScheduleState();
}

class _AdminScheduleState extends State<AdminSchedule> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? startTime;
  DateTime? endTime;
  List<int> selectedUsers = [];
  List<DateTime> timeOptions =
      List.generate(24, (index) => DateTime.now().add(Duration(hours: index)));
  final DateFormat dateFormat = DateFormat('yy/MM/dd HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시간표 수정')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchStoreMembers(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final errorMessage = snapshot.error is Exception
                ? (snapshot.error as Exception).toString()
                : 'Error loading users';
            return Center(child: Text(errorMessage));
          } else {
            final users = snapshot.data!;
            return Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    TextFormField(
                      controller: taskNameController,
                      decoration: const InputDecoration(labelText: 'Task 제목'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter task name' : null,
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: '상세'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter description' : null,
                    ),
                    ListTile(
                      title: Text(
                        startTime != null
                            ? DateFormat('yy/MM/dd HH:mm').format(startTime!)
                            : 'Start Time',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: startTime ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(startTime ?? DateTime.now()),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              startTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                            });
                          }
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        endTime != null
                            ? DateFormat('yy/MM/dd HH:mm').format(endTime!)
                            : 'End Time',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: endTime ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(endTime ?? DateTime.now()),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              endTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                            });
                          }
                        }
                      },
                    ),
                    const Text('직원 배정'),
                    Wrap(
                      children: users.map((user) {
                        return CheckboxListTile(
                          title: Text(user['name']),
                          value: selectedUsers.contains(user['user_id']),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedUsers.add(user['user_id']);
                              } else {
                                selectedUsers.remove(user['user_id']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    ElevatedButton(
                      onPressed: saveTask,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Function to get users from the server
  Future<List<Map<String, dynamic>>> fetchStoreMembers(int storeId) async {
    final response = await http.post(
      Uri.parse('http://143.248.191.173:3001/get_store_members'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'store_id': storeId}),
    );
    print('Response Body: ${response.body}');
    final responseBody = json.decode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(responseBody);
    } else {
      if (responseBody.containsKey('message')) {
        throw Exception('가게에 등록한 직원이 없습니다.');
      } else {
        throw Exception('Failed to load store members');
      }
    }
  }

  // Function to submit the task to the server
  void saveTask() async {
    if (_formKey.currentState!.validate()) {
      final taskData = {
        'task_name': taskNameController.text,
        'description': descriptionController.text,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'store_id': widget.storeId,
        'user_id': selectedUsers,
      };

      final response = await http.post(
        Uri.parse('http://143.248.191.173:3001/add_task'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(taskData),
      );
      
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        // Task added successfully
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task added successfully')));
      } else {
        // Error adding task
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to add task')));
      }
    }
  }

}