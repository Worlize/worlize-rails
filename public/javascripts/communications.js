flashName = "FlashPalace";

io.setPath("/socket-io/");

function WorlizeCommunications(options) {
  var self = this;
  this.socket = null;
  this.eventListeners = {};

  this.socket = new io.Socket();

  this.socket.addEvent('message', function(data) {
    self.dispatchEvent('message', data);
  });
  this.socket.addEvent('connect', function() {
    self.dispatchEvent('connect');
  });
  this.socket.addEvent('disconnect', function() {
    self.dispatchEvent('disconnect');
  });
}

WorlizeCommunications.getInstance = function() {
  if (!WorlizeCommunications.instance) {
    WorlizeCommunications.instance = new WorlizeCommunications();
  }
  return WorlizeCommunications.instance;
};

WorlizeCommunications.prototype = {
  connect: function(serverid) {
    var self = this;
    if (this.socket && this.socket.connected) {
      this.disconnect();
    }

    if (!serverid) {
      throw new Error("You must specify a server id");
    }

    this.socket = new io.Socket(null, {
      // transports: ['xhr-polling'],
      rememberTransport: false,
      resource: serverid,
      port:80
    });

    this.currentServerId = serverid;
    // console.log("Connecting to serverid " + serverid)

    this.socket.connect();
    
  },
  disconnect: function() {
    this.send({
        msg: "disconnect"
    });
    this.socket.disconnect();
  },
  send: function(message) {
    this.socket.send(message);
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
  // console.log("initializing worlize communications");
  comm = WorlizeCommunications.getInstance();
  comm.addEventListener('message', function(data) {
    // console.log("Whee, data!", data);
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
