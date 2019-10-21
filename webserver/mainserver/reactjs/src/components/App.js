import React from 'react';
import CSRFToken from './csrftoken';
import './App.css';
import InputRows from './inputrows';

class App extends React.Component {
    render() {
        props = window.props;
        let display = props['display'][0] == 'T';
        let values = props['values'];
        let range = props['range'];

        return (
            <form method="POST">
            <CSRFToken cookie={document.cookie}/>
                <InputRows display={display} values={values} range={range}/>
                <input className="button" type="submit" value="Run Program" disabled/>
            </form>
        );
    }
}

export default App;