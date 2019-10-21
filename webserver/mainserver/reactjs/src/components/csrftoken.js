import React from 'react';

class CSRFToken extends React.Component {
    constructor(props) {
        super(props);
    }

    retrieveToken(cookieData) {
        let csrfStr = (cookieData + "").substring(cookieData.indexOf("csrftoken="));
        if(csrfStr.indexOf(';') != -1) {
            csrfStr = csrfStr.substring(0, csrfStr.indexOf(';'));
        }
        csrfStr = csrfStr.split('=')[1];
        return csrfStr;
    }

    render() {
        let cookie = this.props.cookie;
        return (
            <input type="hidden" name="csrfmiddlewaretoken" value={this.retrieveToken(cookie)}/>
        );
    }
}

export default CSRFToken;