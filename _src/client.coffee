socket = require( "./lib/socketclient" )

gphoto2 = require('gphoto2')
GPhoto = new gphoto2.GPhoto2()

console.log "START"

GPhoto.list (list)->
	if not list.length
		console.log( "no cam found" )
		return

	camera = list[0]
	console.log('Found', camera.model)

	socket.listen "takePicture", ( data )->
		camera.takePicture {download: true}, (err, data)->
			if err
				console.error( err )
				return
			socket.send( "image", data )
			return
		return
	return
