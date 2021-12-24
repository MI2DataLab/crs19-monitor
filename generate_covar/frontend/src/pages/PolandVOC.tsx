import React from "react";
import {MapDataRepository} from "../data-access/map-data.repository";
import {Variant} from "../domain/variant.enum";
import {DataSource} from "../domain/data-source.enum";
import TimeRangeSelect from "../components/TimeRangeSelect";
import FilterSelector from "../components/FilterSelector";
import {countVariants} from "../data-access/map-reporting.utils";
import ToggleSwitch from "../components/ToggleSwitch";
import Map from "../components/Map";
import {StationReport} from "../domain/station-report.interface";
import {ConfigProvider} from "../data-access/config-provider";
import {calculatePercentage} from "../utils/calculate-percentage.util";

export interface PolandVOCProps {}

export interface PolandVOCState {
    repository: MapDataRepository;
    selectedFilters: Variant[];
    dataSource: DataSource;
    lastUpdate: Date;
    timeRangeTimestamp: number;
    timeRanges: Record<number, string>;
    cache: Record<Variant, number> | null;
    records: StationReport[];
}

function buildTimeRanges(pivotDate: Date): Record<number, string> {
    const lastWeek = pivotDate.getTime() - (1000 * 60 * 60 * 24 * 7);
    const lastTwoWeeks = pivotDate.getTime() - (1000 * 60 * 60 * 24 * 14);
    const lastThreeWeeks = pivotDate.getTime() - (1000 * 60 * 60 * 24 * 21);
    const lastMonth = pivotDate.getTime() - (1000 * 60 * 60 * 24 * 30);

    return {
        [lastWeek]: "ostatnim tygodniu",
        [lastTwoWeeks]: "ostatnich 2 tygodniach",
        [lastThreeWeeks]: "ostatnich 3 tygodniach",
        [lastMonth]: "ostatnim miesiącu",
    };
}

const dataSources = ["dane GISAID", "dane PZH"];
const dataSourcesMapping = [DataSource.GISAID, DataSource.PZH];
const configProvider = new ConfigProvider();
const fullVariantList = [Variant.Omicron, Variant.Beta, Variant.Gamma, Variant.Delta, Variant.Wild, Variant.Alpha];

class PolandVOC extends React.Component<PolandVOCProps, PolandVOCState>{
    state: PolandVOCState = {
        repository: new MapDataRepository(),
        selectedFilters: fullVariantList,
        dataSource: DataSource.GISAID,
        lastUpdate: new Date(),
        timeRangeTimestamp: 0,
        timeRanges: buildTimeRanges(new Date()),
        cache: null,
        records: []
    };

    timeRangeUpdater = (range: number) => {
        console.log(range);
        this.setState(state => ({
            timeRangeTimestamp: range
        }));
        this.reloadData(range, this.state.dataSource);
    }

    filtersUpdater = (variant: Variant) => {
        this.setState(state => ({
            selectedFilters: (state.selectedFilters.indexOf(variant) !== -1) ? state.selectedFilters.filter(v => v !== variant) : [variant, ...state.selectedFilters]
        }));
    }

    filtersEraser = () => {
        this.setState({selectedFilters: fullVariantList});
    }

    dataSourceUpdater = (sourceType: DataSource) => {
        this.setState(state => ({
            dataSource: sourceType
        }));
        this.reloadData(this.state.timeRangeTimestamp, sourceType);
    }

    reloadData = async (ts: number, ds: DataSource) => {
        const data = await this.state.repository.getData(ts, ds);
        const counted = countVariants(data);
        this.setState(state => ({
            records: data,
            cache: counted
        }));
    }

    componentDidMount() {
        this.reloadData(this.state.timeRangeTimestamp, this.state.dataSource);
        configProvider.lastUpdateDate.then(
            date => {
                this.setState({
                    lastUpdate: date,
                    timeRangeTimestamp: 0,
                    timeRanges: buildTimeRanges(date)
                });
            }
        );
    }

    render() {
        const changes = {
            [Variant.Wild]: 0,
            [Variant.Omicron]: 0,
            [Variant.Alpha]: 0,
            [Variant.Beta]: 0,
            [Variant.Gamma]: 0,
            [Variant.Delta]: 0,
        };
        const percentageReport = calculatePercentage(this.state.records);
        console.log(this.state.records);

        return <div className="container"><div className="map__split-container">
            <div className="map__info-panel">
                <h2>
                    Monitoring wariantów SARS-CoV-2 w Polsce
                </h2>
                <h6 style={{marginTop: '0px'}}>
                    Ostatnia aktualizacja: {this.state.lastUpdate.toLocaleDateString()}
                </h6>
                <TimeRangeSelect selection={this.state.timeRanges} selected={this.state.timeRangeTimestamp} selectionChange={this.timeRangeUpdater}/>
                <FilterSelector selected={this.state.selectedFilters} selectionToggleHandler={this.filtersUpdater} variantNumbers={this.state.cache ?? changes} selectionClearHandler={this.filtersEraser} percentageReport={percentageReport}/>
            </div>
            <div className="map__content">
                <div className="map__content-header">
                    <ToggleSwitch options={dataSources} selected={dataSourcesMapping.indexOf(this.state.dataSource)} selectionChanged={(e) => this.dataSourceUpdater(dataSourcesMapping[e])}/>
                </div>
                <Map data={this.state.records} visibleVariants={this.state.selectedFilters}/>
            </div>
        </div>
            <div className="map-view__footer">
                <img width="600px" src="/images/logo.png"/>
            </div>
        </div>;
    }


}

export default PolandVOC;
