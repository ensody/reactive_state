# Changelog

## [0.7.0-dev.1]

ATTENTION: This release comes with a few breaking changes.

* Renamed package to `reactive_state` (I'm sorry, but the old name gave people the impression that this is intended for simple apps)
* Renamed `AutoRebuild` to `AutoBuild`
* Added `ListValue` and `MapValue` which allow observing individual change events
* Added `.map()` and other operations allowing to create derived observable lists and maps more efficiently than with `DerivedValue`

## [0.6.0]

* Added `DerivedValue`, `AutoRunner`, `autorun`
* Upgraded to Dart 2.7

## [0.5.1+2]

* Fixed typo in example (thanks [Timm Preetz](https://github.com/tp))

## [0.5.1+1]

* Initial public release
