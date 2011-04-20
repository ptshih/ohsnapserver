Setting up the Rails Environment
---
* Rails 3.0.5+
* Ruby 1.9.2

* See Gems

Gems required and any special precautions
---
* unicorn (for EY)
* delayed_job
* mysql2
* activerecord-import
* yajl-ruby
* paperclip
* aws-s3
* typhoeus
* nokogiri (yelp)
* httpclient (yelp)

Deploying on localhost
---
Start the server:
    rails s
    
Start the worker:
    rake jobs:work

Deploying on Engine Yard
---
* First push all changes to Github

* Workers should be automatically started

To just deploy
    ey deploy
    
To do a DB schema reload:
    ey deploy -m "rake db:schema:load"


Testing the API (Endpoints)
---
API Version -> v1

Server root:
    curl "http://localhost:3000"
    
Places:

Kupos:


Foursquare Consumer
---
* CLIENT ID: 2CPOOTGBGYH53Q2LV3AORUF1JO0XV0FZLU1ZSZ5VO0GSKELO
* CLIENT SECRET: W45013QS5ADELZMVZYIIH3KX44TZQXDN0KQN5XVRN1JPJVGB

* Example API Request:
    curl "https://api.foursquare.com/v2/venues/search?ll=40.7,-74&client_id=2CPOOTGBGYH53Q2LV3AORUF1JO0XV0FZLU1ZSZ5VO0GSKELO&client_secret=W45013QS5ADELZMVZYIIH3KX44TZQXDN0KQN5XVRN1JPJVGB"

* Venus API Docs:
http://developer.foursquare.com/venues/

Joyent Proxy
---
IP: 72.2.118.126
SSH Username: jill
SSH Password: fyvnr4exjd
Script Path: /home/jill/web/public/index.php

Heroku Quirks
---
* In order to use the mysql2 gem with RDS, needed to manually type this into the console:
heroku config:add DATABASE_URL=mysql2://friendmash:Lik3aG6@friendmash-production.clhyg7sm4xmb.us-east-1.rds.amazonaws.com/moogle?encoding=utf8

Facebook API Errors
---
    {"error"=>{"type"=>"OAuthException", "message"=>"(#613) Calls to checkin_fql have exceeded the rate of 600 calls per 600 seconds."}} - Throttled LOL
    {"error_code":1,"error_msg":"An unknown error occurred"} - Seems to happen when using multiquery (ids) and there are too many ids

Console Commands
---
    alias mcurlpost='curl -i -H "Accept: application/json" -F "access_token=m0z4AO5qSOtB9Uguk80S2D05eEmng2DfrpAnNGMTJh4.eyJpdiI6IkZ2cFVNbHBSaHByVkswZURhZHF3aFEifQ.F4IKIBxFkQqQQkgEyG5SEeaFVBsPT_d_XGwf88o8j8yQrBX-FliW9ELnioMLEg_8quMqc5rQZvOoiszxnXx6M4kfrWON748kVzQE4CS-Vg5Nuqjfg_IAMt3d4P_judBKoG_xAlGFXWQg-tiXwT_UDA"'

How to use Git
---
* check status of repo

git status
  
* add all files to be committed

git add .

* commit all files

git commit -am "your commit message"
  
* get most recent changes from origin/master

git pull
  
* push all locally committed changes to origin/master

git push
  
* in case your shit is all fucked up, this will reset it (careful to not lose local stuff that isn't committed yet)

git reset HEAD --hard
  
Cool Git .profile Stuff
---
    # Set git autocompletion and PS1 integration
    if [ -f /usr/local/git/contrib/completion/git-completion.bash ]; then
      . /usr/local/git/contrib/completion/git-completion.bash
    fi
    GIT_PS1_SHOWDIRTYSTATE=true

    if [ -f /opt/local/etc/bash_completion ]; then
        . /opt/local/etc/bash_completion
    fi

    PS1='\[\033[32m\]\u@\h\[\033[00m\]:\[\033[34m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '

    export CLICOLOR=1
    export LSCOLORS=ExFxCxDxBxegedabagacad

Code Snippets
---
    begin
    # Your normal code block
    rescue SomeException
    # ... handling exception
    else
    # This part only run if the main code did not throw
    # an exception.
    ensure
    # The very last thing to be run before the clause exit.
    # Code in the ensure clause will always get execute.
    end