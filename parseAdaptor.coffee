# Based on Ractive-adaptor-Backbone : https://github.com/RactiveJS/Ractive-adaptors-Backbone

define ['ractive', 'parse'], (Ractive, Parse)->

	class ParseModelWrapper
		constructor : (ractive, model, keypath, prefix)->
			@value = model

			# Save onChange after delay
			saveTimer = null
			model.on 'change', @changeHandler = (model, options)->
				# If options.save is false, then do not save.
				return if options.save is false

				clearTimeout saveTimer
				saveTimer = setTimeout ->
					model.save
						error : (model, error)->
							if error.code is 111  # Invalid type
								[column, type] = _.map error.message.split(','), (message)->
									message.slice(message.lastIndexOf ' ').trim()

								if type is 'string'
									model.save column, model.get(column).toString()

				, 1500

		get : ->
			rv = id : @value.id
			for key, val of @value.attributes
				rv[key] = val
			return rv

		set : (keypath, value)->
			if not @setting and keypath.indexOf '.' is -1
				@value.set keypath, value

		teardown : ->
			@value.off 'change', @changeHandler

		reset : ->
			console.log 'mreset'

	class ParseCollectionWrapper
		constructor : (ractive, collection, keypath)->
			@value = collection

			collection.on 'reset add', =>
				@setting = true
				ractive.set keypath, @get()
				@setting = false

		get : ->
			@value.models

		teardown : ->
			console.log 'teardown'

		reset : ->
			console.log 'RESET', this, @setting
			if @setting
				console.log 'cancel RESET'
				return
			console.log 'cont reset'

	Ractive.adaptors.Parse =
		filter : (object)->
			object instanceof Parse.Object or object instanceof Parse.Collection

		wrap : (ractive, object, keypath, prefix)->
			if object instanceof Parse.Object
				new ParseModelWrapper ractive, object, keypath, prefix
			else
				new ParseCollectionWrapper ractive, object, keypath, prefix
