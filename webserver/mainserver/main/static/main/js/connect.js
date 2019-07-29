/*
 * connect.js
 * This script determines whether or not the user is connected to the bso_dev 
 * SQL Server by creating an AJAX GET request to connect.html.
 * 
 */

const timerInterval = 1000; // 1000 milliseconds in a second
const timeoutLimit = 5000; // timeout in 5 seconds
let message = ''; // used when updating the text in the connectmsg bar
const connectmsgselector = "#connectmsg"; // element containing connection info
const connectmsgsuccess = 'You are connected!';
const connectmsgfail = 'You are not connected to the database. Try enabling your VPN and then refreshing your browser.';
let attemptFinished = false;  // determines when we're done getting information from connect.html
let i = 5; // 5 * 1s = 5s timeout
const connectselector = 'connect';
const connectedtrueselector = 'connected-true';
const connectedfalseselector = 'connected-false';

let connectionTimer = setInterval(function() {

    $(connectmsgselector).text("Connecting in " + i + "s...");
    i--;
    if (i <= 0 || attemptFinished) {
        $(connectmsgselector).text(message);
        clearInterval(connectionTimer);     
    }

}, timerInterval);

$.get(connectselector, function(result) {
    message = result;
    // Determine status text to display based on the contents of connect.html
    if( result == connectmsgfail ) {
        attemptFinished = true;
        // if this line of code executes, it's after the setTimeout function runs
        $(connectmsgselector).text(message);
    } else {
        attemptFinished = true;
        $(connectmsgselector).text(message);        
        $(connectmsgselector).addClass(connectedtrueselector);
    }
    return result;
})

setTimeout(function() {
    // executes line of code within 5 seconds of rendering
    // if not connected within 5 seconds, we are not connected
    if( $(connectmsgselector).text() != connectmsgsuccess ) {
        attemptFinished = true;
        message = connectmsgfail;
        $(connectmsgselector).text(connectmsgfail);        
        $(connectmsgselector).addClass(connectedfalseselector);
    }
}, timeoutLimit);