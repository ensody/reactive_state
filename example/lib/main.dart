// This is a simple, but pretty complete flutter_simple_state example.
// It demonstrates use-cases for small and large apps:
//
// Actions & state values can be globally accessible via Provider.
// This can be useful for making e.g. the currently logged-in user accessible
// from anywhere in the app.
//
// Actions & state values can alternatively be passed diretly as arguments.
// This is important for writing reusable components that mustn't depend on
// some globally accessible app-specific state.

import 'package:flutter/material.dart';
import 'package:flutter_simple_state/flutter_simple_state.dart';
import 'package:provider/provider.dart';

void main() => runApp(App());

class User {
  User({this.name = '', this.email = '', this.location = ''});

  String name;
  String email;
  String location;
}

// Global state that the whole app has access to via a Provider.
// For complex apps you might want to split this up into multiple classes
// that cleanly take care of orthogonal state & action aspects.
class GlobalState {
  // We use Value instead of ValueNotifier because we need the update() helper below.
  final user = Value<User>(User());

  // A globally reachable action that is potentially used in multiple places.
  void updateUser(String name, String email) {
    // This demonstrates the Value.update() helper
    user.update((u) {
      u.name = name;
      u.email = email;
    });
  }
}

// We use a StatefulWidget to retain the state between hot reloads
class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  // Global state that will be available in the whole app.
  final state = GlobalState();

  // Local state that is only accessible to a subsection of the app.
  // If you have to pass lots of these objects as arguments *and* if they
  // conceptually belong together, you might want to group them in classes like
  // we did with GlobalState and pass a whole group as a single argument.
  final counter = ValueNotifier<int>(0);

  // A local action that is potentially used in multiple places, but only
  // needed in a subsection of your app.
  void decrement() {
    counter.value--;
  }

  @override
  Widget build(BuildContext context) {
    // We use a MultiProvider, so we can easily add more state objects later
    return MultiProvider(
      providers: [Provider.value(value: state)],
      child: MaterialApp(
        title: 'flutter_simple_state example',
        home: HomePage(counter: counter, decrement: decrement),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key key, @required this.counter, @required this.decrement})
      : super(key: key);

  final ValueNotifier<int> counter;
  final VoidCallback decrement;
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  void _saveUser(GlobalState globalState) {
    globalState.updateUser(nameController.text, emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit values'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Counter (press "+"/"-" buttons):'),
            // We use multiple AutoRebuild widgets to minimize redrawing.
            AutoRebuild(builder: (context, get, track) {
              return Text(
                '${get(counter)}',
                style: Theme.of(context).textTheme.display1,
              );
            }),
            SizedBox(height: 20),
            Text(
              'User data',
              style: Theme.of(context).textTheme.display1,
            ),
            AutoRebuild(builder: (context, get, track) {
              var user = get(globalState.user);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Name: ${user.name}'),
                  Text('Email: ${user.email}'),
                ],
              );
            }),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(hintText: 'Name'),
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.text,
                  ),
                  TextFormField(
                    decoration: InputDecoration(hintText: 'Email'),
                    controller: emailController,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            AutoRebuild(builder: (context, get, track) {
              var enabled = get(nameController).text.isNotEmpty &&
                  get(emailController).text.isNotEmpty;
              var onPressed = enabled ? () => _saveUser(globalState) : null;
              return MaterialButton(
                onPressed: onPressed,
                child: Text('Save'),
              );
            })
          ],
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.0),
            child: FloatingActionButton(
              child: Icon(Icons.add),
              // Demonstrating trivial update case
              onPressed: () => counter.value++,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.0),
            child: FloatingActionButton(
              child: Icon(Icons.remove),
              // Demonstrating reusable action via callback
              onPressed: decrement,
            ),
          ),
        ],
      ),
    );
  }
}
