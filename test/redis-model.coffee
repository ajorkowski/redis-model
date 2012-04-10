RedisModel = require '../lib/redis-model'
redis = require("redis").createClient()
redis.flushall()

class Model extends RedisModel
	constructor: ->
		super redis, 'Model'
		@addFields 'field1', 'field2'
		
Model = new Model

class Model2 extends RedisModel
	constructor: ->
		super redis, 'Model'
		@addFields 'field1'
		
Model2 = new Model2

exports['newItem'] =
	'Keeps track of latest key': (test) ->
		test.expect 2
		Model.newItem (err, model) ->
			Model.newItem (err2, mod2) ->
				test.equal model.key, 1
				test.equal mod2.key, 2
				test.done()
		
	'Creates property for a single field': (test) ->
		test.expect 1
		Model2.newItem (err, model) ->
			test.ok model.field1?, 'Field was not added'
			test.done()
	
	'Creates property for multiple fields': (test) ->	
		test.expect 2
		Model.newItem (err, model) ->
			test.ok model.field1?, 'Field1 was not added'
			test.ok model.field2?, 'Field2 was not added'
			test.done()
			
exports['withKey'] =
	'Sets the correct key': (test) ->
		test.expect 1
		Model.withKey 'id', (err, model) ->
			test.equal model.key, 'id'
			test.done()
			
	'Creates property for a single field': (test) ->
		test.expect 1
		Model2.withKey 'id', (err, model) ->
			test.ok model.field1?, 'Field was not added'
			test.done()
	
	'Creates property for multiple fields': (test) ->	
		test.expect 2
		Model.withKey 'id', (err, model) ->
			test.ok model.field1?, 'Field1 was not added'
			test.ok model.field2?, 'Field2 was not added'
			test.done()

exports['clearNamespace'] =
	'All keys are cleared': (test) ->
		test.expect 1
		Model.withKey 'id', (e, model) ->
			model.field1 'newValue', () ->
				Model.clearNamespace () ->
					model.field1 (e2, field1) ->
						test.ok not field1?, 'Field1 still exists'
						test.done()
			
exports['BaseModel'] =
	'Not locked can write and read': (test) ->
		test.expect 1
		Model.withKey 'id', (err, model) ->
			model.field1 'newValue', () ->
				Model.withKey 'id', (err2, model2) ->
					model2.field1 (err3, val) ->
						test.equal val, 'newValue', 'The value set on the object was not saved'
						test.done()
						
	'Locked can write and read in same object': (test) ->
		test.expect 1
		Model.withKey 'id', (err, model) ->
			model.lock()
			model.field1 'otherValue'
			model.field1 (err2, val) ->
				test.equal val, 'otherValue', 'The value on the object is not saved'
				test.done()
	
	'Locked does not save': (test) ->
		test.expect 1
		Model.withKey 'otherid', (err, model) ->
			model.lock()
			model.field1 'foo'
			Model.withKey 'otherid', (err2, mod2) ->
				mod2.field1 (err3, val) ->
					test.equal val, null, 'The value on the object has been saved when it shouldnt have'
					test.done()		
					
	'Unlocking does save': (test) ->
		test.expect 1
		Model.withKey 'otherid', (err, model) ->
			model.lock()
			model.field1 'foo'
			model.unlock ->
				Model.withKey 'otherid', (err2, mod2) ->
					mod2.field1 (err3, val) ->
						test.equal val, 'foo', 'The value on the object should have been saved'
						test.done()		
						
	'Can save multiple fields at once via locking': (test) ->
		test.expect 2
		Model.withKey 'someid', (err, model) ->
			model.lock()
			model.field1 'bar'
			model.field2 'foobar'
			model.unlock ->
				Model.withKey 'someid', (err2, mod2) ->
					mod2.field1 (err3, val) ->
						mod2.field2 (err4, val2) ->
							test.equal val, 'bar', 'The value on the object should have been saved'
							test.equal val2, 'foobar', 'The value on the object should have been saved'
							test.done()		
					
	'Can save multiple fields at once via setAll': (test) ->
		test.expect 2
		Model.withKey 'someid', (err, model) ->
			model.setAll { field1: 'barAll', field2: 'foobarAll'}, ->
				Model.withKey 'someid', (err2, mod2) ->
					mod2.field1 (err3, val) ->
						mod2.field2 (err4, val2) ->
							test.equal val, 'barAll', 'The value on the object should have been saved'
							test.equal val2, 'foobarAll', 'The value on the object should have been saved'
							test.done()
							
	'Can load multiple fields at once': (test) ->
		test.expect 2
		Model.withKey 'someid', (err, model) ->
			model.lock()
			model.field1 'bar'
			model.field2 'foobar'
			model.unlock ->
				Model.withKey 'someid', (err2, mod2) ->
					mod2.getAll (err3, obj) ->
						test.equal obj.field1, 'bar', 'The value on the object should have been saved'
						test.equal obj.field2, 'foobar', 'The value on the object should have been saved'
						test.done()
						
	'Get all includes the key': (test) ->
		test.expect 1
		Model.withKey 'someid', (err, model) ->
			model.getAll (err2, obj) ->
				console.log obj.key
				test.equal obj.key, 'someid', 'getAll did not return the key'
				test.done()

exports['Complete'] = (test) ->
	# This is a dummy test to finish off the tests
	redis.flushall ->
		redis.quit()
		test.done()
