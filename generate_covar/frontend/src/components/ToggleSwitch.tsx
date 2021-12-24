import React from "react";

export interface ToggleSwitchProps {
    options: string[];
    selected: number;
    selectionChanged: (sel: number) => void
}

function ToggleSwitch(props: ToggleSwitchProps): JSX.Element {
    return <div className="toggle__container">
        <span className={`toggle__option${props.selected === 0 ? " toggle__option--active" : ""}`}
              onClick={() => props.selectionChanged(0)}>{props.options[0]}</span>
        <div className={`toggle__switch${props.selected === 0 ? " toggle__switch--active" : ""}`} onClick={() => props.selectionChanged((props.selected + 1) % 2)}>
            <div className={`toggle__switch-circle${props.selected === 0 ? " toggle__switch-circle--active" : ""}`}/>
        </div>
        <span className={`toggle__option${props.selected === 1 ? " toggle__option--active" : ""}`}
              onClick={() => props.selectionChanged(1)}>{props.options[1]}</span>
    </div>;
}

export default ToggleSwitch;