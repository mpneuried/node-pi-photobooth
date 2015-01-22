path = require( "path" )

request = require( "request" )
_ = require( "lodash" )

try 
	_gconfig = require( "./config.json" )?.grunt
	if not _gconfig?
		console.log( "INFO: No grunt config in `config.json` found. So use default.\n" )
		_gconfig = {}
catch _e
	if _e.code is "MODULE_NOT_FOUND"
		console.log( "INFO: No `config.json` found. So use default.\n" ) 
	_gconfig = {}

_.defaults( _gconfig, {
	"gettext_path": "/usr/local/opt/gettext/bin/"
})

languageCodes = [ 'de', 'en' ]


module.exports = (grunt) ->
	
	deploy = grunt.file.readJSON( "deploy.json" )
	
	# Project configuration.
	grunt.initConfig
		pkg: grunt.file.readJSON('package.json')
		gconfig: _gconfig
		deploy: deploy
		regarde:

			client:
				files: ["_src/*.coffee", "_src/lib/*.coffee"]
				tasks: [ "update-client" ]

			serverjs:
				files: ["_src/**/*.coffee"]
				tasks: [ "coffee:serverchanged" ]
			
			frontendjs:
				files: ["_src_static/js/**/*.coffee"]
				tasks: [ "build_staticjs" ]

			frontendvendorjs:
				files: ["_src_static/js/vendor/**/*.js"]
				tasks: [ "build_staticjs" ]
			frontendcss:
				files: ["_src_static/css/**/*.styl"]
				tasks: [ "stylus" ]
			
			static:
				files: ["_src_static/static/**/*.*"]
				tasks: [ "build_staticfiles" ]
			
			#i18nserver:
			#	files: ["_locale/**/*.po"]
			#	tasks: [ "build_i18n_server" ]
		
		coffee:
			serverchanged:
				expand: true
				cwd: '_src'
				src:	[ '<% print( _.first( ((typeof grunt !== "undefined" && grunt !== null ? (_ref = grunt.regarde) != null ? _ref.changed : void 0 : void 0) || ["_src/nothing"]) ).slice( "_src/".length ) ) %>' ]
				# template to cut off `_src/` and throw on error on non-regrade call
				# CF: `_.first( grunt?.regarde?.changed or [ "_src/nothing" ] ).slice( "_src/".length )
				dest: ''
				ext: '.js'
			
			frontendchanged:
				expand: true
				cwd: '_src_static/js'
				src:	[ '<% print( _.first( ((typeof grunt !== "undefined" && grunt !== null ? (_ref = grunt.regarde) != null ? _ref.changed : void 0 : void 0) || ["_src_static/js/nothing"]) ).slice( "_src_static/js/".length ) ) %>' ]
				# template to cut off `_src_static/js/` and throw on error on non-regrade call
				# CF: `_.first( grunt?.regarde?.changed or [ "_src_static/js/nothing" ] ).slice( "_src_static/js/".length )
				dest: 'static_tmp/js'
				ext: '.js'
			
			backend_base:
				expand: true
				cwd: '_src',
				src: ["**/*.coffee"]
				dest: ''
				ext: '.js'
			
			frontend_base:
				expand: true
				cwd: '_src_static/js',
				src: ["**/*.coffee"]
				dest: 'static_tmp/js'
				ext: '.js'
			


		clean:
			server:
				src: [ "lib", "modules", "model", "models", "*.js", "release", "test" ]
			
			frontend: 
				src: [ "static", "static_tmp" ]
			mimified: 
				src: [ "static/js/*.js", "!static/js/main.js" ]
			statictmp: 
				src: [ "static_tmp" ]
			
			

		
		stylus:
			standard:
				options:
					"include css": true
				files:
					"static/css/style.css": ["_src_static/css/style.styl"]
					"static/css/login.css": ["_src_static/css/login.styl"]

		
		browserify: 
			main: 
				src: [ 'static_tmp/js/main.js' ]
				dest: 'static/js/main.js'
			login: 
				src: [ 'static_tmp/js/login.js' ]
				dest: 'static/js/login.js'

		copy:
			static:
				expand: true
				cwd: '_src_static/static',
				src: [ "**" ]
				dest: "static/"
			bootstrap_fonts:
				expand: true
				cwd: 'node_modules/bootstrap/dist/fonts',
				src: [ "**" ]
				dest: "static/fonts/"

		uglify:
			options:
				banner: '/*!<%= pkg.name %> - v<%= pkg.version %>\n*/\n'
			staticjs:
				files:
					"static/js/main.js": [ "static/js/main.js" ]
		
		cssmin:
			options:
				banner: '/*! <%= pkg.name %> - v<%= pkg.version %>*/\n'
			staticcss:
				files:
					"static/css/external.css": [ "_src_static/css/*.css", "node_modules/bootstrap/dist/css/bootstrap.css" ]
		
		compress:
			main:
				options: 
					archive: "release/<%= pkg.name %>_deploy_<%= pkg.version.replace( '.', '_' ) %>.zip"
				files: [
						{ src: [ "package.json", "server.js", "modules/**", "lib/**", "static/**", "views/**", "_src_static/css/**/*.styl" ], dest: "./" }
				]
			cli:
				options: 
					archive: "release/<%= pkg.name %>_client_<%= pkg.version.replace( '.', '_' ) %>.zip"
				files: [
						{ src: [ "package_client.json", "client.js", "lib/*", "_docs/*" ], dest: "./" }
				]

		
		sftp:	
			client:
				files:
					"./":  [ "release/<%= pkg.name %>_client_<%= pkg.version.replace( '.', '_' ) %>.zip" ]
				options:
					path: "<%= deploy.targetServerPath %>"
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true
	
			clientconfig:
				files:
					"./":  [ "<%= deploy.configfile %>" ]
				options:
					path: "<%= deploy.targetServerPath %>"
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true
		
		sshexec:
			preparelogfile:
				command: "sudo touch /home/pi/Sites/logs/photobooth-camera-client.log && sudo chmod 666 /home/pi/Sites/logs/photobooth-camera-client.log"
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
			movestartup:
				command: [ "cd <%= deploy.targetServerPath %> && sudo mv -f _docs/photobooth-client /etc/init.d/ && sudo chmod 777 /etc/init.d/photobooth-client" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true

			cleanup:
				command: "rm -rf <%= deploy.targetServerPath %>*"
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
			cleanup_nonpm:
				command: "cd <%= deploy.targetServerPath %> && sudo rm -rf $(ls | grep -v node_modules)"
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
			unzip:
				command: [ "cd <%= deploy.targetServerPath %> && unzip -u -q -o release/<%= pkg.name %>_client_<%= pkg.version.replace( '.', '_' ) %>.zip", "ls" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true
			removezip:
				command: [ "cd <%= deploy.targetServerPath %> && rm -f release/<%= pkg.name %>_client_<%= pkg.version.replace( '.', '_' ) %>.zip" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true
			donpminstall:
				command: [ "cd <%= deploy.targetServerPath %> && npm install --production" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true
			renameconfig:
				command: [ "cd <%= deploy.targetServerPath %> && mv <%= deploy.configfile %> config.json" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true
			renamepackage:
				command: [ "cd <%= deploy.targetServerPath %> && mv <%= deploy.packagefile %> package.json" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"
					createDirectories: true

			stop:
				command: [ "/etc/init.d/photobooth-client stop" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"

			start:
				command: [ "/etc/init.d/photobooth-client start &" ]
				options:
					host: "<%= deploy.host %>"
					username: "<%= deploy.username %>"
					password: "<%= deploy.password %>"

	# Load npm modules
	grunt.loadNpmTasks "grunt-regarde"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-stylus"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-compress"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-ssh"
	
	
	grunt.loadNpmTasks "grunt-browserify"
	


	# just a hack until this issue has been fixed: https://github.com/yeoman/grunt-regarde/issues/3
	grunt.option('force', not grunt.option('force'))
	
	# ALIAS TASKS
	grunt.registerTask "watch", "regarde"
	grunt.registerTask "default", "build"
	grunt.registerTask "uc", "update-client"
	grunt.registerTask "dc", "deploy-client"
	grunt.registerTask "dcn", "deploy-client-npm"
	
	
	grunt.registerTask "clear", [ "clean:server", "clean:frontend"  ]

	# build the project
	
	grunt.registerTask "build", [ "clean:frontend", "build_server", "build_frontend"  ]
	grunt.registerTask "build-dev", [ "build"  ]

	grunt.registerTask "build_server", [ "coffee:backend_base" ]

	
	grunt.registerTask "build_frontend", [ "build_staticjs", "build_vendorcss", "stylus", "build_staticfiles" ]
	grunt.registerTask "build_staticjs", [ "clean:statictmp", "coffee:frontend_base", "browserify:main", "clean:mimified" ]
	grunt.registerTask "build_vendorcss", [ "cssmin:staticcss" ]
	grunt.registerTask "build_staticfiles", [ "copy:static", "copy:bootstrap_fonts" ]
	

	grunt.registerTask "prepare-client", [ "sshexec:preparelogfile", "sshexec:movestartup" ]

	grunt.registerTask "update-client", [ "compress:cli", "sshexec:cleanup_nonpm", "sftp:client", "sftp:clientconfig", "sshexec:unzip", "sshexec:renamepackage", "sshexec:renameconfig", "sshexec:removezip", "sshexec:stop", "sshexec:start" ]
	grunt.registerTask "deploy-client", [ "build", "update-client" ]
	grunt.registerTask "deploy-client-npm", [ "build", "compress:cli", "sshexec:cleanup", "sftp:client", "sftp:clientconfig", "sshexec:unzip", "sshexec:renamepackage", "sshexec:donpminstall", "sshexec:renameconfig", "sshexec:removezip", "sshexec:stop", "sshexec:start" ]

	grunt.registerTask "release", [ "build", "uglify:staticjs", "compress:main" ]