import React from "react";
import {Variant} from "../domain/variant.enum";
import FilterCard from "./FilterCard";

export interface FilterSelectorProps {
    selected: Variant[];
    selectionClearHandler: () => void;
    selectionToggleHandler: (variant: Variant) => void;
    variantNumbers: Record<Variant, number>;
    percentageReport: Record<Variant, number>;
}


function FilterSelector(props: FilterSelectorProps): JSX.Element {
    const renderedVariants: Variant[] = [
        Variant.Alpha,
        Variant.Beta,
        Variant.Gamma,
        Variant.Delta,
        Variant.Omicron,
        Variant.Wild
    ];

    return <div>
        <div className="filters__container">
            {renderedVariants.map(variant => <FilterCard
                number={props.variantNumbers[variant]}
                key={variant}
                change={props.percentageReport[variant]}
                variant={variant}
                selected={props.selected.indexOf(variant) !== -1}
                selectionChange={() => props.selectionToggleHandler(variant)}/>)}
            <div className={`filter-card__container filter-card__container--wide${props.selected.length === renderedVariants.length ? "" : " filter-card__container--inactive"}`}
                onClick={() => props.selectionClearHandler()}
            >
                <div className="filter-card__stripe" style={{backgroundColor: "black"}}/>
                <div className="filter-card__data">
                    <h4>{Object.values(props.variantNumbers).reduce((total, current) => total + current, 0)}</h4>
                    <h6></h6>
                </div>
                <p className="filter-card__name">
                    Wszystkie
                </p>
            </div>
        </div>

        <p className="filters__info">
            ↑ Naciśnij wariant, żeby filtrować wyniki.
        </p>
    </div>;
}

export default FilterSelector;
