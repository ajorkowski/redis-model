# redis-model

A simple object wrapper over the hash type in redis.

### Usage

Define your own models, note the second argument in the super call is used to define the namespace of your model:

```
redis = (require 'redis').createClient()
RedisModel = require 'redis-model'

class Blog extends RedisModel
	constructor: ->
		super redis, 'Blog'
		@addFields 'url', 'date', 'content'
```

Create instances with automatic keys, or use your own:

```
Blog.newItem (blogInstance) ->
	# Do stuff with blogInstance with automatic key

Blog.withKey 'akey', (blogInstance) ->
	# Do stuff with blogInstance with set key
```
	
Get values simply:

```
blogInstance.url (url) ->
	console.log url
```

You can save values one at a time, or lock for full advantage

```
# Save a value straight away
blogInstance.url 'http://www.google.com', ->
	# Value is saved at this point
	
# Lock and save multiple values at once
blogInstance.lock()
blogInstance.url 'url'
blogInstance.date 'date'
blogInstance.content 'content'
blogInstance.unlock ->
	# All values saved in one call - this is much faster than saving each individually
```

### Installation

```bash
$ npm install redis-model
```

### Benchmark test results

```bash
1000 normal sequential requests done in 44ms
✔ Pure redis (read)
1000 redis-model sequential requests done in 30ms
✔ Redis-Model (read)
1000 normal sequential requests done in 37ms
✔ Pure redis (save)
500 redis-model sequential requests for two fields done in 19ms
✔ Redis-Model with locking (save)
```

### License

©2012 Felix Jorkowski and available under the [MIT license](http://www.opensource.org/licenses/mit-license.php):

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.