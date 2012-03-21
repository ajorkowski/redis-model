module.exports = class RedisModel
	constructor: (@redisClient, @_type) ->
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
			err = 'The type of the model is not defined'
		else
			model = (new BaseModel @_fields, @redisClient, @_type, key)
		if cb?
			cb err, model
	
	newItem: (cb) ->
		if not @_type?
			if cb?
				cb 'The type of the model is not defined'
			return
			
		@redisClient.incr @_idCount, () =>
			@redisClient.get @_idCount, (err, id) =>
				if not err?
					model = (new BaseModel @_fields, @redisClient, @_type, id)
		  	if cb?
		  		cb err, model
	
class BaseModel
	constructor: (fields, @redisClient, @_type, @key) ->
		@_isLocked = false
		@_innerObj = {}
		@_key = @_type + '_' + @key 
		for field in fields
			this[field] = setFunction this, field
			
	lock: () ->
	  @_isLocked = true
	  
	unlock: (cb) -> 
		if @_isLocked
	  	@redisClient.hmset @_key, @_innerObj, (err, res) ->
	  		@_innerObj = {}
	  		@_isLocked = false
	  		cb err, res
	  		
	getAll: (cb) ->
		self = this
		@redisClient.hgetall @_key, (err, res) ->
			if not err?
				result = self.extendObjs self._innerObj, res
			cb err, res

	# ------------------------------------------------
	# Private functions
	# ------------------------------------------------
	getField = (self, field, cb) ->
		# If we dont have a key then the value will be null
		# note we dont really care about @_isLocked here
		# as that is only for saving
		if self._key?
			if self._innerObj[field]?
				if cb?
					cb null, self._innerObj[field]
			else
				self.redisClient.hget [self._key, field], (err, res) ->
					if cb?
						cb err, res
		else
			if cb?
				cb null, self._innerObj[field] ? null		

  # If we are locked then do not save a value straight away
	setField = (self, field, value, cb) ->
		value = value ? null
	    
		if self._isLocked
			self._innerObj[field] = value
			if cb?
				cb()
		else
			if value?
				self.redisClient.hset [self._key, field, value], (err, res) ->
					if cb?
						cb err, res
			else
				self.redisClient.hdel [self._key, field], (err, res) ->
					if cb?
						cb err, res
						
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
	
	extendObjs: (obj1, obj2) ->
		obj3 = {}
		for key, val of obj2
			obj3[key] = obj2[key]
		for key, val of obj1
			if obj1[key]?
				obj3[key] = obj1[key]
		return obj3

