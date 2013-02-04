# TweetShifter

Tool to monitor your favorites for bookmarks

## Setup

Create new OpenShift application

    rhc app create tweetshifter diy-0.1

fetch the source code

    cd tweetshifter
    gill pull -s recursive -X theirs git://github.com/openshift-quickstart/tweetshifter-openshift-quickstart.git

change the configuration

    $EDITOR config.yml

and push to OpenShift

    git add .
    git commit -m "First deploy"

and you are done.
