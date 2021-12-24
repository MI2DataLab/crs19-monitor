import React from "react";

function ForeignDetections(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Monitoring poza granicami Polski</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Obserwacja zgłoszeń ze stacji europejskich pozwala na identyfikacje osób z adresem w Polsce
                        zidentyfikowanych poza Polską. Identyfikacja oparta jest o informacje z bazy GISaid w których
                        lokalizacja różni się od kraju w którym wykonano badanie.</p>
                    <p>Zdarzenie: 2021-04-13. <br/>Belgia (University Hospital Antwerp): <br/>EPI_ISL_1661222 (wariant P.1
                        - brazylijski). <br/>Mężczyna 27 lat. <br/>Adres: Europe/Poland/Lopon</p>
                    <p>Zdarzenie: 2021-04-13. <br/>Belgia (EPI_ISL_1661211): <br/>EPI_ISL_1661211 (wariant P.1 -
                        brazylijski). <br/>Mężczyna 29 lat. <br/>Adres: Europe/Poland/Tymowa</p>

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

export default ForeignDetections;