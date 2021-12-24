import React from "react";

function EuropeVOC(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Variants of Concern (VoC)</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Zgodnie z nomenklaturą <a
                        href="https://www.ecdc.europa.eu/en/covid-19/variants-concern">ECDC</a> tą nazwą określa się
                        warianty, co do których dostępne są wyraźne dowody wskazujące na znaczący wpływ na zdolność
                        przenoszenia się, dotkliwość choroby lub odporność, które prawdopodobnie będą miały wpływ na
                        sytuację epidemiologiczną w UE/EOG.</p>
                    <p>Obecnie dla SARS-COV-2 zdefiniowano następujące VoC:<br/><br/>
                        <a href="https://en.wikipedia.org/wiki/Lineage_B.1.1.7">Alpha</a> (B.1.1.7, brytyjski). Kluczowe
                        mutacje: N501Y, D614G. Dostępne są dowody na zwiększoną zakaźność i dotkliwość. Dominujący
                        wariant w Europie.<br/><br/>
                        <a href="https://en.wikipedia.org/wiki/Lineage_B.1.351">Beta</a> (B.1.351,
                        południowoafrykański). Kluczowe mutacje: K417T, E484K, N501Y, D614G. Dostępne są dowody na
                        zwiększoną zakaźność i dotkliwość. <br/><br/>
                        <a href="https://en.wikipedia.org/wiki/Lineage_P.1">Gamma</a> (P.1, brazylijski). Kluczowe
                        mutacje: K417N, E484K, N501Y, D614G. Dostępne są dowody na zwiększoną zakaźność i
                        dotkliwość. <br/><br/>
                        <a href="https://en.wikipedia.org/wiki/Lineage_B.1.617.2">Delta</a> (B.1.617.2, indyjski).
                        Kluczowe mutacje: L452R, T478K, D614G.<br/><br/>
                    </p>
                </div>
                <div className="map-view__map" style={{paddingLeft: "50px", paddingTop: "0px"}}>
                    <p>Dane na bazie GISAID. Nie wszystkie te warianty są obecne w Europie w znaczącej liczbie.</p>
                    Liczba wystąpień wariantu Delta<br/>
                    <img width="700px" src="/grafika/pango/B.1.617.2.svg"/><br/>
                    Liczba wystąpień wariantu Beta <br/>
                    <img width="700px" src="/grafika/pango/B.1.351.svg"/><br/>
                    Liczba wystąpień wariantu Gamma<br/>
                    <img width="700px" src="/grafika/pango/P.1.svg"/><br/>
                    Liczba wystąpień wariantu Omicron<br/>
                    <img width="700px" src="/grafika/pango/B.1.1.529.svg"/><br/>
                </div>
            </div>
        </div>
        <div className="map-view__footer">
            <h4 className="map-view__footer-title" style={{backgroundColor: "white"}}>
                <img width="800px" src="/images/logo.png"/>
            </h4>
        </div>
    </main>;
}

export default EuropeVOC;
