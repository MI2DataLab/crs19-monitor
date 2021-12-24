import React, {useState} from "react";
import * as d3 from "d3";
import {StationReport} from "../domain/station-report.interface";
import {Variant} from "../domain/variant.enum";
import {COLOR_MAPPING} from "../domain/color-mapping.const";
import {getTextWidth} from "../utils/get-text-width.util";

export interface MapProps {
    data: StationReport[],
    visibleVariants: Variant[];
}

const Map = (props: MapProps) => {
    const mapRef = React.useRef(null);
    const backgroundRef = React.useRef(null);

    const maxCount = props.data.reduce(
        (total, current) => Math.max(total,
            Math.max(...Object.keys(Variant).map(k => current[k as Variant]))),
        0);

    // @ts-ignore
    const minDim = Math.min(backgroundRef?.current?.clientHeight ?? 0, backgroundRef?.current?.clientWidth ?? 0);
    const logBase = Math.pow(10, Math.floor(Math.log10(maxCount)));
    const maxFix = Math.floor(maxCount / logBase) * logBase;

    const scaleLat = d3.scaleLinear()
        .domain([49.10, 54.83])
        .range([620 * minDim / 650 , 0]);

    const scaleLong = d3.scaleLinear()
        .domain([14.07, 24.09])
        .range([0, 647 * minDim / 650]);

    const scaleSize = d3.scaleSqrt()
        .domain([0, maxCount])
        .range([0, 30]);

    const divTooltip = d3.select("body").append("div")
        .attr("class", "tooltipMap")
        .style("opacity", 0);

    React.useEffect(() => {
            const redraw = () => {
                const svg = d3.select(mapRef.current);
                svg.selectAll("*").remove();
                props.visibleVariants.forEach(
                    variant => {
                        const g = svg.append("g");
                        g
                            .selectAll("circle")
                            .data(props.data)
                            .enter()
                            .append("circle")
                            .attr("cx", d => scaleLong(d.long))
                            .attr("cy", d => scaleLat(d.lat))
                            .attr("r", d => scaleSize(d[variant]))
                            .attr("fill", COLOR_MAPPING[variant] + '35')
                            .attr("stroke", COLOR_MAPPING[variant])
                            .on("mouseover", (e, d: StationReport) => {
                                divTooltip
                                    .transition()
                                    .duration(200)
                                    .style("opacity", 0.8);
                                divTooltip
                                    .html(`
                                    <svg>
                                        <rect fill="#110c35" x="15" y="0" width="${Math.max(getTextWidth(d.city, 'Barlow', '14px') + 24, 100)}" height="142.24"/>
                                        <rect fill="#110c35" x="59" y="137" width="11.38" height="11.38" transform="rotate(45)"/>
                                        <text fill="white" font-size="14px" y="6" transform="translate(25 15)">${d.city}
                                            <tspan fill="white" x="0" y="23.8">Alpha: </tspan><tspan fill="${COLOR_MAPPING[Variant.Alpha]}" x="54.2" y="23.8">${d.Alpha}</tspan>
                                            <tspan fill="white" x="0" y="41.6">Beta: </tspan><tspan fill="#0DAFB5" x="34.55" y="41.6">${d.Beta}</tspan>
                                            <tspan fill="white" x="0" y="59.4">Gamma: </tspan><tspan fill="${COLOR_MAPPING[Variant.Gamma]}" x="52.63" y="59.4">${d.Gamma}</tspan>
                                            <tspan fill="white" x="0" y="77.2">Delta: </tspan><tspan fill="${COLOR_MAPPING[Variant.Delta]}" x="37.93" y="77.2">${d.Delta}</tspan>
                                            <tspan fill="white" x="0" y="95.0">Omicron: </tspan><tspan fill="${COLOR_MAPPING[Variant.Omicron]}" x="59.2" y="95.0">${d.Omicron}</tspan>
                                            <tspan fill="white" x="0" y="112.8">Inny: ${d.Wild}</tspan>
                                        </text>
                                    </svg>`)
                                    .style("left", `${e.pageX > window.innerWidth - getTextWidth(d.city, 'Barlow', '14px') - 100 ? e.pageX - Math.max(getTextWidth(d.city, 'Barlow', '14px') + 24, 100) - 30 : e.pageX}px`)
                                    .style("top", `${e.pageY - 28}px`);
                            })
                            .on("mouseout", d => {
                                divTooltip
                                    .transition()
                                    .duration(200)
                                    .style("opacity", 0);
                            });
                    }
                );
                if (maxFix !== 0) {
                    const rDiff = scaleSize(maxFix) - scaleSize(maxFix / 4);

                    svg
                        .append('text')
                        .attr('x', 25)
                        .attr('y', minDim - 93)
                        .style('fill', '#A9AAB9')
                        .style('font-family', 'Barlow')
                        .style('font-weight', 600)
                        .text('skala:');

                    svg
                        .append('circle')
                        .attr('cx', 100)
                        .attr('cy', minDim - 100)
                        .attr('r', scaleSize(maxFix))
                        .attr('stroke', '#A9AAB9')
                        .attr('fill', 'transparent');

                    svg
                        .append('text')
                        .style('font-family', 'Barlow')
                        .style('font-size', '12px')
                        .style('fill', '#A9AAB9')
                        .style('font-weight', 500)
                        .attr('x', 100 - getTextWidth(maxFix.toString(), 'Barlow', '12px') / 2)
                        .attr('y', minDim - 100 - rDiff / 2)
                        .text(maxFix);
                    if (maxFix >= 4) {
                        svg
                            .append('circle')
                            .attr('cx', 100)
                            .attr('cy', minDim - 100 + rDiff)
                            .attr('r', scaleSize(maxFix / 4))
                            .attr('stroke', '#A9AAB9')
                            .attr('fill', 'transparent');
                        svg
                            .append('text')
                            .style('font-family', 'Barlow')
                            .style('fill', '#A9AAB9')
                            .style('font-size', '10px')
                            .style('font-weight', 500)
                            .attr('x', 100 - getTextWidth(Math.floor(maxFix / 4).toString(), 'Barlow', '10px') / 2)
                            .attr('y', minDim - 100 + rDiff)
                            .text(Math.ceil(maxFix / 4));
                    }
                    if (maxFix >= 16) {
                        svg
                            .append('circle')
                            .attr('cx', 100)
                            .attr('cy', minDim - 100 + scaleSize(maxFix) - scaleSize(maxFix / 16))
                            .attr('r', scaleSize(maxFix / 16))
                            .attr('stroke', '#A9AAB9')
                            .attr('fill', 'transparent');
                    }
                }
            };
            redraw();
    });

    return <div ref={backgroundRef} style={{backgroundImage: `url('${process.env.PUBLIC_URL}/images/svg.svg')`, height: "100%", backgroundSize: "contain", backgroundRepeat: "no-repeat", width: "100%", display: "flex", justifyContent: "center", padding:"0px"}}>
        <svg width="100%" height="100%" ref={mapRef}/>
    </div>;
};

export default Map;
