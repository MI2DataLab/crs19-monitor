import React from "react";

function EuropeVOHC(): JSX.Element {
    return <main>
        <div>
            <div className="map-view__header">
                <div className="map-view__title-section">
                    <h2 className="map-view__title">Variants of High Consequence (VoHC)</h2>
                </div>
            </div>
            <div className="map-view__content">
                <div className="map-view__filters">
                    <br/>
                    <p>Tą nazwą określa się warianty, co do których istnieją wyraźne dowody na to, że środki
                        zapobiegawcze lub medyczne środki zaradcze mają znacznie zmniejszoną skuteczność w stosunku do
                        poprzednio występujących wariantów.</p>
                    <p>Obecnie dla SARS-COV-2 nie ma zdefiniowanych <i>Variants of High Consequence</i></p>

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

export default EuropeVOHC;