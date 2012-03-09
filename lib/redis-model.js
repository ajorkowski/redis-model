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
      if (!(this._type != null)) {
        throw new Error('The type of the model is not defined');
      }
      return cb(new BaseModel(this._fields, this.redisClient, this._type, key));
    };

    RedisModel.prototype.newItem = function(cb) {
      var _this = this;
      if (!(this._type != null)) {
        throw new Error('The type of the model is not defined');
      }
      return this.redisClient.incr(this._idCount, function() {
        return _this.redisClient.get(_this._idCount, function(err, id) {
          return cb(new BaseModel(_this._fields, _this.redisClient, _this._type, id));
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
        this.redisClient.hmset(this._key, this._innerObj, function(err, res) {
          return cb();
        });
        this._innerObj = {};
        return this._isLocked = false;
      }
    };

    getField = function(self, field, cb) {
      var _ref;
      if (self._key != null) {
        if (self._innerObj[field] != null) {
          return cb(self._innerObj[field]);
        } else {
          return self.redisClient.hget([self._key, field], function(err, res) {
            return cb(res);
          });
        }
      } else {
        return cb((_ref = self._innerObj[field]) != null ? _ref : null);
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
            if (cb != null) return cb();
          });
        } else {
          return self.redisClient.hdel([self._key, field], function(err, res) {
            if (cb != null) return cb();
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

    return BaseModel;

  })();

}).call(this);
