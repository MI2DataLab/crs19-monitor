import {StationReport} from "../domain/station-report.interface";
import {Variant} from "../domain/variant.enum";

export const countVariants = (records: StationReport[]): Record<Variant, number> => ({
    [Variant.Omicron]: records.reduce((total, record) => total + record[Variant.Omicron], 0),
    [Variant.Alpha]: records.reduce((total, record) => total + record[Variant.Alpha], 0),
    [Variant.Beta]: records.reduce((total, record) => total + record[Variant.Beta], 0),
    [Variant.Gamma]: records.reduce((total, record) => total + record[Variant.Gamma], 0),
    [Variant.Delta]: records.reduce((total, record) => total + record[Variant.Delta], 0),
    [Variant.Wild]: records.reduce((total, record) => total + record[Variant.Wild], 0),
});
