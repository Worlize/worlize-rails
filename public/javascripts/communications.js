flashName = "FlashClient";
worlizeDebug = false;

function WorlizeCommunications(options) {
  var self = this;
  this.socket = null;
  this.eventListeners = {};
  this.debug = options && options['debug'] && window.console && window.console.log;
}

WorlizeCommunications.getInstance = function() {
  if (!WorlizeCommunications.instance) {
    if (worlizeDebug) {
      console.log("Generating instance");
    }
    WorlizeCommunications.instance = new WorlizeCommunications({debug: worlizeDebug});
  }
  return WorlizeCommunications.instance;
};

WorlizeCommunications.prototype = {
  connect: function(serverid) {
    if (this.debug) {
      console.log("Connecting to " + serverid);
    }
    var self = this;
    if (this.socket && this.socket.connected) {
      this.disconnect();
    }
    
    if (!serverid) {
      throw new Error("You must specify a server id");
    }

    var isSecureConnection = document.location.protocol.indexOf('https') != -1;
    if (this.debug) {
      console.log("Secure connection: " + isSecureConnection);
    }
    
    this.socket = new io.Socket(null, {
      transports: ['websocket','htmlfile'], // No Firefox Support for now!! :-(
      rememberTransport: false,
      resource: serverid,
      secure: isSecureConnection,
      port: isSecureConnection ? 443 : 80
    });

    this.socket.addEvent('message', function(data) {
      if (self.debug) {
        console.log("Incoming Message",data);
      }
      var decodedMessage;
      try {
          decodedMessage = JSON.parse(data)
      }
      catch(e) {
        /* do nothing */
        return;
      }
      self.dispatchEvent('message', decodedMessage);
    });
    this.socket.on('connect', function() {
      if (self.debug) {
        console.log("Connected");
      }
      self.dispatchEvent('connect');
    });
    this.socket.addEvent('disconnect', function() {
      // alert("Disconnected!!");
      if (self.debug) {
        console.log("Disconnected");
      }
      self.dispatchEvent('disconnect');
    });

    this.currentServerId = serverid;
    // console.log("Connecting to serverid " + serverid)

    this.socket.connect();
    
  },
  disconnect: function() {
    if (this.debug) {
      console.log("Disconnect requested");
    }
    this.send({
        msg: "disconnect"
    });
    this.socket.disconnect();
  },
  send: function(message) {
    if (this.debug) {
      console.log("Sending message: ", message);
    }
    this.socket.send(JSON.stringify(message));
  },
  
  addEventListener: function(event, closure) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    this.eventListeners[event].push(closure);
  },
  removeEventListener: function(event, closure) {
    if (!this.eventListeners[event]) {return;}
    var listeners = this.eventListeners[event];
    var index = listeners.indexOf(closure);
    if (index != -1) {
      listeners.splice(index, 1);
    }
  },
  dispatchEvent: function(event) {
    if (!this.eventListeners[event]) {return;}
    var listeners = this.eventListeners[event];
    args = [];
    for (var i=1,len=arguments.length; i<len; i++) {
      args[i-1] = arguments[i];
    }
    for (var index in listeners) {
      var closure = listeners[index];
      if (typeof(closure) === 'function') {
        closure.apply(window, args);
      }
    }
  }
};

function getSWF(movieName) {
    if (navigator.appName.indexOf("Microsoft") != -1) {
        return window[movieName]
    }
    else {
        return document[movieName]
    }
}

function worlizeInitialize() {
  if (worlizeDebug) {
    console.log("initializing worlize communications");
  }
  comm = WorlizeCommunications.getInstance();
  comm.addEventListener('message', function(data) {
    // console.log("data!", data);
    getSWF(flashName).handleMessage(data);
  });
  comm.addEventListener('connect', function() {
    // console.log("Connected");
    getSWF(flashName).handleConnect();
  });
  comm.addEventListener('disconnect', function() {
    // console.log("Disconnected");
    getSWF(flashName).handleDisconnect();
  });            
}

function worlizeConnect(serverid) {
  comm.connect(serverid);
}

function worlizeDisconnect() {
  comm.disconnect();
}

function worlizeSend(message) {
  comm.send(message);
}
