import React from "react";

function CoInfections(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Koinfekcje</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Zdarzenie: 2021-04-28. <br/>Kobieta, województwo mazowieckie <br/>
                        Analiza alleli dla mutacji L452R, P681R, E484Q, N501Y wykazała udział 25% odczytów o
                        charakterystyce mutacji typowych dla B.1.1.7 oraz 75% odczytów o charakterystyce typowej dla
                        B.1.617.2. <br/> Możliwa konfekcja dwoma wariantami wirusa.
                    </p>

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

export default CoInfections;