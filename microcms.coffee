@Snippets = new Meteor.Collection("Snippets")

generateHexId = -> (Math.random()+1).toString(36).substring(2)

Router.route '/', -> 
	@render 'edit'
# Router.route '/:id', -> @render 'view', 
	# data: -> Snippets.findOne({'id': @params.id})
Router.route '/:id', -> 
	content = Snippets.findOne({'id': @params.id})?.content
	@response.end(content + '\n')
, where: 'server'
Router.route '/:id/:password', 
	name: 'edit'
	onAfterAction: -> 
		Session.set('snippet', Snippets.findOne({'id': @params.id, 'password': @params.password}))
	action: -> 
		@render 'edit'

if Meteor.isClient

	Template.edit.rendered = ->
		$('#editor').wysiwyg()

	Template.edit.events 
		'click .save-snippet-btn': (evt) ->
			existingSnippet = Session.get('snippet')
			newContent = $('#editor').html()
			callback = (err, snippet) ->
				if snippet
					# TODO: fix when https://github.com/meteor/meteor/issues/2980 is fixed
					# $('#editor').text('')
					# Router.go('edit', {'id': snippet.id, 'password': snippet.password})
					window.location = window.location.origin + "/#{snippet.id}/#{snippet.password}"
			if existingSnippet
				Meteor.call 'updateSnippet', existingSnippet, newContent, callback
			else
				Meteor.call 'createSnippet', newContent, callback

	Template.edit.helpers
		'snippet': -> Session.get('snippet')
		'urlOrigin': -> window.location.origin


if Meteor.isServer

	Meteor.methods
		'createSnippet': (content) ->
			snippet = {'id': generateHexId(), 'password': generateHexId(), 'content': content}
			Snippets.insert(snippet)
			return snippet

		'updateSnippet': (existingSnippet, newContent) ->
			existingSnippet = Snippets.findOne({'id': existingSnippet.id, 'password': existingSnippet.password})
			if existingSnippet
				Snippets.update({'id': existingSnippet.id}, {'$set': {'content': newContent}})
				return Snippets.findOne({'id': existingSnippet.id})
			else
				return null

	# CORS
	Meteor.startup ->
	  WebApp.rawConnectHandlers.use (req, res, next) ->
	    res.setHeader 'Access-Control-Allow-Origin', '*'
	    next()


