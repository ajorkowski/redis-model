r = require '../lib/redis-model'
redis = r.client
redis.flushall()

class Model extends r.RedisModel
	constructor: ->
		super 'Model'
		@addFields 'field1', 'field2'
		
Model = new Model

exports['Pure redis (read)'] = (test) ->
	count = 0
	redis.hset 'MODEL_id', 'field1', 'value', ->
		startTime = new Date
		do rec = () ->
			if count > 1000
				console.log "1000 normal sequential requests done in #{new Date - startTime}ms"
				test.done()
			else
				count++
				redis.hget 'id', 'field1', ->
					rec()
					
exports['Redis-Model (read)'] = (test) ->
	count = 0
	Model.withKey 'benchmarkid', (model) ->
		model.field1 'value', ->
			startTime = new Date
			do rec = () ->
				if count > 1000
					console.log "1000 redis-model sequential requests done in #{new Date - startTime}ms"
					test.done()
				else
					count++
					model.field1 (val) ->
						rec()
				
exports['Pure redis (save)'] = (test) ->
	count = 0
	startTime = new Date
	do rec = () ->
		if count > 1000
			console.log "1000 normal sequential requests done in #{new Date - startTime}ms"
			test.done()
		else
			count++
			redis.hset 'MODEL_id2', 'field1', 'value', ->
				rec()
						
exports['Redis-Model with locking (save)'] = (test) ->
	count = 0
	Model.withKey 'benchmarkid2', (model) ->
		startTime = new Date
		do rec = () ->
			if count > 500
				console.log "500 redis-model sequential requests for two fields done in #{new Date - startTime}ms"
				test.done()
			else
				count++
				model.lock()
				model.field1 'val'
				model.field2 'val2'
				model.unlock ->
					rec()	

exports['Complete'] = (test) ->
	# This is a dummy test to finish off the tests
	redis.flushall ->
		redis.quit()
		test.done()
