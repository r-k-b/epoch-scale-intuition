module Main exposing (main)

import Browser
import Date
import Dict
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Maybe.Extra as ME
import Task
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
                { title = "Epoch Scale Intuition", body = [ view model ] }
        , subscriptions = \_ -> Sub.none

        --, onUrlChange = Debug.todo ""
        --, onUrlRequest = Debug.todo ""
        }


type alias Flags =
    { localZone : String
    , posixMillis : Int
    }


type alias Model =
    { epoch : Time.Posix
    , zone : Time.Zone
    }


type alias TimeScale =
    { name : String
    , seconds : Int
    , digits : Float
    , color : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { epoch = Time.millisToPosix flags.posixMillis -- Initial timestamp
      , zone =
            TimeZone.zones
                |> Dict.get flags.localZone
                |> ME.unwrap Time.utc (\zone -> zone ())
      }
    , Cmd.batch
        [ Task.perform AdjustTimeZone Time.here

        --, Task.perform SetCurrentTime Time.now
        ]
    )



-- UPDATE


type Msg
    = UpdateTimestampSeconds Int
    | IncrementDigit Int
    | DecrementDigit Int
    | SetReference Time.Posix
    | AdjustTimeZone Time.Zone
    | SetCurrentTime Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateTimestampSeconds newTimestamp ->
            ( { model | epoch = Time.millisToPosix (1000 * newTimestamp) }, Cmd.none )

        IncrementDigit position ->
            let
                multiplier =
                    10 ^ (3 + position)

                newTimestamp =
                    Time.posixToMillis model.epoch + multiplier
            in
            ( { model | epoch = Time.millisToPosix newTimestamp }, Cmd.none )

        DecrementDigit position ->
            let
                multiplier =
                    10 ^ (3 + position)

                newTimestamp =
                    max 0 (Time.posixToMillis model.epoch - multiplier)
            in
            ( { model | epoch = Time.millisToPosix newTimestamp }, Cmd.none )

        SetReference timestamp ->
            ( { model | epoch = timestamp }, Cmd.none )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }, Cmd.none )

        SetCurrentTime _ ->
            --( { model | currentTime = Time.posixToMillis time // 1000 }, Cmd.none )
            ( model, Cmd.none )



-- VIEW


timeScales : List TimeScale
timeScales =
    [ { name = "minute", seconds = 60, digits = logBase 10 60, color = "rgba(74, 222, 128, 0.5)" }
    , { name = "hour", seconds = 3600, digits = logBase 10 3600, color = "rgba(34, 211, 238, 0.5)" }
    , { name = "day", seconds = 86400, digits = logBase 10 86400, color = "rgba(168, 85, 247, 0.5)" }
    , { name = "month", seconds = 2628000, digits = logBase 10 2628000, color = "rgba(248, 113, 113, 0.5)" }
    , { name = "year", seconds = 31536000, digits = logBase 10 31536000, color = "rgba(251, 191, 36, 0.5)" }
    ]


references : List { time : Time.Posix, label : String }
references =
    [ { time = Time.millisToPosix 0, label = "1970" }
    , { time = Time.millisToPosix 1000000000000, label = "?? 2001" }
    , { time = Time.millisToPosix 1500000000000, label = "Mid 2017" }
    , { time = Time.millisToPosix 1600000000000, label = "Sept 2020" }
    , { time = Time.millisToPosix 1700000000000, label = "Nov 2023" }
    , { time = Time.millisToPosix 1800000000000, label = "???" }
    , { time = Time.millisToPosix 1900000000000, label = "??" }
    ]


view : Model -> Html Msg
view model =
    H.h1 [] [ H.text "Epoch Scale Explorer" ]
        :: List.concat
            [ viewTimestampControls model
            , viewCurrentDate model
            , viewTimeScaleLegend
            , viewReferences
            ]
        |> H.div []


viewTimestampControls : Model -> List (Html Msg)
viewTimestampControls model =
    let
        timestampStr =
            String.padLeft 10 '0' (model.epoch |> Time.posixToMillis |> (\t -> t // 1000) |> String.fromInt)

        viewDigitControl : Int -> Char -> Html Msg
        viewDigitControl position digit =
            H.div []
                [ H.button
                    [ HE.onClick (IncrementDigit position)
                    , HA.type_ "button"
                    ]
                    [ H.text "↑" ]
                , H.span [ HA.class "font-mono H.text-xl w-6 H.text-center" ]
                    [ H.text (String.fromChar digit) ]
                , H.button
                    [ HE.onClick (DecrementDigit position)
                    , HA.type_ "button"
                    ]
                    [ H.text "↓" ]
                ]
    in
    [ H.div []
        (String.toList timestampStr
            |> List.indexedMap (\i d -> viewDigitControl (9 - i) d)
        )
    , H.div []
        (List.map
            (\scale ->
                let
                    width =
                        ceiling (scale.digits * toFloat 33)
                in
                H.div
                    [ HA.style "width" (String.fromInt width ++ "px")
                    , HA.style "background-color" scale.color
                    , HA.style "bottom" (String.fromInt ((List.length timeScales - 1) * 4) ++ "px")
                    ]
                    []
            )
            timeScales
        )
    , H.input
        [ HA.type_ "range"
        , HA.min "0"
        , HA.max "2000000000"
        , HA.value (model.epoch |> Time.posixToMillis |> (\t -> t // 1000) |> String.fromInt)
        , HE.onInput (String.toInt >> Maybe.withDefault 0 >> UpdateTimestampSeconds)
        ]
        []
    , H.input
        [ HA.type_ "number"
        , HA.value (model.epoch |> Time.posixToMillis |> (\t -> t // 1000) |> String.fromInt)
        , HE.onInput (String.toInt >> Maybe.withDefault 0 >> UpdateTimestampSeconds)
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
        [ H.text (formatDate model.epoch model.zone) ]
    , H.p []
        [ H.text
            (dateToString parts
                ++ "T"
                ++ timeToString parts
                ++ offsetToString { minutes = Time.Extra.toOffset model.zone model.epoch }
            )
        ]
    , H.p []
        [ H.text ("Timestamp: " ++ String.fromInt (Time.posixToMillis model.epoch // 1000)) ]
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


viewTimeScaleLegend : List (Html Msg)
viewTimeScaleLegend =
    List.map
        (\scale ->
            H.div []
                [ H.div
                    [ HA.style "background-color" scale.color
                    ]
                    []
                , H.text scale.name
                ]
        )
        timeScales


viewReferences : List (Html Msg)
viewReferences =
    [ H.h3 [] [ H.text "Reference Timestamps:" ]
    , H.div []
        (List.map
            (\ref ->
                H.button
                    [ HE.onClick (SetReference ref.time)
                    , HA.type_ "button"
                    ]
                    [ H.span [] [ H.text ref.label ]
                    , H.code [] [ H.text (ref.time |> Time.posixToMillis |> (\t -> t // 1000) |> String.fromInt) ]
                    ]
            )
            references
        )
    ]



-- HELPERS


formatDate : Time.Posix -> Time.Zone -> String
formatDate time zone =
    let
        year =
            String.fromInt (Time.toYear zone time)

        month =
            case Time.toMonth zone time of
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
            String.fromInt (Time.toDay zone time)

        hour =
            String.padLeft 2 '0' (String.fromInt (Time.toHour zone time))

        minute =
            String.padLeft 2 '0' (String.fromInt (Time.toMinute zone time))

        weekday =
            case Time.toWeekday zone time of
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
    weekday ++ ", " ++ month ++ " " ++ day ++ ", " ++ year ++ " " ++ hour ++ ":" ++ minute
