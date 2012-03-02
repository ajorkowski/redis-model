redis = require('redis').createClient()

module.exports.client = redis

module.exports.RedisModel = class RedisModel
	constructor: (@_type) ->
		@_idCount = @_type + '_CurrentId'
		@_fields = []
	
	addFields: (names...) ->
		for name in names
			throw new Error 'Field is already defined' if @_fields.indexOf(name) > -1
			@_fields.push name
		# for chaining
		return this
	
	withKey: (key, cb) ->
		if not @_type?
			throw new Error 'The type of the model is not defined'
		cb (new BaseModel @_fields, @_type, key)
	
	newItem: (cb) ->
		if not @_type?
			throw new Error 'The type of the model is not defined'
		redis.incr @_idCount, () =>
			redis.get @_idCount, (err, id) =>
		  	cb (new BaseModel @_fields, @_type, id)
	
class BaseModel
	constructor: (fields, @_type, @key) ->
		@_isLocked = false
		@_innerObj = {}
		@_key = @_type + '_' + @key 
		for field in fields
			this[field] = setFunction this, field
			
	lock: () ->
	  @_isLocked = true
	  
	unlock: (cb) -> 
		if @_isLocked
	  	redis.hmset @_key, @_innerObj, (err, res) ->
	  		cb()
	  	@_innerObj = {}
	  	@_isLocked = false

	# ------------------------------------------------
	# Private functions
	# ------------------------------------------------
	getField = (self, field, cb) ->
		# If we dont have a key then the value will be null
		# note we dont really care about @_isLocked here
		# as that is only for saving
		if self._key?
			if self._innerObj[field]?
				cb self._innerObj[field]
			else
				redis.hget [self._key, field], (err, res) ->
					cb res
		else
			cb self._innerObj[field] ? null		

  # If we are locked then do not save a value straight away
	setField = (self, field, value, cb) ->
		value = value ? null
	    
		if self._isLocked
			self._innerObj[field] = value
			if cb?
				cb()
		else
			if value?
				redis.hset [self._key, field, value], (err, res) ->
					if cb?
						cb()
			else
				redis.hdel [self._key, field], (err, res) ->
					if cb?
						cb()
						
	setFunction = (self, field) ->
		(value, cb) ->
			hasValue = true
			if not value? or typeof value == 'function'
				cb = value
				hasValue = false
				
			if hasValue
				setField self, field, value, cb
			else
				getField self, field, cb
