@Snippets = new Meteor.Collection("Snippets")

generateHexId = -> (Math.random()+1).toString(36).substring(2)

Router.route '/', -> 
	@render 'edit'
Router.route '/:id', -> @render 'view', 
	data: -> Snippets.findOne({'id': @params.id})
Router.route '/:id/:password', 
	name: 'edit'
	onAfterAction: -> 
		Session.set('snippet', Snippets.findOne({'id': @params.id, 'password': @params.password}))
	action: -> 
		@render 'edit'

if Meteor.isClient

	Template.edit.rendered = ->
		$('#editor').wysiwyg()
		$('#editor').html('')

	Template.edit.events 
		'click .save-snippet-btn': (evt) ->
			Session.set('updated', false)
			existingSnippet = Session.get('snippet')
			callback = (err, snippet) ->
				if snippet
					Router.go("edit", {'id': snippet.id, 'password': snippet.password})
					Session.set('updated', true)
			if existingSnippet
				Meteor.call 'updateSnippet', existingSnippet, $('#editor').html(), callback
			else
				Meteor.call 'createSnippet', $('#editor').html(), callback

	Template.edit.helpers
		'updated': -> Session.get('updated')
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



