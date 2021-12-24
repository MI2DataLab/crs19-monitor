import {Station} from "../domain/station.interface";

export class StationsDataSource {
    public async fetch(login: string, password: string): Promise<Station[]> {
        let headers = new Headers();
        headers.set('Authorization', 'Basic ' + btoa(login + ":" + password));
        return fetch("/data/stations/stations.json",
            {
                method:'GET',
                headers
            }).then(r => r.json()
        );
    }
}