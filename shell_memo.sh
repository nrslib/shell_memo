# delete remote tags
git ls-remote --tags | grep alpha | awk '{ print $2 }' | awk -F/ '{ print $3 }' | xargs git push origin --delete
