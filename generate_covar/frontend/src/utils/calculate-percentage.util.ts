import {StationReport} from "../domain/station-report.interface";
import {Variant} from "../domain/variant.enum";

export const calculatePercentage = (records: StationReport[]): Record<Variant, number> => {
    const totalMap = records.reduce((total, current) => {
        return {
            [Variant.Omicron]: total[Variant.Omicron] + current.Omicron,
            [Variant.Alpha]: total[Variant.Alpha] + current.Alpha,
            [Variant.Beta]: total[Variant.Beta] + current.Beta,
            [Variant.Gamma]: total[Variant.Gamma] + current.Gamma,
            [Variant.Delta]: total[Variant.Delta] + current.Delta,
            [Variant.Wild]: total[Variant.Wild] + current.Wild,
        };
    }, {
        [Variant.Alpha]: 0, [Variant.Omicron]: 0, [Variant.Beta]: 0, [Variant.Gamma]: 0,
        [Variant.Delta]: 0, [Variant.Wild]: 0
    });
    const total = Object.values(totalMap).reduce((t, c) => t + c, 0);

    return {
        [Variant.Omicron]: totalMap[Variant.Omicron] / total,
        [Variant.Alpha]: totalMap[Variant.Alpha] / total,
        [Variant.Beta]: totalMap[Variant.Beta] / total,
        [Variant.Gamma]: totalMap[Variant.Gamma] / total,
        [Variant.Delta]: totalMap[Variant.Delta] / total,
        [Variant.Wild]: totalMap[Variant.Wild] / total,
    };
}
