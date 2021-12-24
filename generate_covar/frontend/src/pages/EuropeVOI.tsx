import React from "react";

function EuropeVOI(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Variant of Interest (VoI)</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Zgodnie z nomenklaturą <a
                        href="https://www.who.int/en/activities/tracking-SARS-CoV-2-variants/">WHO</a> tą nazwą określa
                        się warianty, w przypadku których dostępne są dowody dotyczące właściwości genomicznych, dowody
                        epidemiologiczne lub dowody in vitro, które mogłyby sugerować znaczący wpływ na zdolność
                        przenoszenia, ciężkość przebiegu choroby lub odporność, co realnie miałoby wpływ na sytuację
                        epidemiologiczną w UE/EOG. Dowody te są jednak nadal wstępne lub wiążą się z dużą niepewnością.
                    </p>
                    <p>Obecnie dla SARS-COV-2 zdefiniowano następujące VoI:<br/><br/>

                        <a href="https://en.wikipedia.org/wiki/Lineage_B.1.427">Epsilon</a> (B.1.427/B.1.429,
                        kalifornijski). Kluczowe mutacje: L452R, D614G.<br/><br/>
                        <a href="https://en.wikipedia.org/wiki/Lineage_B.1.525">Eta</a> (B.1.525, nigeryjski). Kluczowe
                        mutacje: E484K, D614G, Q677H.<br/><br/>
                        <a href="https://en.wikipedia.org/wiki/Lineage_P.3">Zeta</a> (P.2). Kluczowe mutacje: E484K,
                        N501Y, D614G.<br/><br/>
                        <a href="https://en.wikipedia.org/wiki/Lineage_B.1.617">Kappa</a> (B.1.617.1/ B.1.617.3,
                        indyjski). Kluczowe mutacje: L452R, E484Q, D614G.<br/><br/>
                    </p>
                </div>
                <div className="map-view__map" style={{paddingLeft: "50px", paddingTop: "0px"}}>
                    <p>Dane na bazie GISAID. Nie wszystkie te warianty są obecne w Europie w znaczącej liczbie.</p>
                    Liczba wystąpień wariantu Mu<br/>
                    <img width="700px" src="/grafika/pango/B.1.621.svg"/><br/>
                    Liczba wystąpień wariantu Lambda<br/>
                    <img width="700px" src="/grafika/pango/C.37.svg"/><br/>
                    Liczba wystąpień wariantu AY.4.2 (podwariant wariantu Delta)<br/>
                    <img width="700px" src="/grafika/pango/AY.4.2.svg"/><br/>
                </div>
            </div>
        </div>
        <div className="map-view__footer">
            <h4 className="map-view__footer-title">
                <img width="800px" src="/images/logo.png"/>
            </h4>
        </div>
    </main>;
}

export default EuropeVOI;
