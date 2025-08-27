# nahCon [WIP]
![nahCon Banner](assets/Banner.png)

A Jellyfin video client made using Flutter.

## Features
- [x] Login into your Jellyfin server
- [x] Display Library
- [x] Filter Media
- [ ] Search Media
- [x] Stream Media (requires a lot of testing)
- [ ] Download media onto the device
- [ ] Continue watching (works but needs testing)
- [ ] Add to watch later
- [x] Show TV shows


## Platform
- [x] Android
- [ ] iOS (haven't tested)
- [x] macOS
- [ ] Linux
- [ ] Windows

## Compiling the app
Before anything, be sure to have a working flutter sdk setup.If not installed, go to [Install - Flutter](https://docs.flutter.dev/get-started/install).

Be sure to disable signing on build.gradle or change keystore to sign the app.

For now the required flutter channel is master, so issue those two commands before starting building:
```
$ flutter channel master
```
```
$ flutter upgrade
```

After that, building is simple as this:
```
$ flutter pub get
```
```
$ flutter run
```
```
$ flutter build platform-name
```

## Contributing

Feel free to open a PR to suggest fixes, features or whatever you want, just remember that PRs are subjected to manual review so you gotta wait for actual people to look at your contributions.