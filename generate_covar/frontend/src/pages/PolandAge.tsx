import React from "react";

function PolandAge(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Wiek pacjentów poddanych analizie</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Rozkład wieku przedstawiony jest z użyciem wykresów słupkowych. Przedziały na osi poziomej
                        obejmują pięcoletnie grupy. </p>
                    <div style={{textAlign: "center"}}><img width="600px" src="/grafika/age.svg"/></div>

                    <p>Rozkład wieku w podziale na miesiące. </p>
                    <div style={{textAlign: "center"}}><img width="900px" src="/grafika/age2.svg"/></div>

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

export default PolandAge;