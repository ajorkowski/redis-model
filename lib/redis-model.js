(function() {
  var BaseModel, RedisModel;
  var __slice = Array.prototype.slice;

  module.exports = RedisModel = (function() {

    function RedisModel(redisClient, _type) {
      this.redisClient = redisClient;
      this._type = _type;
      this._idCount = this._type + '_CurrentId';
      this._fields = [];
    }

    RedisModel.prototype.addFields = function() {
      var name, names, _i, _len;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        name = names[_i];
        if (this._fields.indexOf(name) > -1) {
          throw new Error('Field is already defined');
        }
        this._fields.push(name);
      }
      return this;
    };

    RedisModel.prototype.withKey = function(key, cb) {
      var err, model;
      if (!(this._type != null)) {
        err = 'The type of the model is not defined';
      } else {
        model = new BaseModel(this._fields, this.redisClient, this._type, key);
      }
      if (cb != null) return cb(err, model);
    };

    RedisModel.prototype.newItem = function(cb) {
      var _this = this;
      if (!(this._type != null)) {
        if (cb != null) cb('The type of the model is not defined');
        return;
      }
      return this.redisClient.incr(this._idCount, function() {
        return _this.redisClient.get(_this._idCount, function(err, id) {
          var model;
          if (!(err != null)) {
            model = new BaseModel(_this._fields, _this.redisClient, _this._type, id);
            if (cb != null) return cb(err, model);
          }
        });
      });
    };

    return RedisModel;

  })();

  BaseModel = (function() {
    var getField, setField, setFunction;

    function BaseModel(fields, redisClient, _type, key) {
      var field, _i, _len;
      this.redisClient = redisClient;
      this._type = _type;
      this.key = key;
      this._isLocked = false;
      this._innerObj = {};
      this._key = this._type + '_' + this.key;
      for (_i = 0, _len = fields.length; _i < _len; _i++) {
        field = fields[_i];
        this[field] = setFunction(this, field);
      }
    }

    BaseModel.prototype.lock = function() {
      return this._isLocked = true;
    };

    BaseModel.prototype.unlock = function(cb) {
      if (this._isLocked) {
        return this.redisClient.hmset(this._key, this._innerObj, function(err, res) {
          this._innerObj = {};
          this._isLocked = false;
          return cb(err, res);
        });
      }
    };

    BaseModel.prototype.getAll = function(cb) {
      var self;
      self = this;
      return this.redisClient.hgetall(this._key, function(err, res) {
        var result;
        if (!(err != null)) result = self.extendObjs(self._innerObj, res);
        return cb(err, res);
      });
    };

    getField = function(self, field, cb) {
      var _ref;
      if (self._key != null) {
        if (self._innerObj[field] != null) {
          if (cb != null) return cb(null, self._innerObj[field]);
        } else {
          return self.redisClient.hget([self._key, field], function(err, res) {
            if (cb != null) return cb(err, res);
          });
        }
      } else {
        if (cb != null) {
          return cb(null, (_ref = self._innerObj[field]) != null ? _ref : null);
        }
      }
    };

    setField = function(self, field, value, cb) {
      value = value != null ? value : null;
      if (self._isLocked) {
        self._innerObj[field] = value;
        if (cb != null) return cb();
      } else {
        if (value != null) {
          return self.redisClient.hset([self._key, field, value], function(err, res) {
            if (cb != null) return cb(err, res);
          });
        } else {
          return self.redisClient.hdel([self._key, field], function(err, res) {
            if (cb != null) return cb(err, res);
          });
        }
      }
    };

    setFunction = function(self, field) {
      return function(value, cb) {
        var hasValue;
        hasValue = true;
        if (!(value != null) || typeof value === 'function') {
          cb = value;
          hasValue = false;
        }
        if (hasValue) {
          return setField(self, field, value, cb);
        } else {
          return getField(self, field, cb);
        }
      };
    };

    BaseModel.prototype.extendObjs = function(obj1, obj2) {
      var key, obj3, val;
      obj3 = {};
      for (key in obj2) {
        val = obj2[key];
        obj3[key] = obj2[key];
      }
      for (key in obj1) {
        val = obj1[key];
        if (obj1[key] != null) obj3[key] = obj1[key];
      }
      return obj3;
    };

    return BaseModel;

  })();

}).call(this);
