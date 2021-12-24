import React from "react";

function PolandProvinces(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Udział poszczególnych wariantów SARS-COV-2 w województwach</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Sumaryczna liczba sekwencji wraz z procentowym udziałem dla całej Polski.</p>
                    <div style={{textAlign: "center"}}><img width="240px" src="/grafika/wojewodztwa_all1.svg"/><img
                        width="360px" src="/grafika/wojewodztwa_all2.svg"/></div>
                    <p>Liczba sekwencji na tydzień w podziale na rodzaj wariantu w poszczególnych województwach.
                        Zaznaczona data to data pozyskania próby do analizy.</p>
                        <div style={{textAlign: "center"}}><img width="800px" src="/grafika/wojewodztwa_licz.svg"/></div>
                    <p>Procent sekwencji na tydzień w podziale na rodzaj wariantu w poszczególnych województwach.
                        Zaznaczona data to data pozyskania próby do analizy.</p>
                    <div style={{textAlign: "center"}}><img width="800px" src="/grafika/wojewodztwa_proc.svg"/></div>

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

export default PolandProvinces;