import {Variant} from "./variant.enum";
import {GeoPoint} from "./geo-point.interface";

export interface StationReport extends Record<Variant, number>, GeoPoint {
    city: string;
    timestamp: number;
}