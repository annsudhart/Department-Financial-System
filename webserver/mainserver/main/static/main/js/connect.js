/*
 * connect.js
 * This script determines whether or not the user is connected to the bso_dev 
 * SQL Server by creating an AJAX GET request to connect.html.
 * 
 */


$.get('connect', function(result) {

    // Determine status text to display based on the contents of connect.html
    if( result == "You aren&#39;t connected to the database. Try enabling your VPN and then refreshing your browser." ) {
        $('#connectmsg').text("You aren't connected to the database. Try enabling your VPN and then refreshing your browser.");
    } else {
        $('#connectmsg').text(result);        
        $('#connectmsg').addClass('connected-true');
    }
    return result;
})

setTimeout(function() {
    // if not connected within 5 seconds, we are not connected
    if( $('#connectmsg').text() != 'You are connected!' ) {
        $('#connectmsg').text("You aren't connected to the database. Try enabling your VPN and then refreshing your browser.");        
        $('#connectmsg').addClass('connected-false');
    }
}, 5000);