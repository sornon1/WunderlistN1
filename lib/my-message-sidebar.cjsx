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
           redirect_uri: "yourredirecturlhere",  
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
    accessToken = localStorage.getItem("wunderlist_token")
    if accessToken and accessToken != ""
      content = @_renderAddToWunderlist()
    else
      content = @_renderContent()
    <div className="my-message-sidebar">
      {content}
    </div>

  _renderContent: =>
    <div className="wunderlist-sidebar" style={display: "inline-block"}>
        <p className="headingText">Add your email as tasks </p>
        <div className="button" onClick={@_loginToWunderlist}><p>Login to Wunderlist</p></div>
    </div>

  _renderAddToWunderlist: =>

    <div className="wunderlist-sidebar">
      <input className="textBox" type="text" id="taskName" placeholder={@state.thread.subject}/>
      <input className="textBox" type="radio" name=
      <div className="buttonFullWidth" onClick={@_addToWunderlistPost}><p>Add to Wunderlist</p></div>
        <div className="transparentButton" onClick={@_logoutWunderlist}><p>Logout from Wunderlist</p></div>
      </div>
    </div>

  s4: ->
     Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)

  guidCreate: () ->
     "#{@s4()}#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}#{@s4()}#{@s4()}"

  _addToWunderlistPost: =>
     accessToken = localStorage.getItem("wunderlist_token")
     taskName = document.getElementById('taskName').value + @state.thread.subject
     payload = { "title": taskName , "list_id":  }

     if accessToken
       request
       .post("https://a.wunderlist.com/api/v1/tasks")
       .send(payload)
       .set("Content-Type","application/json")
       .set("X-Access-Token",accessToken)
       .set("X-Client-ID",options.client_id)
       .end(@handleAddToWunderlistResponse)

  _logoutWunderlist: =>
    localStorage.removeItem("wunderlist_token")
    @forceUIUpdate()


  forceUIUpdate: =>
    @setState(@_getStateFromStores())

  handleAccessTokenResponse : (err, response) =>
    if response and response.ok
        localStorage.setItem('wunderlist_token', response.body.access_token)
        @fetchWunderlistLists()
    else
        console.log err
    authWindow.destroy()
    @forceUIUpdate()

  fetchWunderlistLists : (err,response) =>
     accessToken = localStorage.getItem("wunderlist_token")
     
     if accessToken
       request
       .get("https://a.wunderlist.com/api/v1/lists")
       .set("X-Access-Token",accessToken)
       .set("X-Client-ID",options.client_id)
       .end(@storeWunderlistLists)

  storeWunderlistLists : (err,response) =>
    if response and response.ok
        localStorage.setItem('wunderlist_lists', JSON.stringify(response.body)
        console.log(response.body)
    else
        console.log err
    authWindow.destroy()

  handleAddToWunderlistResponse : (err,response) =>
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
          .post("https://www.wunderlist.com/oauth/access_token")
          .send({ client_id: options.client_id, client_secret: options.client_secret, code: code })
          .set('Content-Type','application/x-www-form-urlencoded')
          .end(@handleAccessTokenResponse)

  _loginToWunderlist: =>
     wunderlistUrl = 'https://www.wunderlist.com/oauth/authorize?'
     state = @guidCreate()
     mainUrl = wunderlistUrl + 'client_id=' + options.client_id + '&redirect_uri=' + options.redirect_uri + '&state=' + state
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
