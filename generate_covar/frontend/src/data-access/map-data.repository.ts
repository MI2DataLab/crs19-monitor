import {DataSource} from "../domain/data-source.enum";
import {MapDataSource} from "./map-data-source.interface";
import {StationReport} from "../domain/station-report.interface";
import {GisaidMapDataSource} from "./gisaid-map-data-source";
import {PzhMapDataSource} from "./pzh-map-data-source";
import {Variant} from "../domain/variant.enum";

const sourceInstanceFactory = (sourceType: DataSource) => {
    switch (sourceType) {
        case DataSource.GISAID: return new GisaidMapDataSource();
        case DataSource.PZH: return new PzhMapDataSource();
    }
}

export class MapDataRepository {
    private instances: Record<DataSource, MapDataSource | null> = {
        [DataSource.GISAID]: null,
        [DataSource.PZH]: null
    };
    public async getData(timestamp: number, sourceType: DataSource): Promise<StationReport[]> {
        if (this.instances[sourceType] === null) {
            this.instances[sourceType] = sourceInstanceFactory(sourceType);
        }
        const source = this.instances[sourceType] as MapDataSource;
        const data = await source.fetch(timestamp);

        const groupedByLocation = data.reduce((total, current) => {
            if (current.city in total) {
                return {
                    ...total,
                    [current.city]: {
                        ...total[current.city],
                        [Variant.Omicron]: total[current.city][Variant.Omicron] + current[Variant.Omicron],
                        [Variant.Alpha]: total[current.city][Variant.Alpha] + current[Variant.Alpha],
                        [Variant.Beta]: total[current.city][Variant.Beta] + current[Variant.Beta],
                        [Variant.Gamma]: total[current.city][Variant.Gamma] + current[Variant.Gamma],
                        [Variant.Delta]: total[current.city][Variant.Delta] + current[Variant.Delta],
                        [Variant.Wild]: total[current.city][Variant.Wild] + current[Variant.Wild],
                    }
                }
            } else {
                return {
                    ...total,
                    [current.city]: current
                };
            }
        }, {} as Record<string, StationReport>);
        return Object.values(groupedByLocation);
    }
}
