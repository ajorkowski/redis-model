module.exports = class RedisModel
	constructor: (@_client, @namespace, @_seperator) ->
		@_seperator ?= ':'
		@_idCount = @namespace + @_seperator + 'CurrentId'
		@_fields = []
	
	addFields: (names...) ->
		for name in names
			throw new Error 'Field is already defined' if @_fields.indexOf(name) > -1
			throw new Error "The 'key' field is reserved" if name == 'key'
			throw new Error "The 'namespace' field is reserved" if name == 'namespace'
			@_fields.push name
		# for chaining
		return this
		
	sort: (externalKey, options, cb) ->
		if not options? or typeof options == 'function'
			cb = options
			options = {}
			
		options.getKey ?= true
		options.asc ?= true
		options.alpha ?= false
		options.skip ?= 0
		options.take ?= null
		options.byField ?= null
		options.by ?= null
		
		if options.byField? and options.by?
			return cb 'Cannot sort by a field and by some other method at the same time'
	
		# construct the sort arguments
		sorting = [externalKey]
		
		if options.byField?
			sorting.push 'BY'
			sorting.push @namespace + @_seperator + @_seperator + '*->' + options.byField
			
		if options.by?
			sorting.push 'BY'
			sorting.push options.by
			
		if options.take?
			sorting.push 'LIMIT'
			sorting.push options.skip
			sorting.push options.take
			
		if options.alpha
			sorting.push 'ALPHA'
			
		if not options.asc
			sorting.push 'DESC'
			
		if options.getKey
			sorting.push 'GET'
			sorting.push '#'
			
		for field in @_fields
			sorting.push 'GET'
			sorting.push @namespace + @_seperator + @_seperator + '*->' + field
			
		@_client.sort sorting, (err, res) =>
			if err?
				return cb err
				
			items = []
			item = {}
			noFields = @_fields.length
			if options.getKey
				noFields++
			count = 0
				
			for field in res
				fieldNum = count % noFields
				if options.getKey
					if fieldNum == 0
						item.key = field
					else
						item[@_fields[fieldNum - 1]] = field
				else
					item[@_fields[fieldNum]] = field
				
				# If last field push item and get next
				if fieldNum == noFields - 1
					items.push item
					item = {}
				
				count++
			
			cb null, items
		
	withKey: (key, cb) ->
		if not @namespace?
			err = 'The namespace of the model is not defined'
		else
			model = (new BaseModel @_fields, @_client, @namespace, @_seperator, key)
		if cb?
			cb err, model
	
	newItem: (cb) ->
		if not @namespace?
			if cb?
				cb 'The namespace of the model is not defined'
			return
			
		@_client.multi()
			.incr(@_idCount)
			.get(@_idCount)
			.exec (err, results) =>
				if not err?
					id = results[1]
					model = (new BaseModel @_fields, @_client, @namespace, @_seperator, id)
				if cb?
					cb err, model
					
	clearNamespace: (cb) ->
		@_client.keys @namespace + '*', (e, keys) =>
			if e?
				return cb e
				
			if keys.length == 0
				return cb null
						
			@_client.del keys, cb
	
class BaseModel
	constructor: (@_fields, @_client, @namespace, @_seperator, @key) ->
		@_isLocked = false
		@_innerObj = {}
		@_key = @namespace + @_seperator + @_seperator + @key 
		for field in @_fields
			this[field] = setFunction this, field
			
	lock: () ->
	  @_isLocked = true
	  
	unlock: (cb) -> 
		if @_isLocked
	  	@_client.hmset @_key, @_innerObj, (err, res) ->
	  		if not err?
	  			@_innerObj = {}
	  			@_isLocked = false
	  			
	  		if cb?
	  			cb err, res
	  		
	getAll: (cb) ->
		self = this
		@_client.hgetall @_key, (err, res) ->
			if not err?
				result = self.extendObjs self._innerObj, res
				result.key = self.key
				
			if cb?
				cb err, result

	setAll: (obj, cb) ->
		if @_isLocked
			for field in @_fields
				@_innerObj[field] = obj[field]
			if cb?
				cb()
		else
			multi = @_client.multi()
			setAllInternal @, obj, multi
			multi.exec (err) ->
				if cb?
					cb err
					
	multi: () ->
		self = this
		multi = @_client.multi()
		multi.setAll = (obj) ->
			setAllInternal self, obj, multi
			return multi
			
		multi.setField = (field, value) ->
			if value?
				multi.hset [self._key, field, value]
			else
				multi.hdel [self._key, field]
			return multi
			
		return multi
			
	# ------------------------------------------------
	# Private functions
	# ------------------------------------------------
	setAllInternal = (self, obj, multi) ->
		for field in self._fields
			if obj[field]?
				multi.hset self._key, field, obj[field]
			else
				multi.hdel self._key, field
	
	getField = (self, field, cb) ->
		# If we dont have a key then the value will be null
		# note we dont really care about @_isLocked here
		# as that is only for saving
		if self._key?
			if self._innerObj[field]?
				if cb?
					cb null, self._innerObj[field]
			else
				self._client.hget [self._key, field], (err, res) ->
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
				self._client.hset [self._key, field, value], (err, res) ->
					if cb?
						cb err, res
			else
				self._client.hdel [self._key, field], (err, res) ->
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

