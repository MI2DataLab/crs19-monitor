import React from "react";

function PolandTrends(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Udział poszczególnych wariantów SARS-COV-2 w województwach</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div>
                    <br/>
                    <p>Dominującym wariantem jest wariant brytyjski w każdym województwie. Pozioma linia oznacza, że nie
                        ma dużych zmian w częstości występowania danego wariantu. </p>
                    <div style={{textAlign: "center"}}>
                        <img width="640px" src="/grafika/wojewodztwa_sparkline.svg"/>
                    </div>
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

export default PolandTrends;