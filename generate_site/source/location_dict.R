load_location_dict <- function() { 
    ### reversed dict
    ## NOTE: gsub(" ", "", x) is not possible due to other countries than PL
    # TODO: consider only lowercase keys
    list(
    # https://pl.wikipedia.org/wiki/Województwo
    ######## PL

    "Dolnośląskie" =
        c(
        "Dolnoslaskie" , "dolnoslaskie"
        , " Dolnoslaskie" , " dolnoslaskie"
        , " Dolnoslaskie " , " dolnoslaskie "
        , "Dolnośląskie", "dolnośląskie"
        , " Dolnośląskie", " dolnośląskie"
        , " Dolnośląskie ", " dolnośląskie "
        , "Dolnoslakie", "dolnoslakie"
        , " Dolnoslakie", " dolnoslakie"
        , " Dolnoslakie ", " dolnoslakie "
        , "DolnoSlaskie" , "dolnoSlaskie"
        , " DolnoSlaskie" , " dolnoSlaskie"
        , " DolnoSlaskie " , " dolnoSlaskie "
        )
    , "Kujawsko-Pomorskie" =
        c(
        "Kujawsko-Pomorskie" , "kujawsko-pomorskie", "Kujawsko-pomorskie"
        , " Kujawsko-Pomorskie" , " kujawsko-pomorskie", " Kujawsko-pomorskie"
        , " Kujawsko-Pomorskie " , " kujawsko-pomorskie ", " Kujawsko-pomorskie "
        )
    , "Lubelskie" =
        c(
        "Lubelskie" , "lubelskie"
        , " Lubelskie", " lubelskie"
        , " Lubelskie ", " lubelskie "
        )
    , "Lubuskie" =
        c(
        "Lubuskie" , "lubuskie"
        , " Lubuskie" , " lubuskie"
        , " Lubuskie " , " lubuskie "
        )
    , "Łódzkie" =
        c(
        "Lodzkie", "lodzkie"
        , " Lodzkie", " lodzkie"
        , " Lodzkie ", " lodzkie "
        , "Łódzkie", "łódzkie"
        , " Łódzkie", " łódzkie"
        , " Łódzkie ", " łódzkie "
        , "Iodzkie", "lodzkie"
        , " Iodzkie", " lodzkie"
        , " Iodzkie ", " lodzkie "
        )
    , "Małopolskie" =
        c(
        "Malopolskie" , "malopolskie"
        , " Malopolskie" , " malopolskie"
        , " Malopolskie " , " malopolskie "
        , "Małopolskie", "małopolskie"
        , " Małopolskie", " małopolskie"
        , " Małopolskie ", " małopolskie "
        , "Malopolska", "malopolska"
        , " Malopolska", " malopolska"
        , " Malopolska ", " malopolska "
        , "Małopolska", "małopolska"
        , " Małopolska", " małopolska"
        , " Małopolska ", " małopolska "
        , "MalOpolskie", "malOpolskie"
        , " MalOpolskie", " malOpolskie"
        , " MalOpolskie ", " malOpolskie "
        )
    , "Mazowieckie" =
        c(
        "Mazowieckie", "mazowieckie"
        , " Mazowieckie", " mazowieckie"
        , " Mazowieckie ", " mazowieckie "
        , "Masovia", "masovia"
        , " Masovia", " masovia"
        , " Masovia ", " masovia "
        )
    , "Opolskie" =
        c(
        "Opolskie", "opolskie"
        , " Opolskie", " opolskie"
        , " Opolskie ", " opolskie "
        )
    , "Podkarpackie" =
        c(
        "Podkarpackie", "podkarpackie"
        , " Podkarpackie", " podkarpackie"
        , " Podkarpackie ", " podkarpackie "
        )
    , "Podlaskie" =
        c(
        "Podlaskie", "podlaskie"
        , " Podlaskie", " podlaskie"
        , " Podlaskie ", " podlaskie "
        , "Bielsk Podlaski", "bielsk podlaski"
        , " Bielsk Podlaski", " bielsk podlaski"
        , " Bielsk Podlaski ", " bielsk podlaski "
        )
    , "Pomorskie" =
        c(
        "Pomorskie", "pomorskie"
        , " Pomorskie", " pomorskie"
        , " Pomorskie ", " pomorskie "
        , "Pomerania", "pomerania"
        , " Pomerania", " pomerania"
        , " Pomerania ", " pomerania "
        , "Pomorze", "pomorze"
        , " Pomorze", " pomorze"
        , " Pomorze ", " pomorze "
        )
    , "Śląskie" =
        c(
        "Slaskie", "slaskie"
        , " Slaskie", " slaskie"
        , " Slaskie ", " slaskie "
        , "Śląskie", "śląskie"
        , " Śląskie", " śląskie"
        , " Śląskie ", " śląskie "
        , "Slask", "slask"
        , " Slask", " slask"
        , " Slask ", " slask "
        )
    , "Świętokrzyskie" =
        c(
        "Swietokrzyskie", "swietokrzyskie"
        , " Swietokrzyskie", " swietokrzyskie"
        , " Swietokrzyskie ", " swietokrzyskie "
        , "Świętokrzyskie", "świętokrzyskie"
        , " Świętokrzyskie", " świętokrzyskie"
        , " Świętokrzyskie ", " świętokrzyskie "
        )
    , "Warmińsko-Mazurskie" =
        c(
        "Warminsko-Mazurskie", "warminsko-mazurskie", "Warminsko-mazurskie"
        , " Warminsko-Mazurskie", " warminsko-mazurskie", " Warminsko-mazurskie"
        , " Warminsko-Mazurskie ", " warminsko-mazurskie ", " Warminsko-mazurskie "
        , "Warmińsko-Mazurskie", "warmińsko-mazurskie", "Warmińsko-mazurskie"
        , " Warmińsko-Mazurskie", " warmińsko-mazurskie", " Warmińsko-mazurskie"
        , " Warmińsko-Mazurskie ", " warmińsko-mazurskie ", " Warmińsko-mazurskie "
        )
    , "Wielkopolskie" =
        c(
        "Wielkopolskie", "wielkopolskie"
        , " Wielkopolskie", " wielkopolskie"
        , " Wielkopolskie ", " wielkopolskie "
        , "Wielkopolska", "wielkopolska"
        , " Wielkopolska", " wielkopolska"
        , " Wielkopolska ", " wielkopolska "
        , "WielkOpolskie", "wielkOpolskie"
        , " WielkOpolskie", " wielkOpolskie"
        , " WielkOpolskie ", " wielkOpolskie "
        )
    , "Zachodniopomorskie" =
        c(
        "Zachodniopomorskie", "zachodniopomorskie"
        , " Zachodniopomorskie", " zachodniopomorskie"
        , " Zachodniopomorskie ", " zachodniopomorskie "
        , "ZachodnioPomorskie", "zachodnioPomorskie"
        , " ZachodnioPomorskie", " zachodnioPomorskie"
        , " ZachodnioPomorskie ", " zachodnioPomorskie "
        )

    ########
    , "Central Bohemian Region" =
        c(
        "Central Bohemian Region", "central bohemian region"
        , " Central Bohemian Region", " central bohemian region"
        , " Central Bohemian Region ", " central bohemian region "
        , "Central Bohemia Region", "central bohemia region"
        , " Central Bohemia Region", " central bohemia region"
        , " Central Bohemia Region ", " central bohemia region "
        , "Melnik", "melnik"
        , " Melnik", " melnik"
        , " Melnik ", " melnik "
        , "Slaný", "slaný"
        , " Slaný", " slaný"
        , " Slaný ", " slaný "
        , "Prague", "prague"
        , " Prague", " prague"
        , " Prague ", " prague "
        , "Prague-Miskovice", "prague-miskovice"
        , " Prague-Miskovice", " prague-miskovice"
        , " Prague-Miskovice ", " prague-miskovice "
        , "Central Czechia and Prague", "central czechia and prague"
        , " Central Czechia and Prague", " central czechia and prague"
        , " Central Czechia and Prague ", " central czechia and prague " 
        , "Praha", "praha"
        , " Praha", " praha"
        , " Praha ", " praha "
        , "Stredocesky Region", "stredocesky region", "Stredocesky region"
        , " Stredocesky Region", " stredocesky region", " Stredocesky region"
        , " Stredocesky Region ", " stredocesky region ", " Stredocesky region "
        )
    , "Hradec Králové Region" =
        c(
        "Hradec Králové Region", "hradec králové region"
        , " Hradec Králové Region", " hradec králové region"
        , " Hradec Králové Region ", " hradec králové region "
        , "Hradec Kralove Region", "hradec kralove region"
        , " Hradec Kralove Region", " hradec kralove region"
        , " Hradec Kralove Region ", " hradec kralove region "
        , "Kralovehradecky Region", "kralovehradecky region", "Kralovehradecky region"
        , " Kralovehradecky Region", " kralovehradecky region", " Kralovehradecky region"
        , " Kralovehradecky Region ", " kralovehradecky region ", " Kralovehradecky region "
        , "Nachod", "nachod"
        , " Nachod", " nachod"
        , " Nachod ", " nachod "
        , "Trutnov", "trutnov"
        , " Trutnov", " trutnov"
        , " Trutnov ", " trutnov "
        )
    , "Karlovy Vary Region" = 
        c(
        "Karlovy Vary Region", "karlovy vary region"
        , "Carlsbad", "carlsbad"
        , " Carlsbad", " carlsbad"
        , " Carlsbad ", " carlsbad "
        , "Cheb", "cheb"
        , " Cheb", " cheb"
        , " Cheb ", " cheb "
        )
    , "Liberec Region" =
        c(
        "Liberec Region", "liberec region", "Liberec region"
        , " Liberec Region", " liberec region", " Liberec region"
        , " Liberec Region ", " liberec region ", " Liberec region "
        , "Liberecky Region", "liberecky region", "Liberecky region"
        , " Liberecky Region", " liberecky region", " Liberecky region"
        , " Liberecky Region ", " liberecky region ", " Liberecky region "
        )
    , "Moravian-Silesian Region" =
        c(
        "Moravian-Silesian Region", "moravian-silesian region"
        , " Moravian-Silesian Region", " moravian-silesian region"
        , " Moravian-Silesian Region ", " moravian-silesian region "
        )
    , "Northern Bohemian Region" =
        c(
        "Northern Bohemian Region", "northern bohemian region"
        , " Northern Bohemian Region", " northern bohemian region"
        , " Northern Bohemian Region ", " northern bohemian region "
        , "Northern Bohemia Region", "northern bohemia region"
        , " Northern Bohemia Region", " northern bohemia region"
        , " Northern Bohemia Region ", " northern bohemia region "
        , "North Bohemian Region", "north bohemian region"
        , " North Bohemian Region", " north bohemian region"
        , " North Bohemian Region ", " north bohemian region "
        , "North Bohemia Region", "north bohemia region"
        , " North Bohemia Region", " north bohemia region"
        , " North Bohemia Region ", " north bohemia region "
        )
    , "Olomouc Region" =
        c(
        "Olomouc", "olomouc"
        , " Olomouc", " olomouc"
        , " Olomouc ", " olomouc "
        , "Olomouc Region", "olomouc region"
        , " Olomouc Region", " olomouc region"
        , " Olomouc Region ", " olomouc region "
        , "Litovel", "litovel"
        , " Litovel", " litovel"
        , " Litovel ", " litovel "
        , "Hranice na Moravě", "hranice na moravě"
        , " Hranice na Moravě", " hranice na moravě"
        , " Hranice na Moravě ", " hranice na moravě "
        , "Hranice", "hranice"
        , " Hranice", " hranice"
        , " Hranice ", " hranice "
        )
    , "Pardubice Region" =
        c(
        "Pardubice Region", "pardubice region"
        , " Pardubice Region", " pardubice region"
        , " Pardubice Region ", " pardubice region "
        )
    , "Plzeň Region" =
        c(
        "Plzen", "plzen"
        , " Plzen", " plzen"
        , " Plzen ", " plzen "
        , "Plzeň", "plzeň"
        , " Plzeň", " plzeň"
        , " Plzeň ", " plzeň "
        , "Plzen Region", "plzen region"
        , " Plzen Region", " plzen region"
        , " Plzen Region ", " plzen region "
        , "Plzeň Region", "plzeň region"
        , " Plzeň Region", " plzeň region"
        , " Plzeň Region ", " plzeň region "
        , "Klatovy", "klatovy"
        , " Klatovy", " klatovy"
        , " Klatovy ", " klatovy "
        , "Domažlice", "domažlice"
        , " Domažlice", " domažlice"
        , " Domažlice ", " domažlice "
        , "Pilsen", "pilsen"
        , " Pilsen", " pilsen"
        , " Pilsen ", " pilsen "
        )
    , "South Bohemian Region" =
        c(
        "South Bohemian Region", "south bohemian region"
        , " South Bohemian Region", " south bohemian region"
        , " South Bohemian Region ", " south bohemian region "
        , "South Bohemia Region", "south bohemia region"
        , " South Bohemia Region", " south bohemia region"
        , " South Bohemia Region ", " south bohemia region "
        , "Southern Bohemian Region", "southern bohemian region"
        , " Southern Bohemian Region", " southern bohemian region"
        , " Southern Bohemian Region ", " southern bohemian region "
        , "Southern Bohemia Region", "southern bohemia region"
        , " Southern Bohemia Region", " southern bohemia region"
        , " Southern Bohemia Region ", " southern bohemia region "
        )
    , "South Moravian Region" =
        c(
        "South Moravian Region", "south moravian region"
        , " South Moravian Region", " south moravian region"
        , " South Moravian Region ", " south moravian region "
        , "Brno", "brno"
        , " Brno", " brno"
        , " Brno ", " brno "
        , "Breclav", "breclav"
        , " Breclav", " breclav"
        , " Breclav ", " breclav "
        )
    , "Ústí nad Labem Region" =
        c(
        "Ústí nad Labem", "ústí nad labem"
        , " Ústí nad Labem", " ústí nad labem"
        , " Ústí nad Labem ", " ústí nad labem "
        , "Ústí nad Labem Region", "ústí nad labem region"
        , " Ústí nad Labem Region", " ústí nad labem region"
        , " Ústí nad Labem Region ", " ústí nad labem region "
        , "Usti nad Labem", "usti nad labem"
        , " Usti nad Labem", " usti nad labem"
        , " Usti nad Labem ", " usti nad labem "
        )
    , "Vysocina Region" =
        c(
        "Vysocina Region", "vysocina region"
        , " Vysocina Region", " vysocina region"
        , " Vysocina Region ", " vysocina region "
        , "Vysocina", "vysocina"
        , " Vysocina", " vysocina"
        , " Vysocina ", " vysocina "
        , "Jihlava", "jihlava"
        , " Jihlava", " jihlava"
        , " Jihlava ", " jihlava "
        )
    , "Zlín Region" =
        c(
        "Zlin", "zlin"
        , " Zlin", " zlin"
        , " Zlin ", " zlin "
        , "Zlin Region", "zlin region"
        , " Zlin Region", " zlin region"
        , " Zlin Region ", " zlin region "
        , "Zlín", "zlín"
        , " Zlín", " zlín"
        , " Zlín ", " zlín "
        , "Zlín Region", "zlín region"
        , " Zlín Region", " zlín region"
        , " Zlín Region ", " zlín region "
        )
    )
}