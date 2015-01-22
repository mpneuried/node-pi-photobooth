socketio = require('socket.io-client')

Config = require( "./config" )

_cnfServer = Config.get( "server" )

class SocketClient extends require( "mpbasic" )( Config )

	# ## defaults
	defaults: =>
		@extend super,
			host: "http://#{_cnfServer.host}:#{_cnfServer.port}"

	constructor: ->
		super
		@socket = socketio( @config.host )
		@on "conenct" , @connected
		return

	connected: =>
		console.log( "CONNECTED" )
		return

	listen: ( name, handler )=>
		@socket.on( name, handler )
		return

	send: ( name, data )=>
		@socket.emit( name, data )
		return

module.exports = new SocketClient()