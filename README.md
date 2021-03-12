Emoji Art File Storage

Implementation

    I changed the init in the EmojiArtDocument ViewModel to read file contents and write to a file instead of using the user defaults store. The files were named using their uuids. The EmojiArtDocumentStore got the document names by listing document files from the document directory. The documentNames variable is where it got confusing for me.

Naming Specs

    Overall the implementation of the file system as a store was not confusing, but the specifications on how to use it with naming was confusing. We are supposed to use the id to name the document, so we shouldn't allow the user to change the name of the file anymore? I just had the id be the name shown because I wasn't sure what we were supposed to do about the naming.

Magic Extensions

    Honestly, it was confusing to read and understand the extension of the dictionary used in the EmojiArtDocumentStore in order to use it. I don't think it is beneficial to have a lot of extension "magic" that is going on behind the scene that we just use. Then we won't be able to understand what's actually going on when we try to use it ourselves.
