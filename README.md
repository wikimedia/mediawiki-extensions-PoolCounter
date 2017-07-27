# PoolCounter

## Contributing

### MediaWiki extension

Test the PHP code in PHP via [Composer](https://getcomposer.org/).
<pre>
$ composer install
$ composer test
</pre>

Lint interface messages in Node.js via [npm](https://www.npmjs.com/get-npm):
<pre>
$ npm install
$ npm test
</pre>

### C Daemon

Build using Make. Requires libevent to be installed.
(`libevent-dev` package on Debian-based systems.)
<pre>
$ cd daemon/
$ make install
</pre>

Test the C code in Ruby with Cucumber. Install using [Bundler](https://bundler.io/):
<pre>
$ gem install bundler
$ bundle install

$ cd daemon/
$ make test
</pre>
