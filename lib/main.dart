import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'Word.dart';
import 'DbWidget.dart';

void main() {
  runApp(MyApp());
}

enum Language { english, spanish }

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DbWidget(
        child: MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loadedDatabasepath = false;
  bool _openedDatabase = false;
  Language _language = Language.spanish;

  Word _priorWord;
  Word _word;

  _showSnackBar(BuildContext context, String content, {bool error = false}) {
    // _scaffoldKey.currentState.showSnackBar(SnackBar(
    //   content: Text('${error ? "An unexpected error occured: " : ""}$content'),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('${error ? "An unexpected error occured: " : ""}$content')));
  }

  _loadDatabasesPath(BuildContext context) {
    try {
      DbWidget.of(context).loadDatabasesPath().then((b) {
        setState(() {
          _loadedDatabasepath = true;
        });
      }).catchError((error) {
        _showSnackBar(context, error.toString(), error: true);
      });
    } catch (e) {
      _showSnackBar(context, e.toString(), error: true);
    }
  }

  _openAndInitDatabase(BuildContext context) {
    try {
      DbWidget.of(context).openAndInitDatabase().then((b) {
        setState(() {
          _openedDatabase = true;
        });
      }).catchError((error) {
        _showSnackBar(context, error.toString(), error: true);
      });
    } catch (e) {
      _showSnackBar(context, e.toString(), error: true);
    }
  }

  _loadWord(BuildContext context) {
    try {
      DbWidget.of(context).loadNextWord(_priorWord).then((word) {
        setState(() {
          _word = word;
        });
      }).catchError((error) {
        _showSnackBar(context, error.toString(), error: true);
      });
    } catch (e) {
      _showSnackBar(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedDatabasepath) {
      _loadDatabasesPath(context);
    } else if (!_openedDatabase) {
      _openAndInitDatabase(context);
    } else if (_word == null) {
      _loadWord(context);
    }

    WordWidget englishWordWidget =
        WordWidget(Language.english, _language, _word);

    WordWidget spanishWordWidget =
        WordWidget(Language.spanish, _language, _word);

    Column wordWidgets = _language == Language.spanish
        ? Column(
            children: [englishWordWidget, spanishWordWidget],
          )
        : Column(
            children: [spanishWordWidget, englishWordWidget],
          );
    AppBar appBar = AppBar(
      title: Text('Vocabulary'),
      actions: [
        IconButton(
          icon: Icon(Icons.shuffle),
          onPressed: () => _switchLanguage(),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _addWord(context),
        ),
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () => _deleteWord(context),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar,
      body: wordWidgets,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () => _loadNextWord(),
      ),
    );
  }

  _loadNextWord() {
    setState(() {
      _priorWord = _word;
      _word = null;
    });
  }

  _switchLanguage() {
    Language newLanguage =
        _language == Language.spanish ? Language.english : Language.spanish;

    setState(() {
      _language = newLanguage;
    });
  }

  _addWord(BuildContext context) async {
    Word word = await showDialog<Word>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(child: AddDialogWidget());
        });
    if (word != null) {
      try {
        DbWidget.of(context).addWord(word).then((_) {
          _loadNextWord();
          _showSnackBar(context, "Added Word");
        }).catchError((error) {
          _showSnackBar(context, error.toString(), error: true);
        });
      } catch (e) {
        _showSnackBar(context, e.toString(), error: true);
      }
    }
  }

  _deleteWord(BuildContext context) {
    _showConfirmDialog(context, _word).then((result) {
      if (result == true) {
        try {
          DbWidget.of(context).deleteWord(_word).then((_) {
            _loadNextWord();
            _showSnackBar(context, "Deleted word");
          }).catchError((error) {
            _showSnackBar(context, error.toString(), error: true);
          });
        } catch (e) {
          _showSnackBar(context, e.toString(), error: true);
        }
      }
    });
  }
}

class WordWidget extends StatefulWidget {
  final Language _widgetLanguage;
  final Language _language;
  final Word _word;

  WordWidget(this._widgetLanguage, this._language, this._word);

  @override
  _WordWidgetState createState() => _WordWidgetState();
}

class _WordWidgetState extends State<WordWidget> {
  bool _revealed = false;
  _WordWidgetState() {}

  @override
  void didUpdateWidget(Widget oldWidget) {
    _revealed = false;
  }

  @override
  Widget build(BuildContext context) {
    bool isReveal = widget._widgetLanguage == widget._language;

    List<Widget> widgets = [];

    String titleText = isReveal
        ? "What's the word in ${getLanguageName(widget._widgetLanguage)}?"
        : "Word in ${getLanguageName(widget._widgetLanguage)} is:";

    widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 20.0),
        child: Text(
          titleText,
          style: const TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        )));

    if ((isReveal) && (!_revealed)) {
      widgets.add(FloatingActionButton(
          child: Icon(Icons.remove_red_eye),
          onPressed: () => {setState(() => _revealed = true)}));
    } else {
      String word = widget._word == null
          ? ""
          : widget._widgetLanguage == Language.english
              ? widget._word.english
              : widget._word.spanish;
      widgets.add(Text(
        word,
        style: const TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ));
    }

    return Expanded(
        child: Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widgets,
      ),
      padding: EdgeInsets.all(10.0),
    ));
  }

  String getLanguageName(Language language) {
    return widget._widgetLanguage == Language.spanish ? 'Spanish' : 'English';
  }
}

class AddDialogWidget extends StatelessWidget {
  static final _formKey = GlobalKey<FormState>();
  static final TextEditingController _englishTextController =
      new TextEditingController();

  static final TextEditingController _spanishTextController =
      new TextEditingController();

  AddDialogWidget() : super();

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 260,
        width: 250,
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Add word',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter the word in English';
                        }
                      },
                      decoration: InputDecoration(
                        icon: const Icon(Icons.location_city),
                        hintText: 'English',
                        labelText: 'Enter the word in English',
                      ),
                      onSaved: (String value) {},
                      controller: _englishTextController,
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter the word in Spanish';
                        }
                      },
                      decoration: InputDecoration(
                        icon: const Icon(Icons.location_city),
                        hintText: 'Spanish',
                        labelText: 'Enter the word in Spanish',
                      ),
                      onSaved: (String value) {},
                      controller: _spanishTextController,
                    ),
                    TextButton(
                      child: Text("Add"),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _formKey.currentState.save();
                          Navigator.pop(
                              context,
                              Word(null, _englishTextController.text,
                                  _spanishTextController.text));

                          _englishTextController.text = '';
                          _spanishTextController.text = '';
                        }
                      },
                    )
                  ],
                ))));
  }
}

Future<bool> _showConfirmDialog(BuildContext context, Word word) async {
  return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content:
              Text('Are you sure you want to delete the word ${word.english}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('No'),
            )
          ],
        );
      });
}
