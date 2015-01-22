
_ = require( "lodash" )

config = require( "../lib/config" )
utils = require( "../lib/utils" )


class ModelUser extends require( "./_rest_tunnel" )

	urlbase: "/users"

	ERRORS: =>
		@extend super, 
			"ENOTFOUND": [ 404, "User not found." ]

module.exports = new ModelUser()