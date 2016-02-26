{Utils, React,FocusedContentStore} = require 'nylas-exports'
{RetinaImg} = require 'nylas-component-kit'
BrowserWindow = require('electron').remote.BrowserWindow
LocalStorage = require('localStorage')
request  = require('superagent')

authWindow = new BrowserWindow({ width: 800, height: 600, show: false, 'node-integration': false })

class MyMessageSidebar extends React.Component
  @displayName: 'MyMessageSidebar'

  options = {
           client_id: "",
           client_secret: "",
           scopes: ["data:read_write"]
  }

  # Providing container styles tells the app how to constrain
  # the column your component is being rendered in. The min and
  # max size of the column are chosen automatically based on
  # these values.
  @containerStyles:
    order: 1
    flexShrink: 0

  # This sidebar component listens to the FocusedContactStore,
  # which gives us access to the Contact object of the currently
  # selected person in the conversation. If you wanted to take
  # the contact and fetch your own data, you'd want to create
  # your own store, so the flow of data would be:
  #
  # FocusedContactStore => Your Store => Your Component
  #
  constructor: (@props) ->
    @state = @_getStateFromStores()

  componentDidMount: =>
    @unsubscribe = FocusedContentStore.listen(@_onFocusChanged, @)

  _onFocusChanged: ->
    @setState(@_getStateFromStores())

  componentWillUnmount: =>
    @unsubscribe()

  render: =>
    accessToken = localStorage.getItem("todoist_token")
    if accessToken and accessToken != ""
      content = @_renderAddToTodoist()
    else
      content = @_renderContent()
    <div className="my-message-sidebar">
      {content}
    </div>

  _renderContent: =>
    <div className="todoist-sidebar" style={display: "inline-block"}>
        <p className="headingText">Add your email as tasks </p>
        <div className="button" onClick={@_loginToTodoist}><p>Login to Todoist</p></div>
    </div>

  _renderAddToTodoist: =>

    <div className="todoist-sidebar">
      <input className="textBox" type="text" id="taskName" placeholder={@state.thread.subject}/>
      <div className="buttonFullWidth" onClick={@_addToTodoistPost}><p>Add to Todoist</p></div>
      <div style={display: "inline-block"}>
        <div className="transparentButton" onClick={@_logoutTodoist}><p>Logout from Todoist</p></div>
      </div>
    </div>

  s4: ->
     Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)

  guidCreate: () ->
     "#{@s4()}#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}#{@s4()}#{@s4()}"

  _addToTodoistPost: =>
     accessToken = localStorage.getItem("todoist_token")
     uuidVal = @guidCreate()
     temp_idVal = @guidCreate()
     taskName = document.getElementById('taskName').value + @state.thread.subject
     command = [{ type: "item_add", uuid: uuidVal, temp_id: temp_idVal, args: { content: taskName}}]
     payload = { token: accessToken, commands: JSON.stringify(command) }

     if accessToken
       request
       .post("https://todoist.com/API/v6/sync")
       .send(payload)
       .set("Content-Type","application/x-www-form-urlencoded")
       .end(@handleAddToTodoistResponse)


  _logoutTodoist: =>
    localStorage.removeItem("todoist_token")
    @forceUIUpdate()


  forceUIUpdate: =>
    @setState(@_getStateFromStores())

  handleAccessTokenResponse : (err, response) =>
    if response and response.ok
        localStorage.setItem('todoist_token', response.body.access_token)
    else
        console.log err
    authWindow.destroy()
    @forceUIUpdate()

  handleAddToTodoistResponse : (err,response) =>
    if response
       console.log response
    else
       console.log err
    authWindow.destroy()


  handleCallback : (event,oldUrl,newUrl) =>
    raw_code = /code=([^&]*)/.exec(newUrl)
    if raw_code and raw_code.length > 1
      code = raw_code[1]
    else
      code = null

    if code
        request
          .post("https://todoist.com/oauth/access_token")
          .send({ client_id: options.client_id, client_secret: options.client_secret, code: code, redirect_uri: "yourredirecturlhere" })
          .set('Content-Type','application/x-www-form-urlencoded')
          .end(@handleAccessTokenResponse)


  _loginToTodoist: =>
     todoistUrl = 'https://todoist.com/oauth/authorize?'
     mainUrl = todoistUrl + 'client_id=' + options.client_id + '&scope=' + options.scopes
     console.log mainUrl
     authWindow = new BrowserWindow({ width: 800, height: 600, show: false, 'node-integration': false })
     authWindow.loadUrl(mainUrl)
     authWindow.show()
     authWindow.webContents.on('did-get-redirect-request',@handleCallback)


  _renderPlaceholder: =>
    <div> No Data Available </div>

  _getStateFromStores: =>
     thread: FocusedContentStore.focused('thread')


module.exports = MyMessageSidebar
