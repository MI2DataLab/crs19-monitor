import React from "react";
import {MenuItem, Select} from "@material-ui/core";

export interface TimeRangeSelectProps {
    selection: Record<number, string>;
    selected: number;
    selectionChange: (timestamp: number) => void;
}

function TimeRangeSelect(props: TimeRangeSelectProps): JSX.Element {
    return <p className="time-range-select">
        Liczba zarejestrowanych przypadków wg wariantów w
        <Select
            style={{marginLeft: "5px", fontSize: "20px", fontFamily: '"Barlow", sans-serif', width: "190px"}}
            value={props.selected}
            onChange={e => props.selectionChange(parseInt(e.target.value as string))}
        >
            {Object.entries(props.selection).map(([key, value]) => <MenuItem key={key} value={parseInt(key)}>{value}</MenuItem>)
            }
            <MenuItem value={0} key={'0'}>całym okresie</MenuItem>
        </Select>
    </p>;
}

export default TimeRangeSelect;
