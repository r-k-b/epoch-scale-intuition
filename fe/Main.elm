module Main exposing (main)

import Browser
import Date
import Dict
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Maybe.Extra as ME
import Time
import Time.Extra
import TimeZone



-- MAIN


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view =
            \model ->
                { title = "Epoch Scale Intuition", body = view model }
        , subscriptions = \_ -> Sub.none
        }


totalDigits : Int
totalDigits =
    10


type alias Flags =
    { localZone : String
    , posixMillis : Int
    }


type alias Model =
    { epoch : Time.Posix
    , momentsAgo : Time.Posix
    , zone : Time.Zone
    , zoneName : String
    }


type alias TimeScale =
    { name : String
    , seconds : Int
    , log10 : Float
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { epoch = Time.millisToPosix flags.posixMillis -- Initial timestamp
      , zone =
            TimeZone.zones
                |> Dict.get flags.localZone
                |> ME.unwrap Time.utc (\zone -> zone ())
      , zoneName = flags.localZone
      , momentsAgo = Time.millisToPosix flags.posixMillis
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = UserEnteredNewTimestampSeconds Int
    | UserClickedIncrementDigit Int
    | UserClickedDecrementDigit Int
    | UserClickedReference Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserEnteredNewTimestampSeconds newTimestamp ->
            ( { model | epoch = Time.millisToPosix (1000 * newTimestamp) }, Cmd.none )

        UserClickedIncrementDigit position ->
            let
                multiplier =
                    10 ^ (3 + position)

                newTimestamp =
                    Time.posixToMillis model.epoch + multiplier
            in
            ( { model | epoch = Time.millisToPosix newTimestamp }, Cmd.none )

        UserClickedDecrementDigit position ->
            let
                multiplier =
                    10 ^ (3 + position)

                newTimestamp =
                    Time.posixToMillis model.epoch - multiplier
            in
            ( { model | epoch = Time.millisToPosix newTimestamp }, Cmd.none )

        UserClickedReference timestamp ->
            ( { model | epoch = timestamp }, Cmd.none )



-- VIEW


timeScales : List TimeScale
timeScales =
    let
        asSeconds : Int -> String -> TimeScale
        asSeconds s name =
            { name = name, seconds = s, log10 = logBase 10 (toFloat s) * 10 }
    in
    [ "1 s" |> asSeconds 1
    , "10 seconds" |> asSeconds 10
    , "1 minute" |> asSeconds 60
    , "1 fika" |> asSeconds (60 * 15)
    , "1,000 seconds" |> asSeconds 1000
    , "1 hour" |> asSeconds 3600
    , "2¾ hours" |> asSeconds (3600 * 2.75 |> round)
    , "1 day" |> asSeconds 86400
    , "1 million seconds" |> asSeconds 1000000
    , "1 month" |> asSeconds 2628000
    , "4 months" |> asSeconds (4 * 2628000)
    , "1 year" |> asSeconds 31536000
    , "2⅞ years" |> asSeconds (31536000 * 2.8539 |> round)
    , "1 decade" |> asSeconds 315360000
    , "31¾ years" |> asSeconds (31536000 * 31.71 |> round)
    , "1 billion seconds" |> asSeconds 1000000000
    ]


references : List { time : Time.Posix, label : String }
references =
    [ { time = Time.millisToPosix 0, label = "1970" }
    , { time = Time.millisToPosix 1000000000000, label = "Sept 2001" }
    , { time = Time.millisToPosix 1500000000000, label = "Mid 2017" }
    , { time = Time.millisToPosix 1600000000000, label = "Sept 2020" }
    , { time = Time.millisToPosix 1700000000000, label = "Nov 2023" }
    , { time = Time.millisToPosix 1800000000000, label = "Jan 2027" }
    , { time = Time.millisToPosix 1900000000000, label = "March 2030" }
    , { time = Time.millisToPosix (1000 * (2 ^ 31 - 1)), label = "2038 💥" }
    ]


view : Model -> List (Html Msg)
view model =
    H.h1 [] [ H.text "Epoch Scale Explorer" ]
        :: List.concat
            [ viewTimestampControls model
            , viewCurrentDate model
            , viewReferences model
            ]


viewTimestampControls : Model -> List (Html Msg)
viewTimestampControls model =
    let
        timestampStr =
            String.padLeft totalDigits
                '0'
                (model.epoch |> Time.posixToMillis |> abs |> String.fromInt |> String.slice 0 -3)

        unhandledDigits : String
        unhandledDigits =
            timestampStr |> String.slice 0 (-1 * totalDigits)

        truncatedTimestampStr : String
        truncatedTimestampStr =
            timestampStr |> String.right 10

        negIndicator : String
        negIndicator =
            if (model.epoch |> Time.posixToMillis) < 0 then
                "−"

            else
                ""

        viewDigitControl : Int -> Char -> List (Html Msg)
        viewDigitControl position digit =
            let
                digitStr =
                    if (position + 1) == totalDigits then
                        negIndicator ++ unhandledDigits ++ String.fromChar digit

                    else
                        String.fromChar digit
            in
            [ H.button
                [ HE.onClick (UserClickedIncrementDigit position)
                , HA.type_ "button"
                , HA.class "controls__digitUp"
                ]
                [ H.text "⮝" ]
            , H.span
                [ HA.class "controls__digit"
                ]
                [ H.text <|
                    if position > 0 && (position |> modBy 3) == 0 then
                        digitStr ++ ","

                    else
                        digitStr
                ]
            , H.button
                [ HE.onClick (UserClickedDecrementDigit position)
                , HA.type_ "button"
                , HA.class "controls__digitDown"
                ]
                [ H.text "⮟" ]
            ]
    in
    [ H.div [ HA.class "controls__grid" ] <|
        (String.toList truncatedTimestampStr
            |> List.indexedMap (\i d -> viewDigitControl (totalDigits - 1 - i) d)
            |> List.concat
        )
            ++ [ H.div [ HA.class "controls__scales" ]
                    (List.indexedMap
                        (\index scale ->
                            let
                                width =
                                    scale.log10 + 5
                            in
                            H.div
                                [ HA.style "width" (String.fromFloat width ++ "%")
                                , HA.class "controls__scaleBar"
                                , HA.attribute "position-anchor" ("--controls__scaleBar--index" ++ String.fromInt index)
                                ]
                                [ H.div
                                    [ HA.attribute "anchor-name" ("--controls__scaleBar--index" ++ String.fromInt index)
                                    , HA.class "controls__scaleBarNeedle"
                                    ]
                                    [ H.text "↑" ]
                                , H.div [ HA.class "controls__scaleBarText" ] [ H.text scale.name ]
                                ]
                        )
                        timeScales
                    )
               ]
    , H.input
        [ HA.type_ "number"
        , HA.value (model.epoch |> toSeconds)
        , HE.onInput (String.toInt >> Maybe.withDefault 0 >> UserEnteredNewTimestampSeconds)
        ]
        []
    ]


viewCurrentDate : Model -> List (Html Msg)
viewCurrentDate model =
    let
        parts : Time.Extra.Parts
        parts =
            Time.Extra.posixToParts model.zone model.epoch
    in
    [ H.h3 [] [ H.text "Current Selection:" ]
    , H.p []
        [ H.text (formatDate model) ]
    , H.p []
        [ H.text
            (dateToString parts
                ++ "T"
                ++ timeToString parts
                ++ offsetToString { minutes = Time.Extra.toOffset model.zone model.epoch }
            )
        ]
    , H.p []
        [ H.text ("Timestamp: " ++ toSeconds model.epoch) ]
    ]


offsetToString : { minutes : Int } -> String
offsetToString { minutes } =
    if minutes == 0 then
        "Z"

    else
        let
            remainderMinutes : Int
            remainderMinutes =
                minutes |> abs |> modBy 60

            hour =
                (abs minutes - remainderMinutes) // 60
        in
        (if minutes >= 0 then
            "+" ++ padInt2 hour

         else
            "-" ++ padInt2 hour
        )
            ++ ":"
            ++ padInt2 remainderMinutes


dateToString : { a | year : Int, month : Time.Month, day : Int } -> String
dateToString date =
    String.join "-"
        [ String.padLeft 4 '0' (String.fromInt date.year)
        , date.month
            |> Date.monthToNumber
            |> padInt2
        , padInt2 date.day
        ]


timeToString : { a | hour : Int, minute : Int, second : Int, millisecond : Int } -> String
timeToString time =
    String.join ":"
        [ padInt2 time.hour
        , padInt2 time.minute
        , if time.millisecond == 0 then
            padInt2 time.second

          else
            padInt2 time.second ++ "." ++ String.padLeft 3 '0' (String.fromInt time.millisecond)
        ]


padInt2 : Int -> String
padInt2 i =
    String.padLeft 2 '0' (String.fromInt i)


viewReferences : Model -> List (Html Msg)
viewReferences { momentsAgo } =
    [ H.h3 [] [ H.text "Reference Timestamps:" ]
    , H.div []
        (List.map
            (\ref ->
                H.button
                    [ HE.onClick (UserClickedReference ref.time)
                    , HA.type_ "button"
                    ]
                    [ H.span [] [ H.text ref.label ]
                    , H.br [] []
                    , H.code [] [ H.text (ref.time |> toSeconds) ]
                    ]
            )
            ({ time = momentsAgo, label = "Moments ago" } :: references)
        )
    ]



-- HELPERS


{-| Using with String.slice here, because using `millis // 1000` introduces overflow issues around 2³².
-}
toSeconds : Time.Posix -> String
toSeconds posix =
    let
        s =
            posix |> Time.posixToMillis |> String.fromInt |> String.slice 0 -3
    in
    if s == "" then
        "0"

    else
        s


formatDate : Model -> String
formatDate { epoch, zone, zoneName } =
    let
        year =
            String.fromInt (Time.toYear zone epoch)

        month =
            case Time.toMonth zone epoch of
                Time.Jan ->
                    "January"

                Time.Feb ->
                    "February"

                Time.Mar ->
                    "March"

                Time.Apr ->
                    "April"

                Time.May ->
                    "May"

                Time.Jun ->
                    "June"

                Time.Jul ->
                    "July"

                Time.Aug ->
                    "August"

                Time.Sep ->
                    "September"

                Time.Oct ->
                    "October"

                Time.Nov ->
                    "November"

                Time.Dec ->
                    "December"

        day =
            String.fromInt (Time.toDay zone epoch)

        hour =
            String.padLeft 2 '0' (String.fromInt (Time.toHour zone epoch))

        minute =
            String.padLeft 2 '0' (String.fromInt (Time.toMinute zone epoch))

        weekday =
            case Time.toWeekday zone epoch of
                Time.Mon ->
                    "Monday"

                Time.Tue ->
                    "Tuesday"

                Time.Wed ->
                    "Wednesday"

                Time.Thu ->
                    "Thursday"

                Time.Fri ->
                    "Friday"

                Time.Sat ->
                    "Saturday"

                Time.Sun ->
                    "Sunday"
    in
    weekday ++ ", " ++ month ++ " " ++ day ++ ", " ++ year ++ " " ++ hour ++ ":" ++ minute ++ " (" ++ zoneName ++ ")"
