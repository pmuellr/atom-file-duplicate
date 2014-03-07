# code stolen from https://github.com/atom/go-to-line

fs   = require "fs"
path = require "path"

{$, EditorView, Point, View} = require 'atom'

#-------------------------------------------------------------------------------
module.exports = class FileDuplicateView extends View

  #-----------------------------------------------------------------------------
  @activate: -> new FileDuplicateView

  #-----------------------------------------------------------------------------
  @content: ->
    @div class: 'file-duplicate overlay from-top mini', =>
      @subview 'miniEditor', new EditorView(mini: true)
      @div class: 'message', outlet: 'message'

  #-----------------------------------------------------------------------------
  detaching: false

  #-----------------------------------------------------------------------------
  initialize: ->
    atom.workspaceView.command 'file-duplicate:open', => @open()
    @miniEditor.hiddenInput.on 'focusout', => @detach() unless @detaching
    @on 'core:confirm', => @confirm()
    @on 'core:cancel',  => @detach()

    @miniEditor.preempt 'textInput', (e) =>

  #-----------------------------------------------------------------------------
  open: ->
    orgFileName = atom.workspaceView.find('.tree-view .selected')?.view()?.getPath?()
    stat        = fs.statSync orgFileName
    return unless stat.isFile()

    if @hasParent()
      @detach()
    else
      @attach()

  #-----------------------------------------------------------------------------
  attach: ->
    if editor = atom.workspace.getActiveEditor()
      @storeFocusedElement()
      atom.workspaceView.append(this)
      @message.text("Enter new duplicated file name")
      @miniEditor.focus()

  #-----------------------------------------------------------------------------
  detach: ->
    return unless @hasParent()

    @detaching = true
    miniEditorFocused = @miniEditor.isFocused
    @miniEditor.setText('')

    super

    @restoreFocus() if miniEditorFocused
    @detaching = false

  #-----------------------------------------------------------------------------
  confirm: ->
    @log "in confirm()"

    fileName = @miniEditor.getText()
    @log "   fileName: #{fileName}"

    editorView = atom.workspaceView.getActiveView()

    @detach()

    return unless editorView? and fileName.length

    orgFileName = atom.workspaceView.find('.tree-view .selected')?.view()?.getPath?()
    return unless orgFileName?

    newFileName = path.join path.dirname(orgFileName), path.basename(fileName)

    @log "orgFileName: #{orgFileName}"
    @log "newFileName: #{newFileName}"

    try
        contents = fs.readFileSync orgFileName
        fs.writeFileSync newFileName, contents
    catch err
        @log "#{__filename}: error copying file: #{err}"

  #-----------------------------------------------------------------------------
  storeFocusedElement: ->
    @previouslyFocusedElement = $(':focus')

  #-----------------------------------------------------------------------------
  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.workspaceView.focus()

  #-----------------------------------------------------------------------------
  log: (message)->
      console.log message
