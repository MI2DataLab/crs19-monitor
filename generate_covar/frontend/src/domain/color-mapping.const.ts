import {Variant} from "./variant.enum";
import {Colors} from "./colors.enum";

export const COLOR_MAPPING: Record<Variant, Colors> = {
    [Variant.Alpha]: Colors.Yellow,
    [Variant.Delta]: Colors.Orange,
    [Variant.Beta]: Colors.DarkBlue,
    [Variant.Gamma]: Colors.Green,
    [Variant.Omicron]: Colors.Red,
    [Variant.Wild]: Colors.LightGrey
}
