Config = require( "./config" )

fs = require( "fs" )

class SocketServer extends require( "mpbasic" )( Config )

	# ## defaults
	defaults: =>
		@extend super, {}

	constructor: ->
		super
		@ready = false
		return

	setSocket: ( @socket )=>
		console.log( "CONNECTED" )
		@ready = true

		@socket.on "image", ( data )=>
			fs.writeFile "./_tmp/#{Date.now()}.jpg", data, ( err )=>
				if err
					@error "write file", err
					return
				@emit "image", data
				console.log "NEW IMAGE", data
				return
			return
		return

	takePicture: =>
		if not @socket?
			console.log "no socket connected"
			return
		@socket.emit( "takePicture", {} )
		return

module.exports = new SocketServer()