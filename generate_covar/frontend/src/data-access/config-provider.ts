import {Config} from "../domain/config.interface";

export class ConfigProvider {
    get lastUpdateDate(): Promise<Date> {
        return  fetch('/data/config.json').then(
            resp => resp.json()
        ).then(
            resp => resp as Config
        ).then(
            config => new Date(config.lastUpdate)
        );
    }
}