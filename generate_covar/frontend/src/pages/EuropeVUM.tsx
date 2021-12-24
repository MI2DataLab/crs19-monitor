import React from "react";

function EuropeVUM(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Variants under monitoring (VUM)</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Zgodnie z nomenklaturą <a
                        href="https://www.ecdc.europa.eu/en/covid-19/variants-concern">ECDC</a> tą nazwą określa się
                        warianty, wykryte poprzez wywiad epidemiologiczny, oparte na regułach przesiewania wariantów
                        genomowych lub wstępne dowody naukowe. Istnieją pewne przesłanki wskazujące, że mogą one mieć
                        właściwości podobne do właściwości VOC, ale dowody są słabe lub nie zostały jeszcze ocenione
                        przez ECDC. Wymienione tu warianty muszą być obecne w co najmniej jednym ognisku, wykryte w
                        społeczności w UE/EOG lub muszą istnieć dowody na to, że wariant ten jest przenoszony przez
                        społeczność w innym miejscu na świecie.</p>
                    <p>Obecnie dla SARS-COV-2 zdefiniowano następujące Vum:
                        <br/><br/>
                            <a>B.1.214.2</a>. Kluczowe mutacje:
                            Q414K, N450K, ins214TDR, D614G.
                            <a><br/><br/>
                                A.23.1+E484K</a>. Kluczowe mutacje:
                            E484K, Q613H.
                            <a><br/><br/>
                                A.27</a>. Kluczowe mutacje:
                            L452R, N501Y, H655Y.
                            <a><br/><br/>
                                A.28</a>. Kluczowe mutacje:
                            E484K, N501T, H655Y.
                            <a><br/><br/>
                                C.16</a>. Kluczowe mutacje:
                            L452R, D614G.
                            <a><br/><br/>
                                C.37</a>. Kluczowe mutacje:
                            L452Q, F490S, D614G.
                            <a><br/><br/>
                                B.1.351+P384L</a>. Kluczowe mutacje:
                            P384L, K417N, E484K, N501Y, D614G.
                            <a><br/><br/>
                                B.1.351+E516Q</a>. Kluczowe mutacje:
                            K417N, E484K, N501Y, E516Q, D614G.
                            <a><br/><br/>
                                B.1.1.7+L452R</a>. Kluczowe mutacje:
                            L452R, N501Y, D614G.
                            <a><br/><br/>
                                C.36+L452R</a>. Kluczowe mutacje:
                            L452R, D614G.
                            <a><br/><br/>
                                AT.1</a>. Kluczowe mutacje:
                            E484K, D614G.
                            <a><br/><br/>
                                B.1.526</a>. Kluczowe mutacje:
                            E484K, D614G.
                            <a><br/><br/>
                                B.1.526.1</a>. Kluczowe mutacje:
                            L452R, D614G.
                            <a><br/><br/>
                                B.1.526.2</a>. Kluczowe mutacje:
                            S477N, D614G.
                            <a><br/><br/>
                                B.1.1.318</a>. Kluczowe mutacje:
                            E484K, D614G.
                            <a><br/><br/>
                                P.2</a>. Kluczowe mutacje:
                            E484K, D614G.
                    </p>
                </div>
                <div className="map-view__map" style={{paddingLeft: "50px", paddingTop: "0px"}}>
                    <p>Dane na bazie GISAID. Nie wszystkie te warianty są obecne w Europie w znaczącej liczbie.</p>
                    Liczba wystąpień wariantu B.1.1.318<br/>
                    <img width="700px" src="/grafika/pango/B.1.1.318.svg"/><br/>
                    Liczba wystąpień wariantu C.1.2<br/>
                    <img width="700px" src="/grafika/pango/C.1.2.svg"/><br/>
                    Liczba wystąpień wariantu B.1.640<br/>
                    <img width="700px" src="/grafika/pango/B.1.640.svg"/><br/>
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

export default EuropeVUM;
