#!/bin/bash
/usr/bin/scl enable ruby193 "gem install rspec --version 1.3.0 --no-rdoc --no-ri" ;           /usr/bin/scl enable ruby193 "gem install fakefs --no-rdoc --no-ri" ;           /usr/bin/scl enable ruby193 "gem install httpclient --version 2.3.2 --no-rdoc --no-ri" ; touch /opt/gem.init
