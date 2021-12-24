import {StationReport} from "../domain/station-report.interface";

export interface MapDataSource {
    fetch(timestampFrom: number): Promise<StationReport[]>;
}