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
Blog.newItem (err, blogInstance) ->
	# Do stuff with blogInstance with automatic key

Blog.withKey 'akey', (err, blogInstance) ->
	# Do stuff with blogInstance with set key
```
	
New: Sort command is available on your model to quickly get a list of your items
from a list of keys

```
Blog.sort 'externalSetOfKeys', { alpha: true, skip: 10, take: 5 }, (err, blogs) ->
	# Sort by alphabetical order on the keys, skip 10 records and take 5 records
	blogs[0] == { key: 'key', url: 'url', date: 'date', content: 'content' }
	
Blog.sort 'externalSetOfKeys', { byField: 'url', alpha:true, asc: false }, (err, blogs) ->
	# Sort the keys by the url field of your blogs, in alphabetical descending order
	
Blog.sort 'externalSetOfKeys', { by: 'nosort', getKey: false }, (err, blogs) ->
	# Don't worry about sorting, and don't worry about pulling back the key
```

Get values simply:

```
blogInstance.url (err, url) ->
	console.log url
	
blogInstance.getAll (err, blog) ->
	console.log blog.url
	console.log blog.date
	console.log blog.content
```

You can save values one at a time, or lock for full advantage

```
# Save a value straight away
blogInstance.url 'http://www.google.com', (err) ->
	# Value is saved at this point
	
# Lock and save multiple values at once
blogInstance.lock()
blogInstance.url 'url'
blogInstance.date 'date'
blogInstance.content 'content'
blogInstance.unlock (err) ->
	# All values saved in one call - this is much faster than saving each individually
	
blogInstance.setAll { url: 'url', date: 'date', content: 'content' }, (err) ->
	# All values are saved in one call here too
```

### Installation

```bash
$ npm install redis-model
```

### Benchmark test results

```bash
1000 normal sequential requests done in 79ms
✔ Pure redis (read)
1000 redis-model sequential requests done in 68ms
✔ Redis-Model (read)
500 redis-model sequential requests for two fields done in 46ms
✔ Redis-Model with locking (read)
1000 normal sequential requests done in 62ms
✔ Pure redis (save)
500 redis-model sequential requests for two fields done in 38ms
✔ Redis-Model with locking (save)
```

### License

©2012 Felix Jorkowski and available under the [MIT license](http://www.opensource.org/licenses/mit-license.php):

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.