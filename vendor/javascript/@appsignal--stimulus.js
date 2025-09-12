// @appsignal/stimulus@1.0.20 downloaded from https://ga.jspm.io/npm:@appsignal/stimulus@1.0.20/dist/esm/index.js

function n(n,r){var e=r.handleError;r.handleError=function(r,t,o){var i=n.createSpan((function(n){return n.setAction((o===null||o===void 0?void 0:o.identifier)||"[unknown Stimulus controller]").setTags({framework:"Stimulus",message:t}).setError(r)}));n.send(i);e&&typeof e==="function"&&e.apply(this,arguments)}}export{n as installErrorHandler};

