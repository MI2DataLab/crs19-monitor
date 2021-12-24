import {MapDataSource} from "./map-data-source.interface";
import {StationReport} from "../domain/station-report.interface";
import {Variant} from "../domain/variant.enum";

interface GisaidFormat {
    miasto: string,
    data: string,
    dlugosc: number,
    szerokosc: number,
    omicron: number,
    beta: number,
    gamma: number,
    delta: number,
    other: number,
    alpha: number
}

export class GisaidMapDataSource implements MapDataSource {
    public async fetch(timestampFrom: number): Promise<StationReport[]> {
        const rawData = (await (fetch("/data/gisaid.json").then(resp => resp.json()))) as GisaidFormat[];
        return rawData
            .map(raw => ({
                city: raw.miasto,
                [Variant.Omicron]: raw.omicron || 0,
                [Variant.Alpha]: raw.alpha || 0,
                [Variant.Beta]: raw.beta || 0,
                [Variant.Delta]: raw.delta || 0,
                [Variant.Gamma]: raw.gamma || 0,
                [Variant.Wild]: raw.other || 0,
                lat: raw.szerokosc,
                long: raw.dlugosc,
                timestamp: (new Date(raw.data)).getTime()
            }))
            .filter(record => record.timestamp > timestampFrom);
    }
}
