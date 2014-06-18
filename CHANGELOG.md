# HOOHoodie CHANGELOG

## 0.1.0

Initial release.

##0.2.0

New functionality:
- Remove object from store
- Update object in store
- Change password of account
Also:
-  Example app now includes editing and removing todos
- HOOStoreChangeNotification now posted on main thread
- Hoodie id generation now follows the same standards as hoodie.js
- Added tests & travis integration

##0.2.1

- Now also works on 64bit architecture
- Update to Couchbase Lite 1.0-beta3.1
- New feature: Anonymous signup

##0.2.2

- Updated to Couchbase Lite 1.0
- Bugfix: removed duplicate creation of replications
- Code documentation
- Code Refactoring (moved all CouchDB/Hoodie API related code into a separate class HOOHoodieAPIClient)