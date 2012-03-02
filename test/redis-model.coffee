r = require '../lib/redis-model'
redis = r.client
redis.flushall()

class Model extends r.RedisModel
	constructor: ->
		super 'Model'
		@addFields 'field1', 'field2'
		
Model = new Model

class Model2 extends r.RedisModel
	constructor: ->
		super 'Model'
		@addFields 'field1'
		
Model2 = new Model2

exports['newItem'] =
	'Keeps track of latest key': (test) ->
		test.expect 2
		Model.newItem (model) ->
			Model.newItem (mod2) ->
				test.equal model.key, 1
				test.equal mod2.key, 2
				test.done()
		
	'Creates property for a single field': (test) ->
		test.expect 1
		Model2.newItem (model) ->
			test.ok model.field1?, 'Field was not added'
			test.done()
	
	'Creates property for multiple fields': (test) ->	
		test.expect 2
		Model.newItem (model) ->
			test.ok model.field1?, 'Field1 was not added'
			test.ok model.field2?, 'Field2 was not added'
			test.done()
			
exports['withKey'] =
	'Sets the correct key': (test) ->
		test.expect 1
		Model.withKey 'id', (model) ->
			test.equal model.key, 'id'
			test.done()
			
	'Creates property for a single field': (test) ->
		test.expect 1
		Model2.withKey 'id', (model) ->
			test.ok model.field1?, 'Field was not added'
			test.done()
	
	'Creates property for multiple fields': (test) ->	
		test.expect 2
		Model.withKey 'id', (model) ->
			test.ok model.field1?, 'Field1 was not added'
			test.ok model.field2?, 'Field2 was not added'
			test.done()

exports['BaseModel'] =
	'Not locked can write and read': (test) ->
		test.expect 1
		Model.withKey 'id', (model) ->
			model.field1 'newValue', () ->
				Model.withKey 'id', (model2) ->
					model2.field1 (val) ->
						test.equal val, 'newValue', 'The value set on the object was not saved'
						test.done()
						
	'Locked can write and read in same object': (test) ->
		test.expect 1
		Model.withKey 'id', (model) ->
			model.lock()
			model.field1 'otherValue'
			model.field1 (val) ->
				test.equal val, 'otherValue', 'The value on the object is not saved'
				test.done()
	
	'Locked does not save': (test) ->
		test.expect 1
		Model.withKey 'otherid', (model) ->
			model.lock()
			model.field1 'foo'
			Model.withKey 'otherid', (mod2) ->
				mod2.field1 (val) ->
					test.equal val, null, 'The value on the object has been saved when it shouldnt have'
					test.done()		
					
	'Unlocking does save': (test) ->
		test.expect 1
		Model.withKey 'otherid', (model) ->
			model.lock()
			model.field1 'foo'
			model.unlock ->
				Model.withKey 'otherid', (mod2) ->
					mod2.field1 (val) ->
						test.equal val, 'foo', 'The value on the object should have been saved'
						test.done()		
						
	'Can save multiple fields at once': (test) ->
		test.expect 2
		Model.withKey 'someid', (model) ->
			model.lock()
			model.field1 'bar'
			model.field2 'foobar'
			model.unlock ->
				Model.withKey 'someid', (mod2) ->
					mod2.field1 (val) ->
						mod2.field2 (val2) ->
							test.equal val, 'bar', 'The value on the object should have been saved'
							test.equal val2, 'foobar', 'The value on the object should have been saved'
							test.done()		

exports['Complete'] = (test) ->
	# This is a dummy test to finish off the tests
	redis.flushall ->
		redis.quit()
		test.done()
