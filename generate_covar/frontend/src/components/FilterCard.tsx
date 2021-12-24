import React from "react";
import {Variant} from "../domain/variant.enum";
import {COLOR_MAPPING} from "../domain/color-mapping.const";

export interface FilterCardProps {
    number: number;
    change: number;
    variant: Variant;
    selected: boolean;
    selectionChange: () => void;
}

function FilterCard(props: FilterCardProps): JSX.Element {
    return <div className={`filter-card__container${!props.selected ? " filter-card__container--inactive" : ""}`} onClick={() => props.selectionChange()}>
        <div className="filter-card__stripe" style={{backgroundColor: COLOR_MAPPING[props.variant]}}/>
        <div className="filter-card__data">
            <h4>{props.number}</h4>
            <h6>{isNaN(props.change) ? '--' : (parseFloat((props.change * 100).toPrecision(2)) + '')}%</h6>
        </div>
        <p className="filter-card__name">
            {props.variant === Variant.Wild ? 'Inny' : props.variant}
        </p>
    </div>;
}

export default FilterCard;
