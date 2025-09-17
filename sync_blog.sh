#!/bin/bash
echo Syncing blog to $TARGET
rsync -e ssh --verbose --archive --delete blog/ $TARGET:~/blog
