@override
void initState() {
  super.initState();
  setState(() => _signedIn = true); // bypass Firebase login
}
