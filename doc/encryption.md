# Encrypt databases

This is an experimental feature, use with caution.

CDTDatastore is able to create encrypted databases. To do so, first edit your
`Podfile` and replace:

```
pod "CDTDatastore"
```

With:

```
pod "CDTDatastore/SQLCipher"
```

Then, implement a class that conforms to protocol
[CDTEncryptionKeyProviding][CDTEncryptionKeyProviding]. This protocol only
defines one method:

```
- (NSString *)encryptionKey;
```

For now, it is up to you to safely store the key that you have to return with
this method (if the method return nil, the database won't be encrypted
regardless of the subspec defined in your `Podfile`).

To end, call `CDTDatastoreManager:datastoreNamed:withEncryptionKeyRetriever:error:`
to create `CDTDatastores` with encrypted databases (datastores and indexes are
encrypted but not attachments and extensions)

[CDTEncryptionKeyProviding]: ../Classes/common/CDTEncryptionKey/CDTEncryptionKeyProviding.h
