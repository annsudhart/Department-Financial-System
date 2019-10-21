import React from 'react';
import './inputrows.css';

class InputRows extends React.Component {

    constructor(props) {
        super(props);
        this.state = {values: this.props.values};
        this.updateVal = this.updateVal.bind(this);
    }
    
    updateVal(event) {
        console.log(event.target.name);
        console.log(parseInt(event.target.name[5]));
        console.log(event.target.value);
        let i = parseInt(event.target.name[5]);
        let newValues = this.state.values.slice();
        this.setState({
            [i]: event.target.value
        });
    }
    
    renderInputs(itemArray , range, fill) {
        let items = itemArray;
        let inputs;
        if(!fill) {
             inputs = range.map( function(x) {
                return (<div key={x} className="input-row">
                    <span>Input {x}</span>
                    <input type="text" name={"input"+x}/>
                </div>)
            });
        } else {    
            inputs = range.map( (x) => {
                return (<div key={x} className="input-row">
                    <span>Input {x}</span>
                    <input type="text" name={"input"+x} value={items[x-1][1]} onChange={this.updateVal}/>
                </div>)
            });
        }
        return (
            inputs
        );
    }

    render() {
        return (
            <div id="form-container">
                {this.renderInputs(this.state.values, this.props.range, this.props.display)}
            </div>
        );
    }
}

export default InputRows;