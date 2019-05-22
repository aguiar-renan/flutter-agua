library bottom_navy_bar;
import 'package:flutter/material.dart';
import 'package:flutter_login_demo/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login_demo/models/todo.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> _todoList;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _textEditingController = TextEditingController();
  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter = _counter + 100;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });

    int _cIndex = 0;

    void _incrementTab(index) {
      setState(() {
        _cIndex = index;
      });
    }

  }



  Query _todoQuery;

  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();

    _checkEmailVerification();

    _todoList = new List();
    _todoQuery = _database
        .reference()
        .child("todo")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(_onEntryAdded);
    _onTodoChangedSubscription = _todoQuery.onChildChanged.listen(_onEntryChanged);
  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {
      _showVerifyEmailDialog();
    }
  }

  void _resentVerifyEmail(){
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verifique sua conta"),
          content: new Text("Por favor, verifique a conta através do link enviado por email !"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Reenviar link"),
              onPressed: () {
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            new FlatButton(
              child: new Text("Dispensar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verifique sua conta de email"),
          content: new Text("Um link para verificar a conta foi enviado por email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dispensar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _onTodoAddedSubscription.cancel();
    _onTodoChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldEntry = _todoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _todoList[_todoList.indexOf(oldEntry)] = Todo.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  _addNewTodo(String todoItem) {
    if (todoItem.length > 0) {

      Todo todo = new Todo(todoItem.toString(), widget.userId, false);
      _database.reference().child("todo").push().set(todo.toJson());
    }
  }

  _updateTodo(Todo todo){
    //Toggle completed
    todo.completed = !todo.completed;
    if (todo != null) {
      _database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  _deleteTodo(String todoId, int index) {
    _database.reference().child("todo").child(todoId).remove().then((_) {
      print("Delete $todoId successful");
      setState(() {
        _todoList.removeAt(index);
      });
    });
  }

  _showDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
        context: context,
      builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(child: new TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Add new todo',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    _addNewTodo(_textEditingController.text.toString());
                    Navigator.pop(context);
                  })
            ],
          );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Hidrate-se'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Sair',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text(
                'Quantidade consumida hoje (ml)',
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  fontFamily: 'Roboto',
                ),
              ),
              new Text(
                '$_counter',
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 100.0,
                  fontFamily: 'Roboto',
                ),
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new RaisedButton(
                    padding: const EdgeInsets.all(8.0),
                    textColor: Colors.white,
                    color: Colors.blue,
                    onPressed: _incrementCounter,
                    child: new Text("Add"),
                  ),
                  new RaisedButton(
                    onPressed: _resetCounter,
                    textColor: Colors.white,
                    color: Colors.red,
                    padding: const EdgeInsets.all(8.0),
                    child: new Text(
                      "Zerar",
                    ),
                  ),
                ],
              )
            ],
          ),

        ),
      bottomNavigationBar: BottomNavigationBar(
      currentIndex: 0, // this will be set when a new tab is tapped
      items: [
        BottomNavigationBarItem(
          icon: new Icon(Icons.home),
          title: new Text('Home'),
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Perfil'),
        )
      ],
    )
    );

    return null;
  }


  /*
  Widget _showTodoList() {
    if (_todoList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _todoList.length,
          itemBuilder: (BuildContext context, int index) {
            String todoId = _todoList[index].key;
            String subject = _todoList[index].subject;
            bool completed = _todoList[index].completed;
            String userId = _todoList[index].userId;
            return Dismissible(
              key: Key(todoId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                _deleteTodo(todoId, index);
              },
              child: ListTile(
                title: Text(
                  subject,
                  style: TextStyle(fontSize: 20.0),
                ),
                trailing: IconButton(
                    icon: (completed)
                        ? Icon(
                      Icons.done_outline,
                      color: Colors.green,
                      size: 20.0,
                    )
                        : Icon(Icons.done, color: Colors.grey, size: 20.0),
                    onPressed: () {
                      _updateTodo(_todoList[index]);
                    }),
              ),
            );
          });
    } else {
      return Center(child: Text("Bem vindo. Sua lista está vazia",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Hidrate-se'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Sair',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        //body: _showTodoList(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showDialog(context);
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        )
    );
  }

  */
}
